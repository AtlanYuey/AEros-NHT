import 'dart:math' as math;

import 'package:eros_n/common/global.dart';
import 'package:eros_n/generated/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const String _cardSizeKey = 'card_size';

/// How large the gallery cards are in the grid and waterfall list styles.
///
/// The column count is always derived from the width of the pane the list
/// is laid out in (so rotating, switching screens or dragging a split view
/// divider adds or removes columns). [standard] keeps the original
/// automatic column count; the other steps scale the preferred card width
/// and are guaranteed to differ from their neighbours whenever possible.
enum CardSize {
  small(0.62),
  smaller(0.8),
  standard(1.0),
  larger(1.3),
  large(1.75);

  const CardSize(this.scale);

  /// Factor applied to the preferred (maximum) card width.
  final double scale;

  /// Steps away from [standard]; negative is smaller (more columns).
  int get offset => index - CardSize.standard.index;

  String label(BuildContext context) {
    final l10n = L10n.of(context);
    switch (this) {
      case CardSize.small:
        return l10n.card_size_small;
      case CardSize.smaller:
        return l10n.card_size_smaller;
      case CardSize.standard:
        return l10n.card_size_standard;
      case CardSize.larger:
        return l10n.card_size_larger;
      case CardSize.large:
        return l10n.card_size_large;
    }
  }

  static CardSize fromName(String? name) {
    for (final value in CardSize.values) {
      if (value.name == name) {
        return value;
      }
    }
    return CardSize.standard;
  }

  /// Number of columns for a pane [crossAxisExtent] wide, given the list
  /// style's preferred [maxCrossAxisExtent] and [crossAxisSpacing].
  int columnsFor({
    required double crossAxisExtent,
    required double maxCrossAxisExtent,
    required double crossAxisSpacing,
  }) {
    int count(double scale) => math.max(
          1,
          (crossAxisExtent / (maxCrossAxisExtent * scale + crossAxisSpacing))
              .ceil(),
        );

    // Same formula as SliverGridDelegateWithMaxCrossAxisExtent.
    final standardCount = count(1.0);
    if (this == CardSize.standard) {
      return standardCount;
    }

    // Walk outwards from the standard step so that every step changes the
    // column count by at least one (until a single column is reached).
    var columns = standardCount;
    final step = offset.sign;
    for (var i = CardSize.standard.index + step;
        step < 0 ? i >= index : i <= index;
        i += step) {
      final scaled = count(CardSize.values[i].scale);
      columns = step < 0
          ? math.max(scaled, columns + 1)
          : math.max(1, math.min(scaled, columns - 1));
    }
    return columns;
  }
}

class CardSizeNotifier extends StateNotifier<CardSize> {
  CardSizeNotifier() : super(_load());

  static CardSize _load() {
    try {
      return CardSize.fromName(hiveHelper.getString(_cardSizeKey));
    } catch (_) {
      // Storage is not available (tests).
      return CardSize.standard;
    }
  }

  void set(CardSize value) {
    if (value == state) {
      return;
    }
    state = value;
    try {
      hiveHelper.setString(_cardSizeKey, value.name);
    } catch (_) {}
  }
}

final cardSizeProvider = StateNotifierProvider<CardSizeNotifier, CardSize>(
  (ref) => CardSizeNotifier(),
);
