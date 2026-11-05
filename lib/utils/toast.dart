import 'package:eros_n/utils/get_utils/get_utils.dart';
import 'package:eros_n/component/theme/theme.dart';
import 'package:eros_n/component/widget/apple.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

void showActionToast(String msg, {IconData? icon, VoidCallback? onPressed}) {
  SmartDialog.show(
    alignment: Alignment.bottomCenter,
    useAnimation: true,
    displayTime: 5.seconds,
    // consumeEvent: true,
    usePenetrate: true,
    clickMaskDismiss: false,
    maskColor: Colors.transparent,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: GlassContainer(
            borderRadius: 22,
            padding: const EdgeInsets.only(left: 18, right: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      msg,
                      style: Theme.of(context).textTheme.bodyMedium,
                      softWrap: true,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  onPressed: () {
                    SmartDialog.dismiss();
                    onPressed?.call();
                  },
                  child: Icon(
                    icon ?? CupertinoIcons.arrow_right_circle_fill,
                    size: 28,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Short glass notice near the bottom of the screen (replaces Material
/// snack bars).
void showToast(String msg, {IconData? icon}) {
  SmartDialog.show(
    alignment: Alignment.bottomCenter,
    useAnimation: true,
    displayTime: 3.seconds,
    usePenetrate: true,
    clickMaskDismiss: false,
    maskColor: Colors.transparent,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 96),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: GlassContainer(
            borderRadius: 24,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: context.palette.label),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Text(
                    msg,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

