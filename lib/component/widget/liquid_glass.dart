import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:eros_n/utils/logger.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Loads and hands out the liquid glass fragment shader.
class LiquidGlassShader {
  LiquidGlassShader._();

  static const String assetKey = 'shaders/liquid_glass.frag';

  static ui.FragmentProgram? _program;

  /// Load the shader once at start-up. Safe to call more than once.
  static Future<void> load() async {
    if (_program != null) {
      return;
    }
    try {
      _program = await ui.FragmentProgram.fromAsset(assetKey);
    } catch (e, stack) {
      logger.e('Liquid glass shader unavailable: $e\n$stack');
    }
  }

  /// Whether real refraction can be rendered (Impeller + shader loaded).
  static bool get isAvailable =>
      _program != null && ui.ImageFilter.isShaderFilterSupported;

  static ui.FragmentShader? createShader() => _program?.fragmentShader();

  /// Test hook: replace the program (e.g. with a debug shader).
  @visibleForTesting
  static set debugProgram(ui.FragmentProgram? program) => _program = program;
}

/// Optical parameters of a glass surface (logical pixels).
@immutable
class LiquidGlassStyle {
  const LiquidGlassStyle({
    this.tint = const Color(0x14FFFFFF),
    this.blur = 2,
    this.refraction = 12,
    this.bevel = 16,
    this.dispersion = 0.06,
    this.saturation = 1.3,
    this.brightness = 1.04,
    this.highlight = 0.6,
    this.lightDirection = const Offset(-0.55, -0.85),
    this.shadowColor = const Color(0x24000000),
    this.shadowBlur = 18,
    this.shadowOffset = const Offset(0, 6),
    this.fallbackTint = const Color(0x66FFFFFF),
    this.fallbackBlur = 14,
    this.borderColor = const Color(0x80FFFFFF),
  });

  /// Light glass over light content.
  static const LiquidGlassStyle light = LiquidGlassStyle();

  /// Dark appearance: a slightly smoky glass.
  static const LiquidGlassStyle dark = LiquidGlassStyle(
    tint: Color(0x33000000),
    brightness: 1.0,
    highlight: 0.42,
    shadowColor: Color(0x66000000),
    fallbackTint: Color(0x8C1C1C1E),
    borderColor: Color(0x33FFFFFF),
  );

  /// Colour mixed into the refracted backdrop; alpha = amount.
  final Color tint;

  /// Gaussian blur applied before refraction (sigma, logical px).
  final double blur;

  /// Maximum displacement at the rim (logical px).
  final double refraction;

  /// Width of the curved rim (logical px); clamped to the shape's radius.
  final double bevel;

  /// Chromatic dispersion at the rim (0 = none).
  final double dispersion;
  final double saturation;
  final double brightness;

  /// Strength of the specular rim highlight.
  final double highlight;
  final Offset lightDirection;

  final Color shadowColor;
  final double shadowBlur;
  final Offset shadowOffset;

  /// Used when shader filters are not supported (Skia).
  final Color fallbackTint;
  final double fallbackBlur;
  final Color borderColor;

  LiquidGlassStyle copyWith({
    Color? tint,
    double? blur,
    double? refraction,
    double? bevel,
    double? highlight,
    Color? shadowColor,
    double? shadowBlur,
    Offset? shadowOffset,
  }) {
    return LiquidGlassStyle(
      tint: tint ?? this.tint,
      blur: blur ?? this.blur,
      refraction: refraction ?? this.refraction,
      bevel: bevel ?? this.bevel,
      dispersion: dispersion,
      saturation: saturation,
      brightness: brightness,
      highlight: highlight ?? this.highlight,
      lightDirection: lightDirection,
      shadowColor: shadowColor ?? this.shadowColor,
      shadowBlur: shadowBlur ?? this.shadowBlur,
      shadowOffset: shadowOffset ?? this.shadowOffset,
      fallbackTint: fallbackTint,
      fallbackBlur: fallbackBlur,
      borderColor: borderColor,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LiquidGlassStyle &&
      other.tint == tint &&
      other.blur == blur &&
      other.refraction == refraction &&
      other.bevel == bevel &&
      other.dispersion == dispersion &&
      other.saturation == saturation &&
      other.brightness == brightness &&
      other.highlight == highlight &&
      other.lightDirection == lightDirection &&
      other.shadowColor == shadowColor &&
      other.shadowBlur == shadowBlur &&
      other.shadowOffset == shadowOffset &&
      other.fallbackTint == fallbackTint &&
      other.fallbackBlur == fallbackBlur &&
      other.borderColor == borderColor;

  @override
  int get hashCode => Object.hash(
        tint,
        blur,
        refraction,
        bevel,
        dispersion,
        saturation,
        brightness,
        highlight,
        lightDirection,
        shadowColor,
        shadowBlur,
        shadowOffset,
        fallbackTint,
        fallbackBlur,
        borderColor,
      );
}

/// A rounded-rectangle piece of liquid glass. Whatever is painted behind it
/// is refracted through its rim; [child] is drawn on top.
class LiquidGlass extends SingleChildRenderObjectWidget {
  const LiquidGlass({
    super.key,
    required this.borderRadius,
    this.style = LiquidGlassStyle.light,
    super.child,
  });

  final double borderRadius;
  final LiquidGlassStyle style;

  @override
  RenderLiquidGlass createRenderObject(BuildContext context) {
    return RenderLiquidGlass(
      borderRadius: borderRadius,
      style: style,
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderLiquidGlass renderObject) {
    renderObject
      ..borderRadius = borderRadius
      ..style = style
      ..devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
  }
}

class RenderLiquidGlass extends RenderProxyBox {
  RenderLiquidGlass({
    required double borderRadius,
    required LiquidGlassStyle style,
    required double devicePixelRatio,
  })  : _borderRadius = borderRadius,
        _style = style,
        _devicePixelRatio = devicePixelRatio;

  /// Test hook: paint only the child (used to composite previews).
  @visibleForTesting
  static bool debugPaintChildOnly = false;

  double _borderRadius;
  double get borderRadius => _borderRadius;
  set borderRadius(double value) {
    if (value == _borderRadius) {
      return;
    }
    _borderRadius = value;
    markNeedsPaint();
  }

  LiquidGlassStyle _style;
  LiquidGlassStyle get style => _style;
  set style(LiquidGlassStyle value) {
    if (value == _style) {
      return;
    }
    _style = value;
    markNeedsPaint();
  }

  double _devicePixelRatio;
  set devicePixelRatio(double value) {
    if (value == _devicePixelRatio) {
      return;
    }
    _devicePixelRatio = value;
    markNeedsPaint();
  }

  ui.FragmentShader? _shader;

  final _blurClip = LayerHandle<ClipRRectLayer>();
  final _blurLayer = LayerHandle<BackdropFilterLayer>();
  final _shaderClip = LayerHandle<ClipRectLayer>();
  final _shaderLayer = LayerHandle<BackdropFilterLayer>();

  Matrix4? _paintedTransform;
  bool _watching = false;

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _watchTransform();
  }

  @override
  void detach() {
    _watching = false;
    super.detach();
  }

  @override
  void dispose() {
    _blurClip.layer = null;
    _blurLayer.layer = null;
    _shaderClip.layer = null;
    _shaderLayer.layer = null;
    _shader?.dispose();
    _shader = null;
    super.dispose();
  }

  /// The shader samples the backdrop in screen space, so it has to be
  /// repainted whenever this box moves on screen, even if nothing marked it
  /// dirty (e.g. an ancestor scrolled or slid). Runs after frames that
  /// happen anyway; it never schedules frames by itself.
  void _watchTransform() {
    if (_watching) {
      return;
    }
    _watching = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _watching = false;
      if (!attached) {
        return;
      }
      if (_paintedTransform != null && hasSize) {
        final current = getTransformTo(null);
        if (current != _paintedTransform) {
          markNeedsPaint();
        }
      }
      _watchTransform();
    });
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!hasSize || size.isEmpty || debugPaintChildOnly) {
      super.paint(context, offset);
      return;
    }
    final rect = offset & size;
    final radius = math.min(_borderRadius, size.shortestSide / 2);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    _paintShadow(context.canvas, rrect);

    final useShader = LiquidGlassShader.isAvailable;
    final blurSigma = useShader ? _style.blur : _style.fallbackBlur;

    // 1. Frost the backdrop inside the shape.
    if (blurSigma > 0) {
      final blurLayer = _blurLayer.layer ??= BackdropFilterLayer();
      blurLayer.filter = ui.ImageFilter.blur(
        sigmaX: blurSigma,
        sigmaY: blurSigma,
        tileMode: TileMode.mirror,
      );
      _blurClip.layer = context.pushClipRRect(
        needsCompositing,
        Offset.zero,
        rect,
        rrect,
        (context, offset) => context.pushLayer(blurLayer, (_, __) {}, offset),
        oldLayer: _blurClip.layer,
      );
    } else {
      _blurClip.layer = null;
    }

    if (useShader) {
      // 2. Refract it through the rim.
      final shader = _shader ??= LiquidGlassShader.createShader();
      if (shader != null) {
        _configureShader(shader, radius);
        final shaderLayer = _shaderLayer.layer ??= BackdropFilterLayer();
        shaderLayer.filter = ui.ImageFilter.shader(shader);
        _shaderClip.layer = context.pushClipRect(
          needsCompositing,
          Offset.zero,
          rect.inflate(1),
          (context, offset) =>
              context.pushLayer(shaderLayer, (_, __) {}, offset),
          oldLayer: _shaderClip.layer,
        );
      }
    } else {
      _shaderClip.layer = null;
      _paintFallback(context.canvas, rrect);
    }

    _paintedTransform = getTransformTo(null);
    super.paint(context, offset);
  }

  void _configureShader(ui.FragmentShader shader, double radius) {
    final transform = getTransformTo(null);
    final global = MatrixUtils.transformRect(transform, Offset.zero & size);
    final scale = size.width > 0 ? global.width / size.width : 1.0;
    final dpr = _devicePixelRatio;
    final s = _style;
    final scaledRadius = radius * scale;
    final bevel = math.min(s.bevel, scaledRadius) * scale;
    final tint = s.tint;
    final light = s.lightDirection;

    var i = 2; // 0 and 1 (uSize) are set by the engine.
    void set(double v) => shader.setFloat(i++, v);
    // uRect
    set(global.left * dpr);
    set(global.top * dpr);
    set(global.width * dpr);
    set(global.height * dpr);
    // uRadius
    set(scaledRadius * dpr);
    // uTint
    set(tint.r);
    set(tint.g);
    set(tint.b);
    set(tint.a);
    // uParams
    set(s.refraction * scale * dpr);
    set(math.max(bevel * dpr, 1));
    set(s.dispersion);
    set(s.saturation);
    // uLight
    set(s.highlight);
    set(s.brightness);
    set(light.dx);
    set(light.dy);
  }

  void _paintShadow(Canvas canvas, RRect rrect) {
    final s = _style;
    if (s.shadowColor.a == 0 || s.shadowBlur <= 0) {
      return;
    }
    // Only outside the glass, otherwise it would show through.
    final outside = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rrect.outerRect.inflate(s.shadowBlur * 3))
      ..addRRect(rrect);
    canvas
      ..save()
      ..clipPath(outside)
      ..drawRRect(
        rrect.shift(s.shadowOffset),
        Paint()
          ..color = s.shadowColor
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s.shadowBlur / 2),
      )
      ..restore();
  }

  void _paintFallback(Canvas canvas, RRect rrect) {
    final s = _style;
    canvas.drawRRect(rrect, Paint()..color = s.fallbackTint);
    // Specular rim approximated with a gradient stroke.
    final rect = rrect.outerRect;
    canvas.drawRRect(
      rrect.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            s.borderColor,
            s.borderColor.withValues(alpha: s.borderColor.a * 0.15),
            s.borderColor.withValues(alpha: s.borderColor.a * 0.6),
          ],
          stops: const [0, 0.5, 1],
        ).createShader(rect),
    );
  }
}
