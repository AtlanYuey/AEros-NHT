import 'dart:math' as math;

import 'package:eros_n/common/const/const.dart';
import 'package:eros_n/common/enum.dart';
import 'package:eros_n/common/provider/card_size_provider.dart';
import 'package:eros_n/common/provider/settings_provider.dart';
import 'package:eros_n/component/theme/theme.dart';
import 'package:eros_n/component/widget/apple.dart';
import 'package:eros_n/generated/l10n.dart';
import 'package:eros_n/pages/list_view/item/item_grid_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// "Card Size": how many cards fit across in the grid / waterfall styles,
/// set separately for portrait and landscape.
class CardSizeSettingPage extends HookConsumerWidget {
  const CardSizeSettingPage({super.key, this.previousPageTitle});

  final String? previousPageTitle;

  static Route<void> route({String? previousPageTitle}) {
    return CupertinoPageRoute<void>(
      builder: (_) => CardSizeSettingPage(previousPageTitle: previousPageTitle),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final sizes = ref.watch(cardSizeProvider);
    final listModel = ref.watch(settingsProvider.select((s) => s.listModel));
    final isGrid = listModel == ListModel.grid;
    final notifier = ref.read(cardSizeProvider.notifier);

    final footer = StringBuffer(l10n.card_size_footer);
    if (listModel == ListModel.list) {
      footer
        ..write('\n')
        ..write(l10n.card_size_list_hint);
    }

    Widget section(Orientation orientation, String header, {String? footer}) {
      return AppleSection(
        header: header,
        footer: footer,
        children: [
          _CardSizeSlider(
            value: sizes.of(orientation),
            onChanged: (value) => notifier.set(orientation, value),
          ),
          _OrientationPreview(
            orientation: orientation,
            cardSize: sizes.of(orientation),
            isGrid: isGrid,
          ),
        ],
      );
    }

    return AppleGroupedPage(
      title: l10n.card_size,
      previousPageTitle: previousPageTitle,
      children: [
        section(Orientation.portrait, l10n.card_size_portrait),
        section(
          Orientation.landscape,
          l10n.card_size_landscape,
          footer: footer.toString(),
        ),
      ],
    );
  }
}

class _CardSizeSlider extends StatelessWidget {
  const _CardSizeSlider({required this.value, required this.onChanged});

  final CardSize value;
  final ValueChanged<CardSize> onChanged;

  /// Distance from the slider's edge to the centre of the thumb at either
  /// end (half of the 37pt iOS 26 thumb).
  static const double _thumbInset = 18.5;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final last = CardSize.values.length - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Centred on the slider track (the slider is 44 tall).
          Padding(
            padding: const EdgeInsets.only(top: 22 - 17 / 2),
            child: Icon(
              CupertinoIcons.square_grid_4x3_fill,
              size: 17,
              color: palette.secondaryLabel,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppleSlider(
                  value: value.index.toDouble(),
                  max: last.toDouble(),
                  divisions: last,
                  activeColor: accent,
                  onChanged: (v) {
                    final next = CardSize.values[v.round().clamp(0, last)];
                    if (next != value) {
                      onChanged(next);
                    }
                  },
                ),
                LayoutBuilder(builder: (context, constraints) {
                  final track = constraints.maxWidth - _thumbInset * 2;
                  return SizedBox(
                    height: 20,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (final size in CardSize.values)
                          Positioned(
                            left: _thumbInset + track * size.index / last - 30,
                            width: 60,
                            top: 0,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                if (size != value) {
                                  HapticFeedback.selectionClick();
                                  onChanged(size);
                                }
                              },
                              child: Text(
                                size.label(context),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.visible,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: size == value
                                      ? accent
                                      : palette.secondaryLabel,
                                  fontWeight: size == value
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(top: 22 - 24 / 2),
            child: Icon(
              CupertinoIcons.square_grid_2x2_fill,
              size: 24,
              color: palette.secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }
}

/// A miniature screen in one orientation showing the resulting columns.
class _OrientationPreview extends StatelessWidget {
  const _OrientationPreview({
    required this.orientation,
    required this.cardSize,
    required this.isGrid,
  });

  final Orientation orientation;
  final CardSize cardSize;
  final bool isGrid;

  /// Horizontal padding of the gallery lists.
  static const double _listPadding = 16;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final mq = MediaQuery.of(context);
    final palette = context.palette;
    final theme = Theme.of(context);

    final isPortraitNow = mq.size.height >= mq.size.width;
    final shortSide = math.min(mq.size.width, mq.size.height);
    final longSide = math.max(mq.size.width, mq.size.height);
    final portrait = orientation == Orientation.portrait;

    // Side insets in the previewed orientation: on notched phones the
    // status bar inset moves to both sides in landscape.
    final double insets;
    if (portrait) {
      insets = isPortraitNow ? mq.padding.left + mq.padding.right : 0;
    } else {
      insets = isPortraitNow
          ? (mq.padding.top > 30 ? mq.padding.top * 2 : 0)
          : mq.padding.left + mq.padding.right;
    }
    final deviceWidth = (portrait ? shortSide : longSide) - insets;
    final deviceHeight = portrait ? longSide : shortSide;

    final columns = cardSize.columnsFor(
      crossAxisExtent: deviceWidth - _listPadding * 2,
      maxCrossAxisExtent: isGrid
          ? gridMaxCrossAxisExtent
          : NHConst.waterfallFlowLargeMaxCrossAxisExtent,
      crossAxisSpacing: isGrid
          ? gridCrossAxisSpacing
          : NHConst.waterfallFlowLargeCrossAxisSpacing,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      child: LayoutBuilder(builder: (context, constraints) {
        final aspect = deviceWidth / deviceHeight;
        final height = portrait
            ? 170.0
            : math.min(150.0, constraints.maxWidth * 0.62 / aspect);
        final width = height * aspect;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: width,
              height: height,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: columns.toDouble()),
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                builder: (context, animatedColumns, _) => CustomPaint(
                  painter: _MiniScreenPainter(
                    columns: animatedColumns,
                    scale: width / deviceWidth,
                    isGrid: isGrid,
                    screen: palette.background,
                    frame: palette.separator,
                    card: theme.colorScheme.primary,
                    text: palette.tertiaryLabel,
                    dark: palette.brightness == Brightness.dark,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$columns',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: palette.label,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  l10n.card_size_columns,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: palette.secondaryLabel),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}

class _MiniScreenPainter extends CustomPainter {
  _MiniScreenPainter({
    required this.columns,
    required this.scale,
    required this.isGrid,
    required this.screen,
    required this.frame,
    required this.card,
    required this.text,
    required this.dark,
  });

  final bool dark;

  /// May be fractional while animating between two counts.
  final double columns;
  final double scale;
  final bool isGrid;
  final Color screen;
  final Color frame;
  final Color card;
  final Color text;

  static const List<double> _waterfallRatios = [
    1.42, 1.18, 1.55, 1.3, 1.08, 1.48, 1.25, 1.6, 1.12, 1.38, 1.5, 1.2,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(math.min(size.width, size.height) * 0.09);
    final outer = RRect.fromRectAndRadius(Offset.zero & size, radius);
    canvas.drawRRect(outer, Paint()..color = screen);
    canvas.save();
    canvas.clipRRect(outer);

    final pad = 16 * scale;
    final gap = math.max(1.5, 12 * scale);
    final top = size.height * 0.1;

    // Large title placeholder.
    final titlePaint = Paint()..color = text;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(pad, top * 0.45, size.width * 0.28, top * 0.32),
        Radius.circular(top * 0.16),
      ),
      titlePaint,
    );

    final count = math.max(1.0, columns);
    final cardWidth = (size.width - pad * 2 - gap * (count - 1)) / count;
    final whole = count.ceil();
    final cardPaint = Paint();
    final cardRadius = Radius.circular(math.max(1.5, cardWidth * 0.08));
    final lineHeight = math.max(1.5, cardWidth * 0.07);

    for (var c = 0; c < whole; c++) {
      final x = pad + c * (cardWidth + gap);
      var y = top + gap;
      var i = c;
      while (y < size.height) {
        final ratio = isGrid ? 4 / 3 : _waterfallRatios[i % 12];
        final coverHeight = cardWidth * ratio;
        final shade = ((i * 7 + c * 3) % 4) / 3;
        cardPaint.color = card.withValues(
          alpha: dark ? 0.34 + 0.22 * shade : 0.18 + 0.14 * shade,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, cardWidth, coverHeight),
            cardRadius,
          ),
          cardPaint,
        );
        var bottom = y + coverHeight;
        if (cardWidth > 10) {
          final lineY = bottom + lineHeight;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x, lineY, cardWidth * 0.85, lineHeight),
              Radius.circular(lineHeight / 2),
            ),
            titlePaint,
          );
          bottom = lineY + lineHeight * 1.5;
        }
        y = bottom + gap;
        i += whole;
      }
    }
    canvas.restore();
    canvas.drawRRect(
      outer.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = frame,
    );
  }

  @override
  bool shouldRepaint(_MiniScreenPainter old) {
    return old.columns != columns ||
        old.scale != scale ||
        old.isGrid != isGrid ||
        old.screen != screen ||
        old.frame != frame ||
        old.card != card ||
        old.text != text ||
        old.dark != dark;
  }
}
