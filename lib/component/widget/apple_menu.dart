import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:eros_n/component/theme/theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shows an iOS 26 style menu (UIMenu) anchored to [anchor] (a rect in
/// global coordinates, e.g. the button or row that opened it).
///
/// The menu is a rounded glass panel that grows out of the anchor. Items
/// are 44pt rows; the [selected] one gets a leading checkmark. Completes
/// with the chosen value, or null when dismissed.
Future<T?> showAppleMenu<T>({
  required BuildContext context,
  required Rect anchor,
  required Map<T, String> items,
  T? selected,
  String? title,
  Map<T, IconData>? icons,
}) {
  HapticFeedback.lightImpact();
  final navigator = Navigator.of(context, rootNavigator: true);
  final overlay = navigator.context.findRenderObject()! as RenderBox;
  final origin = overlay.localToGlobal(Offset.zero);
  return navigator.push<T>(_AppleMenuRoute<T>(
    anchor: anchor.shift(-origin),
    items: items,
    selected: selected,
    title: title,
    icons: icons,
    capturedThemes:
        InheritedTheme.capture(from: context, to: navigator.context),
  ));
}

/// The global rect of the widget that owns [context].
Rect? globalRectOf(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize || !box.attached) {
    return null;
  }
  return box.localToGlobal(Offset.zero) & box.size;
}

/// Not a [PopupRoute] on purpose: the Liquid Glass navigator observer fades
/// out every native glass view while a popup route is open, which would
/// hide the very button that opened the menu (and the tab bar). The menu
/// never covers those views, so they can stay.
class _AppleMenuRoute<T> extends ModalRoute<T> {
  _AppleMenuRoute({
    required this.anchor,
    required this.items,
    required this.capturedThemes,
    this.selected,
    this.title,
    this.icons,
  });

  final Rect anchor;
  final Map<T, String> items;
  final T? selected;
  final String? title;
  final Map<T, IconData>? icons;
  final CapturedThemes capturedThemes;

  @override
  bool get opaque => false;

  @override
  bool get maintainState => true;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 320);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 180);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final mq = MediaQuery.of(context);
    final size = mq.size;
    final alignRight = anchor.center.dx > size.width / 2;
    // Below the anchor unless it sits in the lower part of the screen.
    final below = anchor.center.dy < size.height * 0.62;
    final alignment = Alignment(alignRight ? 1 : -1, below ? -1 : 1);

    return capturedThemes.wrap(
      MediaQuery.removePadding(
        context: context,
        removeTop: true,
        removeBottom: true,
        child: CustomSingleChildLayout(
          delegate: _AppleMenuLayout(
            anchor: anchor,
            alignRight: alignRight,
            below: below,
            padding: mq.padding,
          ),
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final t = animation.status == AnimationStatus.reverse
                  ? Curves.easeIn.transform(animation.value)
                  : Curves.easeOutBack.transform(animation.value);
              return Opacity(
                opacity: Curves.easeOut.transform(animation.value),
                child: Transform.scale(
                  scale: 0.6 + 0.4 * t,
                  alignment: alignment,
                  child: child,
                ),
              );
            },
            child: _AppleMenuPanel<T>(
              items: items,
              selected: selected,
              title: title,
              icons: icons,
              onSelected: (value) => Navigator.of(context).pop(value),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppleMenuLayout extends SingleChildLayoutDelegate {
  _AppleMenuLayout({
    required this.anchor,
    required this.alignRight,
    required this.below,
    required this.padding,
  });

  final Rect anchor;
  final bool alignRight;
  final bool below;
  final EdgeInsets padding;

  static const double _margin = 10;
  static const double _gap = 6;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final maxHeight = math.max(
      120.0,
      below
          ? constraints.maxHeight - anchor.bottom - _gap - padding.bottom - 16
          : anchor.top - _gap - padding.top - 16,
    );
    return BoxConstraints(
      minWidth: 0,
      maxWidth: math.min(300, constraints.maxWidth - _margin * 2),
      maxHeight: maxHeight,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    var x = alignRight ? anchor.right - childSize.width : anchor.left;
    x = x.clamp(_margin, math.max(_margin, size.width - childSize.width - _margin));
    var y = below ? anchor.bottom + _gap : anchor.top - _gap - childSize.height;
    y = y.clamp(
      padding.top + 8,
      math.max(padding.top + 8, size.height - childSize.height - padding.bottom - 8),
    );
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_AppleMenuLayout oldDelegate) {
    return anchor != oldDelegate.anchor ||
        alignRight != oldDelegate.alignRight ||
        below != oldDelegate.below ||
        padding != oldDelegate.padding;
  }
}

class _AppleMenuPanel<T> extends StatelessWidget {
  const _AppleMenuPanel({
    required this.items,
    required this.onSelected,
    this.selected,
    this.title,
    this.icons,
  });

  final Map<T, String> items;
  final T? selected;
  final String? title;
  final Map<T, IconData>? icons;
  final ValueChanged<T> onSelected;

  static const double radius = 24;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    final dark = palette.brightness == Brightness.dark;
    final shape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(radius),
    );

    final rows = <Widget>[
      if (title != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
          child: Text(
            title!,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: palette.secondaryLabel),
          ),
        ),
      for (final entry in items.entries)
        _AppleMenuItem(
          label: entry.value,
          checked: entry.key == selected,
          icon: icons?[entry.key],
          onTap: () {
            HapticFeedback.selectionClick();
            onSelected(entry.key);
          },
        ),
    ];

    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.45 : 0.16),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: dark ? const Color(0xC72A2A2C) : const Color(0xD9F9F9F9),
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(radius),
                side: BorderSide(
                  color: dark
                      ? Colors.white.withValues(alpha: 0.10)
                      : Colors.white.withValues(alpha: 0.6),
                  width: 0.6,
                ),
              ),
            ),
            child: IntrinsicWidth(
              stepWidth: 8,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 200),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: rows,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppleMenuItem extends StatefulWidget {
  const _AppleMenuItem({
    required this.label,
    required this.checked,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool checked;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  State<_AppleMenuItem> createState() => _AppleMenuItemState();
}

class _AppleMenuItemState extends State<_AppleMenuItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    final dark = palette.brightness == Brightness.dark;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          constraints: const BoxConstraints(minHeight: 44),
          decoration: BoxDecoration(
            color: _pressed
                ? (dark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.black.withValues(alpha: 0.07))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.fromLTRB(8, 10, 14, 10),
          child: Row(
            children: [
              SizedBox(
                width: 26,
                child: widget.checked
                    ? Icon(CupertinoIcons.checkmark_alt,
                        size: 18, color: palette.label)
                    : null,
              ),
              const SizedBox(width: 4),
              Flexible(
                fit: FlexFit.tight,
                child: Text(
                  widget.label,
                  style:
                      theme.textTheme.bodyLarge?.copyWith(color: palette.label),
                ),
              ),
              if (widget.icon != null) ...[
                const SizedBox(width: 12),
                Icon(widget.icon, size: 19, color: palette.label),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
