import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

@RoutePage()
class NhWebViewPage extends StatelessWidget {
  const NhWebViewPage({Key? key, required this.initialUrl, this.title})
      : super(key: key);
  final String initialUrl;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? ''),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri(initialUrl),
        ),
        initialSettings: inAppWebViewSettings,
      ),
    );
  }
}

final InAppWebViewSettings inAppWebViewSettings = InAppWebViewSettings(
  useShouldOverrideUrlLoading: true,
  mediaPlaybackRequiresUserGesture: false,
  useHybridComposition: true,
  allowsInlineMediaPlayback: true,
);
