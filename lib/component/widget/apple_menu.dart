import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:eros_n/component/theme/theme.dart';
import 'package:eros_n/component/widget/liquid_glass.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

/// Metrics of an iOS 26 menu (measured from the system Settings app).
class _MenuMetrics {
  static const double rowHeight = 44;
  static const double verticalPadding = 8;
  static const double titleHeight = 30;
  static const double radius = 26;
  static const double leading = 44;
  static const double trailing = 24;
  static const double minWidth = 220;
  static const double maxWidth = 300;
  static const double margin = 12;
}

/// Shows an iOS 26 menu (UIMenu) for [items].
///
/// The menu is a Liquid Glass panel that morphs out of [anchor] (a global
/// rect: the button or value that opened it) with a spring, and morphs back
/// into it when dismissed. With [popUp] (pop-up buttons such as a settings
/// row) the selected item is placed over the anchor; otherwise the menu
/// drops down from (or up above) the anchor. The selected item has a
/// leading checkmark. Tapping outside dismisses the menu without passing
/// the tap through.
///
/// It is shown in the root overlay, not as a route, so native glass views
/// on the page (which hide themselves when their route is covered) stay
/// visible while it is open.
Future<T?> showAppleMenu<T>({
  required BuildContext context,
  required Rect anchor,
  required Map<T, String> items,
  T? selected,
  String? title,
  Map<T, IconData>? icons,
  bool popUp = false,
}) {
  HapticFeedback.lightImpact();
  final overlay = Overlay.of(context, rootOverlay: true);
  final overlayBox = overlay.context.findRenderObject()! as RenderBox;
  final origin = overlayBox.localToGlobal(Offset.zero);
  final completer = Completer<T?>();
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => InheritedTheme.captureAll(
      context,
      _AppleMenuOverlay<T>(
        anchor: anchor.shift(-origin),
        items: items,
        selected: selected,
        title: title,
        icons: icons,
        popUp: popUp,
        textStyle: Theme.of(context).textTheme.bodyLarge,
        onClosed: (value) {
          entry.remove();
          if (!completer.isCompleted) {
            completer.complete(value);
          }
        },
      ),
    ),
  );
  overlay.insert(entry);
  return completer.future;
}

/// Liquid Glass used by floating panels (menus, alerts, sheets): a
/// strongly tinted, blurred glass with a refracting rim, so text on it stays
/// legible while the content behind still shows through.
LiquidGlassStyle glassPanelStyle(bool dark, {double opacity = 0.72}) {
  final a = (opacity * 255).round();
  return LiquidGlassStyle(
    tint: dark
        ? Color.fromARGB(a, 0x3A, 0x3A, 0x3D)
        : Color.fromARGB(a, 0xF6, 0xF6, 0xF7),
    blur: 18,
    refraction: 10,
    bevel: 16,
    dispersion: 0.04,
    saturation: 1.5,
    brightness: dark ? 1.02 : 1.0,
    highlight: dark ? 0.5 : 0.7,
    shadowColor: dark ? const Color(0x73000000) : const Color(0x33000000),
    shadowBlur: 34,
    shadowOffset: const Offset(0, 14),
    fallbackTint: dark ? const Color(0xE63A3A3D) : const Color(0xEBF6F6F7),
    fallbackBlur: 24,
    borderColor: dark ? const Color(0x33FFFFFF) : const Color(0x99FFFFFF),
  );
}

/// The global rect of the widget that owns [context].
Rect? globalRectOf(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize || !box.attached) {
    return null;
  }
  return box.localToGlobal(Offset.zero) & box.size;
}

class _AppleMenuOverlay<T> extends StatefulWidget {
  const _AppleMenuOverlay({
    required this.anchor,
    required this.items,
    required this.onClosed,
    required this.popUp,
    this.selected,
    this.title,
    this.icons,
    this.textStyle,
  });

  final Rect anchor;
  final Map<T, String> items;
  final T? selected;
  final String? title;
  final Map<T, IconData>? icons;
  final bool popUp;
  final TextStyle? textStyle;
  final ValueChanged<T?> onClosed;

  @override
  State<_AppleMenuOverlay<T>> createState() => _AppleMenuOverlayState<T>();
}

class _AppleMenuOverlayState<T> extends State<_AppleMenuOverlay<T>>
    with SingleTickerProviderStateMixin {
  // Opening: an under-damped spring (slight overshoot, like UIKit's
  // menu morph); closing: a quick ease back into the source.
  late final AnimationController _controller = AnimationController.unbounded(
    vsync: this,
  )..animateWith(SpringSimulation(
      const SpringDescription(mass: 1, stiffness: 300, damping: 26),
      0,
      1,
      0,
    ));
  bool _closing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _close([T? value]) async {
    if (_closing) {
      return;
    }
    _closing = true;
    if (value != null) {
      HapticFeedback.selectionClick();
    }
    await _controller.animateTo(
      0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInCubic,
    );
    widget.onClosed(value);
  }

  double _labelWidth(String text) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: widget.textStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  /// Final rect of the panel within [size].
  Rect _layout(Size size, EdgeInsets padding) {
    final entries = widget.items.values.toList();
    var labels = 0.0;
    for (final label in entries) {
      labels = math.max(labels, _labelWidth(label));
    }
    final hasIcons = widget.icons?.isNotEmpty ?? false;
    final width = (_MenuMetrics.leading +
            labels +
            _MenuMetrics.trailing +
            (hasIcons ? 32 : 0))
        .clamp(
          _MenuMetrics.minWidth,
          math.min(_MenuMetrics.maxWidth, size.width - _MenuMetrics.margin * 2),
        );
    final titleHeight = widget.title == null ? 0.0 : _MenuMetrics.titleHeight;
    final top = padding.top + 8;
    final bottom = size.height - padding.bottom - 8;
    final height = math.min(
      _MenuMetrics.verticalPadding * 2 +
          titleHeight +
          entries.length * _MenuMetrics.rowHeight,
      bottom - top,
    );

    final anchor = widget.anchor;
    final alignRight = anchor.center.dx > size.width / 2;
    var x = alignRight ? anchor.right - width : anchor.left;
    x = x.clamp(_MenuMetrics.margin,
        math.max(_MenuMetrics.margin, size.width - width - _MenuMetrics.margin));

    double y;
    final selectedIndex = widget.items.keys.toList().indexOf(
          widget.selected as T,
        );
    if (widget.popUp && selectedIndex >= 0) {
      // Pop-up button: the selected item sits over the anchor.
      y = anchor.center.dy -
          (_MenuMetrics.verticalPadding +
              titleHeight +
              selectedIndex * _MenuMetrics.rowHeight +
              _MenuMetrics.rowHeight / 2);
    } else if (anchor.center.dy < size.height * 0.6) {
      y = anchor.bottom + 8;
    } else {
      y = anchor.top - 8 - height;
    }
    y = y.clamp(top, math.max(top, bottom - height));
    return Rect.fromLTWH(x, y, width.toDouble(), height);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final palette = context.palette;
    final dark = palette.brightness == Brightness.dark;
    final finalRect = _layout(mq.size, mq.padding);
    // The morph starts from the source control (at least a small capsule).
    final source = Rect.fromCenter(
      center: widget.anchor.center,
      width: math.max(36, math.min(widget.anchor.width, finalRect.width)),
      height: math.max(30, math.min(widget.anchor.height, 44)),
    );

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _close(),
            onPanDown: (_) => _close(),
          ),
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;
            final rect = Rect.lerp(source, finalRect, t)!;
            final radius = math.min(
              lerpDouble(source.height / 2, _MenuMetrics.radius,
                  t.clamp(0.0, 1.0))!,
              rect.shortestSide / 2,
            );
            final contentOpacity = ((t - 0.35) / 0.5).clamp(0.0, 1.0);
            return Positioned.fromRect(
              rect: rect,
              child: LiquidGlass(
                borderRadius: radius,
                style: glassPanelStyle(dark),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: OverflowBox(
                    alignment: Alignment.topLeft,
                    minWidth: finalRect.width,
                    maxWidth: finalRect.width,
                    minHeight: finalRect.height,
                    maxHeight: finalRect.height,
                    child: Transform.translate(
                      offset: finalRect.topLeft - rect.topLeft,
                      child: Opacity(
                        opacity: contentOpacity,
                        child: child,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
          child: _AppleMenuContent<T>(
            items: widget.items,
            selected: widget.selected,
            title: widget.title,
            icons: widget.icons,
            onSelected: _close,
          ),
        ),
      ],
    );
  }
}

class _AppleMenuContent<T> extends StatelessWidget {
  const _AppleMenuContent({
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

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    return Material(
      type: MaterialType.transparency,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
            vertical: _MenuMetrics.verticalPadding),
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              SizedBox(
                height: _MenuMetrics.titleHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: palette.secondaryLabel),
                    ),
                  ),
                ),
              ),
            for (final entry in items.entries)
              _AppleMenuItem(
                label: entry.value,
                checked: entry.key == selected,
                icon: icons?[entry.key],
                onTap: () => onSelected(entry.key),
              ),
          ],
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
      child: SizedBox(
        height: _MenuMetrics.rowHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            decoration: BoxDecoration(
              color: _pressed
                  ? (dark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.08))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(_MenuMetrics.radius - 8),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: _MenuMetrics.leading - 8,
                  child: widget.checked
                      ? Icon(CupertinoIcons.checkmark_alt,
                          size: 19, color: palette.label)
                      : null,
                ),
                Expanded(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        theme.textTheme.bodyLarge?.copyWith(color: palette.label),
                  ),
                ),
                if (widget.icon != null) ...[
                  const SizedBox(width: 12),
                  Icon(widget.icon, size: 19, color: palette.label),
                ],
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
