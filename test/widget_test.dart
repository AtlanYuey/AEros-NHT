import 'package:eros_n/component/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accent colors resolve for both brightnesses', () {
    for (final label in ThemeConfig.accentColors.keys) {
      expect(ThemeConfig.accentOf(label, Brightness.light), isNotNull);
      expect(ThemeConfig.accentOf(label, Brightness.dark), isNotNull);
    }
    // Unknown / legacy labels fall back to the default accent.
    expect(
      ThemeConfig.accentOf('deep_purple', Brightness.light),
      ThemeConfig.accentOf(
          ThemeConfig.defaultThemeColorLabel, Brightness.light),
    );
  });

  test('apple theme uses iOS system backgrounds', () {
    final light = ThemeConfig.build(
      accent: ThemeConfig.accentOf('blue', Brightness.light),
      brightness: Brightness.light,
    );
    final dark = ThemeConfig.build(
      accent: ThemeConfig.accentOf('blue', Brightness.dark),
      brightness: Brightness.dark,
    );
    expect(light.scaffoldBackgroundColor, ApplePalette.light.background);
    expect(dark.scaffoldBackgroundColor, ApplePalette.dark.background);
    expect(light.colorScheme.primary,
        ThemeConfig.accentOf('blue', Brightness.light));
    expect(
      light.pageTransitionsTheme.builders[TargetPlatform.android],
      isA<CupertinoPageTransitionsBuilder>(),
    );
  });
}
