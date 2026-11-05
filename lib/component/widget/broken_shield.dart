import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:dio/dio.dart';
import 'package:eros_n/component/theme/theme.dart';
import 'package:eros_n/component/widget/apple.dart';
import 'package:eros_n/component/widget/web_view.dart';
import 'package:eros_n/generated/l10n.dart';
import 'package:eros_n/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../common/const/const.dart';
import '../../common/global.dart';
import '../../network/app_dio/dio_http_cli.dart';

/// Gets requests through Cloudflare's "security check".
///
/// When a request is challenged (403/503), a WebView loads the site so the
/// browser can solve the challenge, then its cookies and User-Agent are
/// copied to the HTTP client and the request is retried.
class BrokenShield extends StatefulWidget {
  const BrokenShield({super.key, required this.child});

  final Widget? child;

  @override
  State<BrokenShield> createState() => _BrokenShieldState();

  static TransitionBuilder init({
    TransitionBuilder? builder,
  }) {
    return (BuildContext context, Widget? child) {
      if (builder == null) {
        return BrokenShield(child: child);
      } else {
        return builder(context, BrokenShield(child: child));
      }
    };
  }
}

class _BrokenShieldState extends State<BrokenShield> {
  OverlayEntry? entry;
  Completer<bool>? completer;

  /// Fires when the challenge did not finish on its own; the WebView is
  /// then shown so the user can complete it.
  final ValueNotifier<bool> _showWebView = ValueNotifier(false);
  final ValueNotifier<String?> _message = ValueNotifier(null);

  /// A non-challenge page that loaded without a clearance cookie is
  /// accepted after this many reports (the site let the browser through).
  static const int _kPlainPageReports = 3;
  int _plainPageReports = 0;

  GlobalKey<OverlayState> overlay = GlobalKey();

  bool get isRunning => !(completer?.isCompleted ?? true);

  Future<bool> throughHandler(DioException error) {
    if (overlay.currentState == null) {
      return Future.value(false);
    }

    if (completer != null && !completer!.isCompleted) {
      return completer!.future;
    }

    logger.d('Security check for ${error.requestOptions.uri}');
    completer = Completer();
    _showWebView.value = false;
    _message.value = null;
    _plainPageReports = 0;

    entry = OverlayEntry(
      maintainState: true,
      builder: (BuildContext context) => _ChallengeOverlay(
        showWebView: _showWebView,
        message: _message,
        webView: _ChallengeWebView(
          webViewState: webViewState,
          onCookieInfo: injectionCookieAndUA,
          onCancel: _cancel,
        ),
        onShowWebView: () => _showWebView.value = true,
        onCancel: _cancel,
      ),
    );

    overlay.currentState!.insert(entry!);

    return completer!.future;
  }

  @override
  void initState() {
    DioHttpClient(dioConfig: globalDioConfig)
        .initThroughInterceptor(throughHandler);
    super.initState();
  }

  @override
  void dispose() {
    _showWebView.dispose();
    _message.dispose();
    super.dispose();
  }

  void _finish(bool passed, {Object? error}) {
    entry?.remove();
    entry = null;
    final c = completer;
    if (c != null && !c.isCompleted) {
      if (error != null) {
        c.completeError(error);
      } else {
        c.complete(passed);
      }
    }
  }

  void _cancel() {
    _finish(false, error: Exception('用户终止了安全验证'));
  }

  Future<void> injectionCookieAndUA(WebViewCookieInfo info) async {
    if (!isRunning) {
      return;
    }
    logger.t('challenge: $info');
    if (info.message != null && info.message!.isNotEmpty) {
      _message.value = info.message;
    }
    if (info.manualRequired && !_showWebView.value) {
      _showWebView.value = true;
    }

    // Passed when the browser is past the challenge page and holds the
    // clearance cookie (or the site's own CSRF cookie). Some clients are
    // let through without a clearance cookie; accept a fully loaded,
    // non-challenge page after a few reports in that case.
    final pastChallenge = !info.challengePage && info.pageReady;
    if (pastChallenge) {
      _plainPageReports++;
    } else {
      _plainPageReports = 0;
    }
    final cleared =
        info.hasCookie('cf_clearance') || info.hasCookie('csrftoken');
    final passed =
        pastChallenge && (cleared || _plainPageReports >= _kPlainPageReports);
    if (!passed) {
      return;
    }

    logger.d('Security check passed: ${info.cookies.map((e) => e.name)}');
    if (info.userAgent.isNotEmpty) {
      await Global.setUserAgent(info.userAgent);
    }
    await Global.setCookies(NHConst.baseUrl, info.cookies);
    _finish(true);
  }

  GlobalKey<GetCookieWebViewState> webViewState = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Material(
        color: Colors.transparent,
        child: Overlay(
          key: overlay,
          initialEntries: [
            OverlayEntry(
              builder: (BuildContext context) => widget.child ?? Container(),
            ),
          ],
        ));
  }
}

/// Full screen layer: the WebView always stays laid out and visible to the
/// system (an invisible WebView may be throttled by WebKit, which stalls
/// the challenge script); until it is needed a scrim and a small status
/// card cover it.
class _ChallengeOverlay extends StatelessWidget {
  const _ChallengeOverlay({
    required this.showWebView,
    required this.message,
    required this.webView,
    required this.onShowWebView,
    required this.onCancel,
  });

  final ValueListenable<bool> showWebView;
  final ValueListenable<String?> message;
  final Widget webView;
  final VoidCallback onShowWebView;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    return ValueListenableBuilder<bool>(
      valueListenable: showWebView,
      builder: (context, visible, _) {
        return Padding(
          padding: EdgeInsets.only(
            top: (Platform.isWindows && visible) ? appWindow.titleBarHeight : 0,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              webView,
              IgnorePointer(
                ignoring: visible,
                child: AnimatedOpacity(
                  opacity: visible ? 0 : 1,
                  duration: const Duration(milliseconds: 250),
                  child: ColoredBox(
                    color: palette.groupedBackground.withValues(alpha: 0.97),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: Material(
                            color: palette.secondaryGroupedBackground,
                            shape: const RoundedSuperellipseBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(20)),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(24, 28, 24, 12),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    CupertinoIcons.checkmark_shield_fill,
                                    size: 44,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    '正在进行安全验证',
                                    style: theme.textTheme.titleMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  ValueListenableBuilder<String?>(
                                    valueListenable: message,
                                    builder: (context, value, _) => Text(
                                      (value == null || value.isEmpty)
                                          ? 'nhentai.net 需要确认你不是机器人，通常几秒内自动完成'
                                          : value,
                                      style: theme.textTheme.bodySmall,
                                      textAlign: TextAlign.center,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  const CupertinoActivityIndicator(radius: 11),
                                  const SizedBox(height: 14),
                                  Divider(color: palette.separator),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: CupertinoButton(
                                          onPressed: onCancel,
                                          child: Text(
                                            L10n.of(context).cancel,
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(
                                                    color:
                                                        palette.secondaryLabel),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: CupertinoButton(
                                          onPressed: onShowWebView,
                                          child: Text(
                                            '手动验证',
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChallengeWebView extends StatelessWidget {
  const _ChallengeWebView({
    required this.webViewState,
    required this.onCookieInfo,
    required this.onCancel,
  });

  final GlobalKey<GetCookieWebViewState> webViewState;
  final WebViewCallback onCookieInfo;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: palette.background,
      body: Column(
        children: [
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                color: palette.bar,
                padding: EdgeInsets.only(top: top),
                height: top + 52,
                child: Row(
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      onPressed: onCancel,
                      child: Text(
                        L10n.of(context).cancel,
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(color: theme.colorScheme.primary),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '安全验证',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    NavBarIconButton(
                      icon: CupertinoIcons.arrow_clockwise,
                      onPressed: () => webViewState.currentState?.reload(),
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
              ),
            ),
          ),
          Divider(color: palette.separator),
          Expanded(
            child: GetCookieWebView(
              key: webViewState,
              callback: onCookieInfo,
              // The login page sets both the Cloudflare clearance and the
              // site's CSRF cookie, which login / favorites need.
              url: NHConst.loginUrl,
            ),
          ),
        ],
      ),
    );
  }
}
