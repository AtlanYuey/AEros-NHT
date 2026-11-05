import 'dart:math' as math;

import 'package:eros_n/common/global.dart';
import 'package:eros_n/generated/l10n.dart';
import 'package:flutter/foundation.dart';
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

/// Card size per screen orientation (set separately, like the column
/// count of a photo grid in portrait and landscape).
@immutable
class CardSizes {
  const CardSizes({
    this.portrait = CardSize.standard,
    this.landscape = CardSize.standard,
  });

  final CardSize portrait;
  final CardSize landscape;

  CardSize of(Orientation orientation) =>
      orientation == Orientation.portrait ? portrait : landscape;

  CardSizes copyWith(Orientation orientation, CardSize value) =>
      orientation == Orientation.portrait
          ? CardSizes(portrait: value, landscape: landscape)
          : CardSizes(portrait: portrait, landscape: value);

  /// Short summary for a settings row, e.g. "Standard" or "Smaller / Large".
  String label(BuildContext context) => portrait == landscape
      ? portrait.label(context)
      : '${portrait.label(context)} / ${landscape.label(context)}';

  @override
  bool operator ==(Object other) =>
      other is CardSizes &&
      other.portrait == portrait &&
      other.landscape == landscape;

  @override
  int get hashCode => Object.hash(portrait, landscape);
}

class CardSizeNotifier extends StateNotifier<CardSizes> {
  CardSizeNotifier() : super(_load());

  static const _keys = {
    Orientation.portrait: _cardSizeKey,
    Orientation.landscape: '${_cardSizeKey}_landscape',
  };

  static CardSizes _load() {
    try {
      return CardSizes(
        portrait: CardSize.fromName(
            hiveHelper.getString(_keys[Orientation.portrait]!)),
        landscape: CardSize.fromName(
            hiveHelper.getString(_keys[Orientation.landscape]!)),
      );
    } catch (_) {
      // Storage is not available (tests).
      return const CardSizes();
    }
  }

  void set(Orientation orientation, CardSize value) {
    if (state.of(orientation) == value) {
      return;
    }
    state = state.copyWith(orientation, value);
    try {
      hiveHelper.setString(_keys[orientation]!, value.name);
    } catch (_) {}
  }
}

final cardSizeProvider = StateNotifierProvider<CardSizeNotifier, CardSizes>(
  (ref) => CardSizeNotifier(),
);
