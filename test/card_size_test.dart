import 'package:eros_n/common/const/const.dart';
import 'package:eros_n/common/provider/card_size_provider.dart';
import 'package:eros_n/pages/list_view/item/item_grid_card.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

SliverConstraints _constraints(double crossAxisExtent) => SliverConstraints(
      axisDirection: AxisDirection.down,
      growthDirection: GrowthDirection.forward,
      userScrollDirection: ScrollDirection.idle,
      scrollOffset: 0,
      precedingScrollExtent: 0,
      overlap: 0,
      remainingPaintExtent: 800,
      crossAxisExtent: crossAxisExtent,
      crossAxisDirection: AxisDirection.right,
      viewportMainAxisExtent: 800,
      remainingCacheExtent: 800,
      cacheOrigin: 0,
    );

void main() {
  // Pane widths minus the 16pt list padding on both sides: phones, phone
  // landscape, iPad split views, iPad full screen.
  const widths = [288.0, 329.0, 361.0, 398.0, 702.0, 788.0, 990.0, 1334.0];

  test('standard matches the original automatic column count', () {
    for (final width in widths) {
      final layout = const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: gridMaxCrossAxisExtent,
        crossAxisSpacing: gridCrossAxisSpacing,
      ).getLayout(_constraints(width)) as SliverGridRegularTileLayout;
      expect(
        CardSize.standard.columnsFor(
          crossAxisExtent: width,
          maxCrossAxisExtent: gridMaxCrossAxisExtent,
          crossAxisSpacing: gridCrossAxisSpacing,
        ),
        layout.crossAxisCount,
        reason: 'grid at $width',
      );
      expect(
        CardSize.standard.columnsFor(
          crossAxisExtent: width,
          maxCrossAxisExtent: NHConst.waterfallFlowLargeMaxCrossAxisExtent,
          crossAxisSpacing: NHConst.waterfallFlowLargeCrossAxisSpacing,
        ),
        (width /
                (NHConst.waterfallFlowLargeMaxCrossAxisExtent +
                    NHConst.waterfallFlowLargeCrossAxisSpacing))
            .ceil(),
        reason: 'waterfall at $width',
      );
    }
  });

  test('each step changes the column count until one column', () {
    for (final width in widths) {
      for (final extent in [
        gridMaxCrossAxisExtent,
        NHConst.waterfallFlowLargeMaxCrossAxisExtent,
      ]) {
        final counts = [
          for (final size in CardSize.values)
            size.columnsFor(
              crossAxisExtent: width,
              maxCrossAxisExtent: extent,
              crossAxisSpacing: 12,
            ),
        ];
        for (var i = 1; i < counts.length; i++) {
          expect(counts[i], greaterThanOrEqualTo(1));
          if (counts[i - 1] > 1) {
            expect(counts[i], lessThan(counts[i - 1]),
                reason: '$counts at $width / $extent');
          } else {
            expect(counts[i], 1);
          }
        }
      }
    }
  });

  test('names round-trip and unknown values fall back to standard', () {
    for (final size in CardSize.values) {
      expect(CardSize.fromName(size.name), size);
    }
    expect(CardSize.fromName(null), CardSize.standard);
    expect(CardSize.fromName(''), CardSize.standard);
    expect(CardSize.fromName('huge'), CardSize.standard);
  });
}
