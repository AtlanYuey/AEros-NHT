import 'dart:ui' as ui;

import 'package:eros_n/utils/logger.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Loads the progressive blur shader used by [ScrollEdgeEffect].
class VariableBlurShader {
  VariableBlurShader._();

  static const String assetKey = 'shaders/variable_blur.frag';

  static ui.FragmentProgram? _program;

  /// Load the shader once at start-up. Safe to call more than once.
  static Future<void> load() async {
    if (_program != null) {
      return;
    }
    try {
      _program = await ui.FragmentProgram.fromAsset(assetKey);
    } catch (e, stack) {
      logger.e('Variable blur shader unavailable: $e\n$stack');
    }
  }

  /// Whether the smooth (shader) variant can be rendered (Impeller).
  static bool get isAvailable =>
      _program != null && ui.ImageFilter.isShaderFilterSupported;

  static ui.FragmentShader? createShader() => _program?.fragmentShader();
}

/// iOS 26 "soft" scroll edge effect.
///
/// Content scrolling under a bar is blurred and washed into the page colour
/// progressively: strongest at the screen edge and fading out smoothly past
/// the bar, so there is no hard edge between the bar and the content
/// (unlike the opaque, hairline-bordered bars of earlier iOS versions).
///
/// On Impeller the blur radius varies continuously along the edge (a
/// separable Gaussian in a fragment shader, see `shaders/variable_blur.frag`).
/// Elsewhere it is approximated with thin backdrop-blur bands. A colour
/// gradient on top washes the content into the page colour.
class ScrollEdgeEffect extends StatelessWidget {
  const ScrollEdgeEffect({
    super.key,
    required this.color,
    this.visibility = 1.0,
    this.maxBlur = 10.0,
    this.maxOpacity = 0.82,
    this.edge = AxisDirection.up,
  });

  /// Page colour the content fades into.
  final Color color;

  /// 0 hides the effect (nothing under the bar yet), 1 shows it fully.
  final double visibility;

  /// Blur sigma at the very edge (logical pixels).
  final double maxBlur;

  /// Opacity of [color] at the very edge.
  final double maxOpacity;

  /// Which screen edge the effect is attached to: [AxisDirection.up] for
  /// a top bar, [AxisDirection.down] for a bottom toolbar.
  final AxisDirection edge;

  static double _smoothstep(double edge0, double edge1, double x) {
    final t = ((x - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  /// Blur strength at [t] (0 = screen edge, 1 = where the effect ends).
  /// Must match `falloff` in the shader.
  static double blurAt(double t) => 1 - _smoothstep(0.15, 1.0, t);

  /// Tint strength at [t].
  static double tintAt(double t) => 1 - _smoothstep(0.3, 1.0, t);

  @override
  Widget build(BuildContext context) {
    final v = visibility.clamp(0.0, 1.0);
    if (v <= 0.001) {
      return const SizedBox.expand();
    }
    final fromTop = edge == AxisDirection.up;

    const steps = 12;
    final colors = <Color>[];
    final stops = <double>[];
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      stops.add(t);
      colors.add(color.withValues(alpha: maxOpacity * v * tintAt(t)));
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        if (VariableBlurShader.isAvailable)
          _VariableBlur(
            maxSigma: maxBlur * v,
            fromTop: fromTop,
            devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
          )
        else
          _BandedBlur(maxSigma: maxBlur * v, fromTop: fromTop),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: fromTop ? Alignment.topCenter : Alignment.bottomCenter,
              end: fromTop ? Alignment.bottomCenter : Alignment.topCenter,
              colors: colors,
              stops: stops,
            ),
          ),
        ),
      ],
    );
  }
}

/// Fallback without shader filters: abutting backdrop-blur bands whose
/// radius falls off along the edge, sharing one backdrop snapshot.
class _BandedBlur extends StatelessWidget {
  const _BandedBlur({required this.maxSigma, required this.fromTop});

  final double maxSigma;
  final bool fromTop;

  static const int _bands = 14;

  @override
  Widget build(BuildContext context) {
    if (maxSigma <= 0.2) {
      return const SizedBox.expand();
    }
    return LayoutBuilder(builder: (context, constraints) {
      final band = constraints.maxHeight / _bands;
      final children = <Widget>[];
      for (var i = 0; i < _bands; i++) {
        final sigma = maxSigma * ScrollEdgeEffect.blurAt((i + 0.5) / _bands);
        if (sigma < 0.15) {
          break;
        }
        // Overlap the next band by a pixel so rounding never leaves an
        // unblurred seam.
        children.add(Positioned(
          left: 0,
          right: 0,
          top: fromTop ? i * band : null,
          bottom: fromTop ? null : i * band,
          height: band + (i == _bands - 1 ? 0 : 1),
          child: ClipRect(
            child: BackdropFilter.grouped(
              filter: ui.ImageFilter.blur(
                sigmaX: sigma,
                sigmaY: sigma,
                tileMode: TileMode.mirror,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ));
      }
      return BackdropGroup(child: Stack(children: children));
    });
  }
}

class _VariableBlur extends LeafRenderObjectWidget {
  const _VariableBlur({
    required this.maxSigma,
    required this.fromTop,
    required this.devicePixelRatio,
  });

  final double maxSigma;
  final bool fromTop;
  final double devicePixelRatio;

  @override
  _RenderVariableBlur createRenderObject(BuildContext context) {
    return _RenderVariableBlur(
      maxSigma: maxSigma,
      fromTop: fromTop,
      devicePixelRatio: devicePixelRatio,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderVariableBlur renderObject,
  ) {
    renderObject
      ..maxSigma = maxSigma
      ..fromTop = fromTop
      ..devicePixelRatio = devicePixelRatio;
  }
}

/// Two backdrop layers (horizontal, then vertical pass) running the
/// variable blur shader over this box's area.
class _RenderVariableBlur extends RenderBox {
  _RenderVariableBlur({
    required double maxSigma,
    required bool fromTop,
    required double devicePixelRatio,
  })  : _maxSigma = maxSigma,
        _fromTop = fromTop,
        _devicePixelRatio = devicePixelRatio;

  double _maxSigma;
  set maxSigma(double value) {
    if (value != _maxSigma) {
      _maxSigma = value;
      markNeedsPaint();
    }
  }

  bool _fromTop;
  set fromTop(bool value) {
    if (value != _fromTop) {
      _fromTop = value;
      markNeedsPaint();
    }
  }

  double _devicePixelRatio;
  set devicePixelRatio(double value) {
    if (value != _devicePixelRatio) {
      _devicePixelRatio = value;
      markNeedsPaint();
    }
  }

  ui.FragmentShader? _horizontal;
  ui.FragmentShader? _vertical;
  final _clip = LayerHandle<ClipRectLayer>();
  final _horizontalLayer = LayerHandle<BackdropFilterLayer>();
  final _verticalLayer = LayerHandle<BackdropFilterLayer>();

  Matrix4? _paintedTransform;
  bool _watching = false;

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  bool hitTestSelf(Offset position) => false;

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
    _clip.layer = null;
    _horizontalLayer.layer = null;
    _verticalLayer.layer = null;
    _horizontal?.dispose();
    _vertical?.dispose();
    _horizontal = null;
    _vertical = null;
    super.dispose();
  }

  /// The shader works in screen space, so the box has to be repainted
  /// whenever it moves on screen even if nothing marked it dirty (e.g. a
  /// page transition). Runs after frames that happen anyway; it never
  /// schedules frames by itself.
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
        if (getTransformTo(null) != _paintedTransform) {
          markNeedsPaint();
        }
      }
      _watchTransform();
    });
  }

  void _configure(ui.FragmentShader shader, Rect global, bool horizontal) {
    final dpr = _devicePixelRatio;
    final scale = size.height > 0 ? global.height / size.height : 1.0;
    var i = 2; // 0 and 1 (uSize) are set by the engine.
    void set(double v) => shader.setFloat(i++, v);
    // uEdge
    set((_fromTop ? global.top : global.bottom) * dpr);
    set(global.height * dpr);
    set(_maxSigma * scale * dpr);
    set(_fromTop ? 1 : -1);
    // uDir
    set(horizontal ? 1 : 0);
    set(horizontal ? 0 : 1);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _paintedTransform = getTransformTo(null);
    if (size.isEmpty || _maxSigma <= 0.05) {
      _clip.layer = null;
      return;
    }
    final horizontal = _horizontal ??= VariableBlurShader.createShader();
    final vertical = _vertical ??= VariableBlurShader.createShader();
    if (horizontal == null || vertical == null) {
      _clip.layer = null;
      return;
    }
    final global =
        MatrixUtils.transformRect(_paintedTransform!, Offset.zero & size);
    _configure(horizontal, global, true);
    _configure(vertical, global, false);

    final hLayer = _horizontalLayer.layer ??= BackdropFilterLayer();
    final vLayer = _verticalLayer.layer ??= BackdropFilterLayer();
    hLayer.filter = ui.ImageFilter.shader(horizontal);
    vLayer.filter = ui.ImageFilter.shader(vertical);

    // The second pass reads the first one's output, so the two layers must
    // not share a backdrop snapshot.
    _clip.layer = context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      (context, offset) {
        context.pushLayer(hLayer, (_, __) {}, offset);
        context.pushLayer(vLayer, (_, __) {}, offset);
      },
      oldLayer: _clip.layer,
    );
  }
}
