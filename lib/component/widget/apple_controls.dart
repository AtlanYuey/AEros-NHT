import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:eros_n/component/theme/theme.dart';
import 'package:eros_n/component/widget/liquid_glass.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

/// iOS 26 control metrics (UISwitch / UISlider, measured on iOS 26).
class _Metrics {
  static const double switchWidth = 63;
  static const double switchHeight = 28;
  static const double thumbWidth = 37;
  static const double thumbHeight = 24;

  /// While touched, the thumb grows into a Liquid Glass lens.
  static const double lensWidth = 58;
  static const double lensHeight = 38.333;

  static const double trackHeight = 6;
}

/// Spring used by UIKit for the thumb morph (damping 0.6, ~0.4s).
const SpringDescription _morphSpring = SpringDescription(
  mass: 1,
  stiffness: 380,
  damping: 24,
);

/// Spring for thumb travel (critically damped, ~0.5s).
const SpringDescription _travelSpring = SpringDescription(
  mass: 1,
  stiffness: 300,
  damping: 34.6,
);

/// The clear lens a control thumb turns into while it is touched.
LiquidGlassStyle _lensStyle(bool dark) => LiquidGlassStyle(
      tint: dark ? const Color(0x14FFFFFF) : const Color(0x0AFFFFFF),
      blur: 0,
      refraction: 7,
      bevel: 12,
      dispersion: 0.05,
      saturation: 1.15,
      brightness: 1.04,
      highlight: 0.9,
      shadowColor: const Color(0x33000000),
      shadowBlur: 10,
      shadowOffset: const Offset(0, 3),
      fallbackTint: dark ? const Color(0x33FFFFFF) : const Color(0x66FFFFFF),
      fallbackBlur: 2,
      borderColor: const Color(0x99FFFFFF),
    );

/// Animates a 0..1 value with a spring.
class _SpringValue {
  _SpringValue(TickerProvider vsync, double initial)
      : controller = AnimationController.unbounded(vsync: vsync, value: initial);

  final AnimationController controller;

  double get value => controller.value;

  void animateTo(double target, SpringDescription spring,
      {double velocity = 0}) {
    controller.animateWith(
        SpringSimulation(spring, controller.value, target, velocity));
  }

  void jumpTo(double value) {
    controller.stop();
    controller.value = value;
  }

  void dispose() => controller.dispose();
}

/// The white capsule thumb, morphing into a glass lens while [press] > 0.
class _MorphingThumb extends StatelessWidget {
  const _MorphingThumb({required this.press, required this.dark});

  final double press;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final p = press.clamp(0.0, 1.2);
    final width = lerpDouble(_Metrics.thumbWidth, _Metrics.lensWidth, p)!;
    final height = lerpDouble(_Metrics.thumbHeight, _Metrics.lensHeight, p)!;
    final pillOpacity = (1 - p * 1.6).clamp(0.0, 1.0);
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (p > 0.02)
            LiquidGlass(
              borderRadius: height / 2,
              style: _lensStyle(dark),
              child: const SizedBox.expand(),
            ),
          if (pillOpacity > 0)
            Opacity(
              opacity: pillOpacity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(height / 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                    BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 1,
                      offset: Offset(0, 0.5),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// iOS 26 switch: a 63×28 track with a capsule thumb that turns into a
/// Liquid Glass lens while touched; it can be tapped or dragged.
class AppleSwitch extends StatefulWidget {
  const AppleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Defaults to system green.
  final Color? activeColor;

  @override
  State<AppleSwitch> createState() => _AppleSwitchState();
}

class _AppleSwitchState extends State<AppleSwitch>
    with TickerProviderStateMixin {
  late final _SpringValue _position =
      _SpringValue(this, widget.value ? 1 : 0);
  late final _SpringValue _press = _SpringValue(this, 0);
  bool _dragging = false;
  bool _dragValue = false;

  static const double _travel =
      _Metrics.switchWidth - _Metrics.thumbWidth - 4;

  bool get _enabled => widget.onChanged != null;

  @override
  void didUpdateWidget(AppleSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_dragging) {
      _position.animateTo(widget.value ? 1 : 0, _travelSpring);
    }
  }

  @override
  void dispose() {
    _position.dispose();
    _press.dispose();
    super.dispose();
  }

  void _expand() => _press.animateTo(1, _morphSpring);

  void _contract() => _press.animateTo(0, _morphSpring);

  void _emit(bool value) {
    if (value != widget.value) {
      HapticFeedback.lightImpact();
      widget.onChanged?.call(value);
    }
  }

  void _onTap() {
    final next = !widget.value;
    _position.animateTo(next ? 1 : 0, _travelSpring);
    _emit(next);
    Future<void>.delayed(const Duration(milliseconds: 160), () {
      if (mounted && !_dragging) {
        _contract();
      }
    });
  }

  void _onDragStart(DragStartDetails details) {
    _dragging = true;
    _dragValue = widget.value;
    _position.controller.stop();
    _expand();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    var next = _position.value + details.primaryDelta! / _travel;
    // Rubber band beyond the ends.
    if (next < 0) {
      next = -math.sqrt(-next) * 0.08;
    } else if (next > 1) {
      next = 1 + math.sqrt(next - 1) * 0.08;
    }
    _position.jumpTo(next);
    if (next <= 0.05 && _dragValue) {
      _dragValue = false;
      HapticFeedback.lightImpact();
    } else if (next >= 0.95 && !_dragValue) {
      _dragValue = true;
      HapticFeedback.lightImpact();
    }
  }

  void _onDragEnd(DragEndDetails details) {
    _dragging = false;
    final velocity = details.primaryVelocity ?? 0;
    final bool next;
    if (velocity.abs() > 300) {
      next = velocity > 0;
    } else {
      next = _position.value > 0.5;
    }
    _position.animateTo(next ? 1 : 0, _travelSpring);
    _contract();
    if (next != widget.value) {
      widget.onChanged?.call(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dark = palette.brightness == Brightness.dark;
    final on = widget.activeColor ??
        (dark ? const Color(0xFF30D158) : const Color(0xFF34C759));
    // systemFill
    final off = dark ? const Color(0x5C787880) : const Color(0x33787880);

    final Widget content = AnimatedBuilder(
      animation: Listenable.merge([_position.controller, _press.controller]),
      builder: (context, _) {
        final t = _position.value;
        final press = _press.value;
        final thumbCenter = 2 + _Metrics.thumbWidth / 2 + t * _travel;
        return SizedBox(
          width: _Metrics.switchWidth,
          height: _Metrics.switchHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color.lerp(off, on, t.clamp(0.0, 1.0)),
                    borderRadius:
                        BorderRadius.circular(_Metrics.switchHeight / 2),
                  ),
                ),
              ),
              Positioned(
                left: thumbCenter - 100,
                width: 200,
                top: _Metrics.switchHeight / 2 - 100,
                height: 200,
                child: Center(
                  child: _MorphingThumb(press: press, dark: dark),
                ),
              ),
            ],
          ),
        );
      },
    );

    return Semantics(
      toggled: widget.value,
      enabled: _enabled,
      child: Opacity(
        opacity: _enabled ? 1 : 0.5,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _enabled ? (_) => _expand() : null,
          onTapCancel: _enabled ? _contract : null,
          onTap: _enabled ? _onTap : null,
          onHorizontalDragStart: _enabled ? _onDragStart : null,
          onHorizontalDragUpdate: _enabled ? _onDragUpdate : null,
          onHorizontalDragEnd: _enabled ? _onDragEnd : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// iOS 26 slider: a 6pt track with a capsule thumb that turns into a Liquid
/// Glass lens while dragged. Snaps to [divisions] with a haptic tick.
class AppleSlider extends StatefulWidget {
  const AppleSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.onChangeEnd,
    this.activeColor,
  });

  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;
  final Color? activeColor;

  @override
  State<AppleSlider> createState() => _AppleSliderState();
}

class _AppleSliderState extends State<AppleSlider>
    with TickerProviderStateMixin {
  late final _SpringValue _press = _SpringValue(this, 0);
  late final _SpringValue _position =
      _SpringValue(this, _fraction(widget.value));
  double _dragFraction = 0;
  bool _dragging = false;
  double _width = 1;

  double _fraction(double value) {
    final range = widget.max - widget.min;
    if (range <= 0) {
      return 0;
    }
    return ((value - widget.min) / range).clamp(0.0, 1.0);
  }

  double _snap(double fraction) {
    final d = widget.divisions;
    if (d == null || d <= 0) {
      return fraction.clamp(0.0, 1.0);
    }
    return (fraction.clamp(0.0, 1.0) * d).round() / d;
  }

  double _valueOf(double fraction) =>
      widget.min + (widget.max - widget.min) * fraction;

  @override
  void didUpdateWidget(AppleSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging && oldWidget.value != widget.value) {
      _position.animateTo(_fraction(widget.value), _travelSpring);
    }
  }

  @override
  void dispose() {
    _press.dispose();
    _position.dispose();
    super.dispose();
  }

  double get _travel => math.max(1, _width - _Metrics.thumbWidth);

  void _start() {
    _dragging = true;
    _dragFraction = _fraction(widget.value);
    _position.controller.stop();
    _press.animateTo(1, _morphSpring);
  }

  void _update(double dx) {
    _dragFraction += dx / _travel;
    // A little stretch beyond the ends.
    var shown = _dragFraction;
    if (shown < 0) {
      shown = -math.sqrt(-shown) * 0.03;
    } else if (shown > 1) {
      shown = 1 + math.sqrt(shown - 1) * 0.03;
    }
    final snapped = _snap(_dragFraction);
    _position.jumpTo(widget.divisions == null ? shown : snapped);
    final value = _valueOf(snapped);
    if (value != widget.value) {
      if (widget.divisions != null) {
        HapticFeedback.selectionClick();
      }
      widget.onChanged?.call(value);
    }
  }

  void _end() {
    _dragging = false;
    final snapped = _snap(_dragFraction);
    _position.animateTo(snapped, _travelSpring);
    _press.animateTo(0, _morphSpring);
    widget.onChangeEnd?.call(_valueOf(snapped));
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dark = palette.brightness == Brightness.dark;
    final active = widget.activeColor ?? Theme.of(context).colorScheme.primary;
    // quaternaryLabel
    final inactive = dark ? const Color(0x29EBEBF5) : const Color(0x2E3C3C43);
    final enabled = widget.onChanged != null;

    return LayoutBuilder(builder: (context, constraints) {
      _width = constraints.maxWidth;
      return Opacity(
        opacity: enabled ? 1 : 0.5,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: enabled ? (_) => _start() : null,
          onHorizontalDragUpdate:
              enabled ? (d) => _update(d.primaryDelta ?? 0) : null,
          onHorizontalDragEnd: enabled ? (_) => _end() : null,
          onHorizontalDragCancel: enabled ? _end : null,
          onTapDown: enabled ? (_) => _press.animateTo(1, _morphSpring) : null,
          onTapUp: enabled ? (_) => _press.animateTo(0, _morphSpring) : null,
          onTapCancel: enabled ? () => _press.animateTo(0, _morphSpring) : null,
          child: SizedBox(
            height: 44,
            child: AnimatedBuilder(
              animation:
                  Listenable.merge([_position.controller, _press.controller]),
              builder: (context, _) {
                final t = _position.value;
                final thumbCenter = _Metrics.thumbWidth / 2 + t * _travel;
                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 22 - _Metrics.trackHeight / 2,
                      height: _Metrics.trackHeight,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: inactive,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      width: thumbCenter.clamp(0.0, _width),
                      top: 22 - _Metrics.trackHeight / 2,
                      height: _Metrics.trackHeight,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: active,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    Positioned(
                      left: thumbCenter - 100,
                      width: 200,
                      top: 22 - 100,
                      height: 200,
                      child: Center(
                        child: _MorphingThumb(
                          press: _press.value,
                          dark: dark,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    });
  }
}

/// iOS 26 segmented control: a capsule track with a capsule thumb that
/// slides between segments (and becomes glass while dragged).
class AppleSegmentedControl<T extends Object> extends StatefulWidget {
  const AppleSegmentedControl({
    super.key,
    required this.children,
    required this.groupValue,
    required this.onValueChanged,
  });

  final Map<T, Widget> children;
  final T groupValue;
  final ValueChanged<T> onValueChanged;

  @override
  State<AppleSegmentedControl<T>> createState() =>
      _AppleSegmentedControlState<T>();
}

class _AppleSegmentedControlState<T extends Object>
    extends State<AppleSegmentedControl<T>> with TickerProviderStateMixin {
  late final _SpringValue _position =
      _SpringValue(this, _indexOf(widget.groupValue).toDouble());
  late final _SpringValue _press = _SpringValue(this, 0);
  bool _dragging = false;
  double _segmentWidth = 1;

  static const double _height = 36;
  static const double _inset = 3;

  List<T> get _keys => widget.children.keys.toList();

  int _indexOf(T value) => math.max(0, _keys.indexOf(value));

  @override
  void didUpdateWidget(AppleSegmentedControl<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging && oldWidget.groupValue != widget.groupValue) {
      _position.animateTo(
          _indexOf(widget.groupValue).toDouble(), _travelSpring);
    }
  }

  @override
  void dispose() {
    _position.dispose();
    _press.dispose();
    super.dispose();
  }

  void _select(int index) {
    final key = _keys[index];
    _position.animateTo(index.toDouble(), _travelSpring);
    if (key != widget.groupValue) {
      HapticFeedback.selectionClick();
      widget.onValueChanged(key);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dark = palette.brightness == Brightness.dark;
    final count = widget.children.length;
    // tertiarySystemFill track; raised thumb.
    final track = dark ? const Color(0x3D767680) : const Color(0x1F767680);
    final thumb = dark ? const Color(0xFF5C5C60) : Colors.white;

    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      _segmentWidth = (width - _inset * 2) / count;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) {
          final i = ((d.localPosition.dx - _inset) / _segmentWidth)
              .floor()
              .clamp(0, count - 1);
          if (i == _position.value.round()) {
            _press.animateTo(1, _morphSpring);
          }
        },
        onTapUp: (d) {
          _press.animateTo(0, _morphSpring);
          final i = ((d.localPosition.dx - _inset) / _segmentWidth)
              .floor()
              .clamp(0, count - 1);
          _select(i);
        },
        onTapCancel: () => _press.animateTo(0, _morphSpring),
        onHorizontalDragStart: (_) {
          _dragging = true;
          _press.animateTo(1, _morphSpring);
        },
        onHorizontalDragUpdate: (d) {
          final next = (_position.value + d.primaryDelta! / _segmentWidth)
              .clamp(-0.15, count - 1 + 0.15);
          _position.jumpTo(next);
        },
        onHorizontalDragEnd: (_) {
          _dragging = false;
          _press.animateTo(0, _morphSpring);
          _select(_position.value.round().clamp(0, count - 1));
        },
        child: SizedBox(
          height: _height,
          child: AnimatedBuilder(
            animation:
                Listenable.merge([_position.controller, _press.controller]),
            builder: (context, _) {
              final press = _press.value.clamp(0.0, 1.2);
              final grow = 3 * press;
              final left = _inset + _position.value * _segmentWidth - grow;
              final thumbWidth = _segmentWidth + grow * 2;
              final thumbHeight = _height - _inset * 2 + grow * 2;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: track,
                        borderRadius: BorderRadius.circular(_height / 2),
                      ),
                    ),
                  ),
                  Positioned(
                    left: left,
                    top: _inset - grow,
                    width: thumbWidth,
                    height: thumbHeight,
                    child: press > 0.05
                        ? LiquidGlass(
                            borderRadius: thumbHeight / 2,
                            style: _lensStyle(dark).copyWith(
                              tint: dark
                                  ? const Color(0x40FFFFFF)
                                  : const Color(0x80FFFFFF),
                            ),
                            child: const SizedBox.expand(),
                          )
                        : DecoratedBox(
                            decoration: BoxDecoration(
                              color: thumb,
                              borderRadius:
                                  BorderRadius.circular(thumbHeight / 2),
                              boxShadow: dark
                                  ? null
                                  : const [
                                      BoxShadow(
                                        color: Color(0x1F000000),
                                        blurRadius: 8,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                            ),
                          ),
                  ),
                  Row(
                    children: [
                      const SizedBox(width: _inset),
                      for (var i = 0; i < count; i++)
                        Expanded(
                          child: Center(
                            child: DefaultTextStyle.merge(
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: palette.label,
                                    fontWeight: i == _position.value.round()
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                              child: IconTheme.merge(
                                data: IconThemeData(
                                    color: palette.label, size: 16),
                                child: widget.children[_keys[i]]!,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: _inset),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      );
    });
  }
}
