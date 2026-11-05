import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:eros_n/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' hide Cookie;
import 'package:webview_windows/webview_windows.dart';
import '../../common/const/const.dart';
import '../../pages/webview/webview.dart';

class WebViewCookieInfo {
  const WebViewCookieInfo({
    required this.url,
    required this.cookies,
    required this.userAgent,
    this.manualRequired = false,
    this.message,
    this.challengePage = false,
    this.pageReady = false,
  });

  @override
  String toString() {
    return 'WebViewCookieInfo<MR:$manualRequired, challenge:$challengePage, '
        'ready:$pageReady, $message, $userAgent, '
        '${cookies.map((e) => e.name).join(',')}>';
  }

  final String url;
  final List<Cookie> cookies;
  final String userAgent;

  /// The challenge needs the user (Turnstile checkbox, captcha...), or it
  /// has been running for too long.
  final bool manualRequired;
  final String? message;

  /// The page currently shown is a Cloudflare challenge page.
  final bool challengePage;

  /// The document finished loading.
  final bool pageReady;

  bool hasCookie(String name) => cookies.any((e) => e.name == name);
}

/// JavaScript that describes the Cloudflare state of the current page.
const String _kChallengeProbeJs = '''
(function () {
  var title = (document.title || '').toLowerCase();
  var challenge = title.indexOf('just a moment') >= 0 ||
      title.indexOf('attention required') >= 0 ||
      title.indexOf('请稍候') >= 0 ||
      !!document.querySelector('#challenge-form, #challenge-running, #challenge-stage, #cf-challenge-running, .cf-browser-verification, #turnstile-wrapper, .cf-turnstile');
  var interactive = !!document.querySelector(
      'iframe[src*="challenges.cloudflare.com"], .cf-turnstile, input[type="checkbox"], .pow-button, .captcha-prompt, #challenge-stage input');
  var msgEl = document.querySelector('#challenge-body-text, #challenge-stage, .core-msg');
  return JSON.stringify({
    challenge: challenge,
    interactive: challenge && interactive,
    ready: document.readyState === 'complete',
    host: location.hostname || '',
    message: msgEl ? (msgEl.textContent || '').trim().substring(0, 120) : '',
    cookie: document.cookie || ''
  });
})()
''';

typedef WebViewCallback = Function(WebViewCookieInfo);

class MobileWebView extends StatefulWidget {
  const MobileWebView(
      {super.key,
      required this.url,
      this.callback,
      this.deletedCookie = false});

  final WebViewCallback? callback;
  final String url;
  final bool deletedCookie;

  @override
  State<MobileWebView> createState() => _MobileWebViewState();
}

class _MobileWebViewState extends State<MobileWebView> {
  late CookieManager cookieManager;
  bool initOk = false;

  Timer? anomalyTimer;

  /// Seconds a challenge may run on its own before we show it to the user.
  static const int _kAutoChallengeSeconds = 12;

  @override
  void initState() {
    initWebView();
    super.initState();
    if (widget.callback != null) {
      anomalyTimer = Timer.periodic(const Duration(seconds: 1), anomalyMonitor);
    }
  }

  @override
  void dispose() {
    anomalyTimer?.cancel();
    super.dispose();
  }

  Future<void> anomalyMonitor(Timer timer) async {
    if (mounted && initOk && _controller != null) {
      await callbackChallengeInfo();
    }
  }

  Future<void> initWebView() async {
    cookieManager = CookieManager.instance();
    if (widget.deletedCookie) {
      await cookieManager.deleteAllCookies();
    }
    if (!mounted) {
      return;
    }
    setState(() {
      initOk = true;
    });
  }

  bool _reporting = false;

  Future<List<Cookie>> _collectCookies(String documentCookie) async {
    final uri = WebUri(NHConst.baseUrl);
    var cookies = await cookieManager.getCookies(url: uri);
    if (Platform.isIOS || Platform.isMacOS) {
      // A URL lookup misses cookies scoped to other paths (e.g. the API
      // token); also scan the whole store for the site's cookies.
      try {
        final all = await cookieManager.getAllCookies();
        final names = cookies.map((c) => c.name).toSet();
        cookies = [
          ...cookies,
          ...all.where((c) =>
              (c.domain ?? '').contains(NHConst.baseHost) &&
              !names.contains(c.name)),
        ];
      } catch (e) {
        logger.t('getAllCookies failed: $e');
      }
    }
    final result = <String, Cookie>{
      for (final c in cookies) c.name: Cookie(c.name, '${c.value}'),
    };
    // document.cookie also exposes cookies set by scripts that the cookie
    // store has not flushed yet (HttpOnly ones are not visible there).
    for (final part in documentCookie.split(';')) {
      final index = part.indexOf('=');
      if (index <= 0) {
        continue;
      }
      final name = part.substring(0, index).trim();
      final value = part.substring(index + 1).trim();
      if (name.isNotEmpty && !result.containsKey(name)) {
        try {
          result[name] = Cookie(name, value);
        } on FormatException {
          // Ignore values dart:io refuses (e.g. quotes, spaces).
        }
      }
    }
    return result.values.toList();
  }

  Future<void> callbackChallengeInfo() async {
    final controller = _controller;
    if (controller == null || _reporting || widget.callback == null) {
      return;
    }
    _reporting = true;
    try {
      Map<String, dynamic> probe = const {};
      try {
        final raw =
            await controller.evaluateJavascript(source: _kChallengeProbeJs);
        if (raw is String && raw.isNotEmpty) {
          probe = jsonDecode(raw) as Map<String, dynamic>;
        }
      } catch (e) {
        logger.t('challenge probe failed: $e');
      }
      final challengePage = probe['challenge'] == true;
      final interactive = probe['interactive'] == true;
      final host = (probe['host'] as String?) ?? '';
      // Only a loaded page of the site itself counts (not about:blank).
      final ready = probe['ready'] == true && host.endsWith(NHConst.baseHost);

      final cookies = await _collectCookies((probe['cookie'] as String?) ?? '');
      final ua =
          await controller.evaluateJavascript(source: 'navigator.userAgent');
      final userAgent = ua is String ? ua : '';
      final waited = anomalyTimer?.tick ?? 0;

      if (!mounted) {
        return;
      }
      widget.callback?.call(WebViewCookieInfo(
        url: NHConst.baseUrl,
        cookies: cookies,
        userAgent: userAgent,
        challengePage: challengePage,
        pageReady: ready,
        manualRequired:
            challengePage && (interactive || waited >= _kAutoChallengeSeconds),
        message: probe['message'] as String?,
      ));
    } catch (e) {
      logger.e('callbackChallengeInfo: $e');
    } finally {
      _reporting = false;
    }
  }

  InAppWebViewController? _controller;

  Future reload() async {
    await _controller?.reload();
  }

  @override
  Widget build(BuildContext context) {
    if (initOk) {
      return InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri(widget.url),
        ),
        initialSettings: inAppWebViewSettings,
        onWebViewCreated: (controller) {
          _controller = controller;
        },
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          return NavigationActionPolicy.ALLOW;
        },
        onTitleChanged: (controller, title) async {
          _controller = controller;
          logger.d('onTitleChanged: $title');
          callbackChallengeInfo();
        },
        onLoadStop: (controller, url) async {
          _controller = controller;
          logger.d('onLoadStop: $url');
          callbackChallengeInfo();
        },
      );
    }
    return Container();
  }
}

class WindowsWebView extends StatefulWidget {
  const WindowsWebView({super.key, required this.url, this.callback});

  final WebViewCallback? callback;
  final String url;

  @override
  State<WindowsWebView> createState() => _WindowsWebViewState();
}

class _WindowsWebViewState extends State<WindowsWebView> {
  final _controller = WebviewController();
  final List<StreamSubscription> _subscriptions = [];

  Timer? anomalyTimer;

  Future reload() {
    return _controller.reload();
  }

  @override
  void initState() {
    super.initState();
    initPlatformState();
    if (widget.callback != null) {
      anomalyTimer = Timer.periodic(const Duration(seconds: 1), anomalyMonitor);
    }
  }

  Future<void> anomalyMonitor(Timer timer) async {
    if (!mounted || !_controller.value.isInitialized) {
      return;
    }
    callbackChallengeInfo();
  }

  Future<bool> getManualRequired() async {
    if (_controller.value.isInitialized) {
      final manualRequiredText = await _controller.executeScript(
          '(document.querySelector(".pow-button") != null  || document.querySelector(".captcha-prompt")) ? "true" : null');
      return manualRequiredText == 'true';
    }
    return false;
  }

  Future<String?> getChallengeMessage() async {
    if (_controller.value.isInitialized) {
      final String msg = await _controller.executeScript(
              '(document.querySelector("#challenge-body-text") != null) ? document.querySelector("#challenge-body-text").textContent : ""')
          as String;
      ;
      return msg.trim();
    }
    return null;
  }

  Future<String> getUserAgent() async {
    if (_controller.value.isInitialized) {
      final value = await _controller.executeScript('navigator.userAgent');
      return value is String ? value : '';
    }
    return '';
  }

  Future<List<Cookie>> getCookies() async {
    if (_controller.value.isInitialized) {
      return await _controller.getCookies([Uri.parse(widget.url)]) ?? [];
    }
    return [];
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    anomalyTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  String url = '';

  Future callbackChallengeInfo() async {
    if (_controller.value.isInitialized) {
      widget.callback?.call(WebViewCookieInfo(
          url: NHConst.baseUrl,
          cookies: await getCookies(),
          userAgent: await getUserAgent(),
          manualRequired:
              (anomalyTimer?.tick ?? 0) >= 10 || await getManualRequired(),
          message: await getChallengeMessage()));
    }
  }

  Future<void> initPlatformState() async {
    url = widget.url;
    await _controller.initialize();
    _subscriptions.add(_controller.url.listen((url) {
      this.url = url;
    }));
    _subscriptions.add(_controller.loadingState.listen((state) async {
      if (state == LoadingState.navigationCompleted ||
          state == LoadingState.loading) {
        if (widget.callback != null) {
          callbackChallengeInfo();
        }
      }
    }));

    await _controller.clearCookies();
    await _controller.setBackgroundColor(Colors.transparent);
    await _controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
    await _controller.loadUrl(url);

    if (!mounted) return;
    setState(() {});
  }

  Future<WebviewPermissionDecision> _onPermissionRequested(
      String url, WebviewPermissionKind kind, bool isUserInitiated) async {
    final decision = await showDialog<WebviewPermissionDecision>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('WebView permission requested'),
        content: Text('WebView has requested permission \'$kind\''),
        actions: <Widget>[
          TextButton(
            onPressed: () =>
                Navigator.pop(context, WebviewPermissionDecision.deny),
            child: const Text('Deny'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, WebviewPermissionDecision.allow),
            child: const Text('Allow'),
          ),
        ],
      ),
    );

    return decision ?? WebviewPermissionDecision.none;
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Text(
        'Not Initialized',
        style: TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      return Webview(
        _controller,
        permissionRequested: _onPermissionRequested,
      );
    }
  }
}

class GetCookieWebView extends StatefulWidget {
  const GetCookieWebView({
    required this.url,
    this.callback,
    this.deletedCookie = true,
    super.key,
  });

  final String url;
  final WebViewCallback? callback;
  final bool deletedCookie;

  @override
  State<GetCookieWebView> createState() => GetCookieWebViewState();
}

class GetCookieWebViewState extends State<GetCookieWebView> {
  GlobalKey<_MobileWebViewState> mobileState = GlobalKey();
  GlobalKey<_WindowsWebViewState> windowsState = GlobalKey();

  Future reload() async {
    await mobileState.currentState?.reload();
    await windowsState.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    switch (Platform.operatingSystem) {
      case 'ios':
      case 'android':
        return MobileWebView(
          key: mobileState,
          url: widget.url,
          callback: widget.callback,
          deletedCookie: widget.deletedCookie,
        );
      case 'windows':
        return WindowsWebView(
            key: windowsState, url: widget.url, callback: widget.callback);
      default:
        throw UnimplementedError();
    }
  }
}
