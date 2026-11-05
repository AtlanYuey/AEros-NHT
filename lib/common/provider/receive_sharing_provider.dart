import 'dart:async';

import 'package:eros_n/common/global.dart';
import 'package:eros_n/routes/routes.dart';
import 'package:eros_n/utils/get_utils/get_utils.dart';
import 'package:eros_n/utils/logger.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class ReceiveSharingNotifier extends StateNotifier<void> {
  ReceiveSharingNotifier(this.ref) : super(null);

  final Ref ref;

  String? sharedText;

  Future<void> _goPage(
    String url,
    WidgetRef widgetRef, {
    bool replace = true,
  }) async {
    if (url.isEmpty ||
        !(await RouteUtil.goGalleryByUrl(widgetRef, url, replace: replace))) {
      0
          .milliseconds
          .delay()
          .then((value) => erosRouter.replaceNamed(NHRoutes.home));
    }
  }

  String _textOf(List<SharedMediaFile> files) {
    for (final file in files) {
      if (file.type == SharedMediaType.text ||
          file.type == SharedMediaType.url) {
        return file.path;
      }
    }
    return '';
  }

  void listenReceiveSharing(WidgetRef widgetRef) {
    // For sharing or opening urls/text coming from outside the app while the app is in the memory
    ReceiveSharingIntent.instance.getMediaStream().listen(
        (List<SharedMediaFile> value) {
      final text = _textOf(value);
      if (text.isEmpty) {
        return;
      }
      sharedText = text;
      logger.d('getMediaStream Shared: $sharedText');
      _goPage(sharedText ?? '', widgetRef, replace: false);
    }, onError: (Object err) {
      logger.e('getMediaStream error: $err');
    });

    // For sharing or opening urls/text coming from outside the app while the app is closed
    ReceiveSharingIntent.instance
        .getInitialMedia()
        .then((List<SharedMediaFile> value) {
      final text = _textOf(value);
      logger.d('getInitialMedia Shared: $text');

      if (text.isEmpty || text == sharedText) {
        return;
      }

      sharedText = text;
      _goPage(sharedText ?? '', widgetRef, replace: false);
      ReceiveSharingIntent.instance.reset();
    });
  }
}

final receiveSharingProvider =
    StateNotifierProvider.autoDispose<ReceiveSharingNotifier, void>((ref) {
  return ReceiveSharingNotifier(ref);
});
