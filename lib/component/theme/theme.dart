import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Apple Human Interface Guidelines inspired theme.
///
/// Colors follow the iOS system palette (systemBackground, label,
/// separator, fills ...), typography follows the iOS Dynamic Type scale
/// and components are tuned to look and feel like native UIKit controls.
class ThemeConfig {
  static late ColorScheme lightColorScheme;
  static late ColorScheme darkColorScheme;

  static late ThemeData lightTheme;
  static late ThemeData darkTheme;

  static const defaultThemeColorLabel = 'blue';
  static const dynamicThemeColorLabel = 'dynamic';

  /// iOS system tint colors. Each entry resolves to a different shade in
  /// light and dark mode, exactly like UIKit's dynamic system colors.
  static const Map<String, CupertinoDynamicColor> accentColors = {
    'blue': CupertinoColors.systemBlue,
    'indigo': CupertinoColors.systemIndigo,
    'purple': CupertinoColors.systemPurple,
    'pink': CupertinoColors.systemPink,
    'red': CupertinoColors.systemRed,
    'orange': CupertinoColors.systemOrange,
    'yellow': CupertinoColors.systemYellow,
    'green': CupertinoColors.systemGreen,
    'mint': CupertinoColors.systemMint,
    'teal': CupertinoColors.systemTeal,
    'cyan': CupertinoColors.systemCyan,
    'brown': CupertinoColors.systemBrown,
    'grey': CupertinoColors.systemGrey,
  };

  /// Light-mode representation of every accent, kept for compatibility
  /// with code that only needs a single color per label.
  static final Map<String, Color?> colorMap = {
    for (final e in accentColors.entries) e.key: e.value.color,
  };

  static Color accentOf(String label, Brightness brightness) {
    final dynamicColor =
        accentColors[label] ?? accentColors[defaultThemeColorLabel]!;
    return brightness == Brightness.dark
        ? dynamicColor.darkColor
        : dynamicColor.color;
  }

  /// Build a complete [ThemeData] for the given accent and brightness.
  static ThemeData build({
    required Color accent,
    required Brightness brightness,
  }) {
    final colorScheme = buildColorScheme(accent, brightness);
    return buildTheme(colorScheme);
  }

  static ColorScheme buildColorScheme(Color accent, Brightness brightness) {
    final p = ApplePalette.of(brightness);
    final base = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    );
    final onAccent =
        ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
            ? Colors.white
            : Colors.black;
    final accentContainer = Color.alphaBlend(
      accent.withValues(alpha: brightness == Brightness.dark ? 0.26 : 0.14),
      p.background,
    );

    return base.copyWith(
      primary: accent,
      onPrimary: onAccent,
      primaryContainer: accentContainer,
      onPrimaryContainer: accent,
      secondary: accent,
      onSecondary: onAccent,
      secondaryContainer: accentContainer,
      onSecondaryContainer: accent,
      tertiary: brightness == Brightness.dark
          ? CupertinoColors.systemPink.darkColor
          : CupertinoColors.systemPink.color,
      error: brightness == Brightness.dark
          ? CupertinoColors.systemRed.darkColor
          : CupertinoColors.systemRed.color,
      onError: Colors.white,
      surface: p.background,
      onSurface: p.label,
      onSurfaceVariant: p.secondaryLabel,
      surfaceDim: p.groupedBackground,
      surfaceBright: p.background,
      surfaceContainerLowest: p.background,
      surfaceContainerLow: p.secondaryBackground,
      surfaceContainer: p.secondaryBackground,
      surfaceContainerHigh: p.tertiaryBackground,
      surfaceContainerHighest: p.quaternaryFill,
      outline: p.opaqueSeparator,
      outlineVariant: p.separator,
      surfaceTint: Colors.transparent,
      shadow: Colors.black,
      scrim: Colors.black,
    );
  }

  static TextTheme appleTextTheme(Color label, Color secondaryLabel) {
    // iOS Dynamic Type (Large) sizes & tracking.
    return TextTheme(
      displayLarge: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: label),
      displayMedium: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: label),
      displaySmall: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.37,
          color: label),
      // Large Title
      headlineLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.37,
          color: label),
      // Title 1
      headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.36,
          color: label),
      // Title 2
      headlineSmall: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.35,
          color: label),
      // Title 3
      titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.38,
          color: label),
      // Headline
      titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.41,
          color: label),
      // Subheadline (emphasized)
      titleSmall: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.24,
          color: label),
      // Body
      bodyLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.41,
          color: label),
      // Subheadline
      bodyMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.24,
          color: label),
      // Footnote
      bodySmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.08,
          color: secondaryLabel),
      // Button
      labelLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.41,
          color: label),
      // Caption 1
      labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
          color: secondaryLabel),
      // Caption 2
      labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.07,
          color: secondaryLabel),
    );
  }

  static ThemeData buildTheme(ColorScheme colorScheme) {
    final brightness = colorScheme.brightness;
    final p = ApplePalette.of(brightness);
    final accent = colorScheme.primary;
    final isDark = brightness == Brightness.dark;

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
    );

    final textTheme =
        base.textTheme.merge(appleTextTheme(p.label, p.secondaryLabel));

    const continuous14 = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
    );
    const continuous12 = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    );

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: base.primaryTextTheme
          .merge(appleTextTheme(colorScheme.onPrimary, colorScheme.onPrimary)),
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      cardColor: p.secondaryBackground,
      dividerColor: p.separator,
      // iOS has no ink ripples, only a subtle highlight on press.
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: p.label.withValues(alpha: isDark ? 0.10 : 0.06),
      hoverColor: p.label.withValues(alpha: 0.04),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
          TargetPlatform.fuchsia: CupertinoPageTransitionsBuilder(),
        },
      ),
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: accent,
        primaryContrastingColor: colorScheme.onPrimary,
        barBackgroundColor: p.bar,
        scaffoldBackgroundColor: p.background,
        applyThemeToAll: true,
        textTheme: CupertinoTextThemeData(primaryColor: accent),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.bar,
        foregroundColor: p.label,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: accent),
        actionsIconTheme: IconThemeData(color: accent),
        titleTextStyle: textTheme.titleMedium,
        shape: Border(
          bottom: BorderSide(color: p.separator, width: 0.0),
        ),
      ),
      cardTheme: CardThemeData(
        color: p.secondaryBackground,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        shape: continuous14,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: accent,
        textColor: p.label,
        titleTextStyle: textTheme.bodyLarge,
        subtitleTextStyle: textTheme.bodySmall,
        leadingAndTrailingTextStyle: textTheme.bodyLarge?.copyWith(
          color: p.secondaryLabel,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        minVerticalPadding: 11,
      ),
      dividerTheme: DividerThemeData(
        color: p.separator,
        thickness: 0.5,
        space: 0.5,
      ),
      iconTheme: IconThemeData(color: accent),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: accent,
          highlightColor: Colors.transparent,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: textTheme.bodyLarge,
          shape: continuous12,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size(64, 50),
          textStyle: textTheme.labelLarge,
          shape: continuous14,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: BorderSide(color: p.opaqueSeparator, width: 0.5),
          shape: continuous12,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.tertiaryFill,
          foregroundColor: accent,
          elevation: 0,
          shape: continuous12,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: colorScheme.onPrimary,
        elevation: 6,
        focusElevation: 6,
        hoverElevation: 8,
        highlightElevation: 2,
        shape: const StadiumBorder(),
        extendedTextStyle: textTheme.labelLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.tertiaryFill,
        hintStyle: textTheme.bodyLarge?.copyWith(color: p.placeholder),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide.none,
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide.none,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.menu,
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        shape: continuous14,
        textStyle: textTheme.bodyLarge,
        labelTextStyle: WidgetStatePropertyAll(textTheme.bodyLarge),
        menuPadding: const EdgeInsets.symmetric(vertical: 4),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.menu,
        surfaceTintColor: Colors.transparent,
        shape: continuous14,
        titleTextStyle: textTheme.titleMedium,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.groupedBackground,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: p.groupedBackground,
        showDragHandle: true,
        dragHandleColor: p.opaqueSeparator,
        shape: const RoundedSuperellipseBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isDark ? const Color(0xFF2C2C2E) : const Color(0xFF1C1C1E),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: continuous14,
        elevation: 4,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.tertiaryFill,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: textTheme.bodyMedium,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: p.tertiaryFill,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: p.quaternaryFill,
        thumbColor: Colors.white,
        overlayColor: Colors.transparent,
        trackHeight: 4,
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark
                ? CupertinoColors.systemGreen.darkColor
                : CupertinoColors.systemGreen.color;
          }
          return p.quaternaryFill;
        }),
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: const WidgetStatePropertyAll(3),
        radius: const Radius.circular(3),
        thumbColor:
            WidgetStatePropertyAll(p.secondaryLabel.withValues(alpha: 0.5)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: p.menu,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: p.label),
      ),
    );
  }
}

/// iOS semantic system colors resolved for a brightness.
class ApplePalette {
  const ApplePalette._({
    required this.brightness,
    required this.background,
    required this.secondaryBackground,
    required this.tertiaryBackground,
    required this.groupedBackground,
    required this.secondaryGroupedBackground,
    required this.label,
    required this.secondaryLabel,
    required this.tertiaryLabel,
    required this.placeholder,
    required this.separator,
    required this.opaqueSeparator,
    required this.systemFill,
    required this.secondaryFill,
    required this.tertiaryFill,
    required this.quaternaryFill,
    required this.bar,
    required this.menu,
    required this.glass,
    required this.glassBorder,
  });

  static const light = ApplePalette._(
    brightness: Brightness.light,
    background: Color(0xFFFFFFFF),
    secondaryBackground: Color(0xFFF2F2F7),
    tertiaryBackground: Color(0xFFFFFFFF),
    groupedBackground: Color(0xFFF2F2F7),
    secondaryGroupedBackground: Color(0xFFFFFFFF),
    label: Color(0xFF000000),
    secondaryLabel: Color(0xFF8A8A8E),
    tertiaryLabel: Color(0xFFC4C4C6),
    placeholder: Color(0xFFA2A2A7),
    separator: Color(0xFFD8D8DC),
    opaqueSeparator: Color(0xFFC6C6C8),
    systemFill: Color(0xFFE3E3E8),
    secondaryFill: Color(0xFFE9E9EE),
    tertiaryFill: Color(0xFFEEEEF0),
    quaternaryFill: Color(0xFFE5E5EA),
    bar: Color(0xEBF9F9F9),
    menu: Color(0xFFF7F7F8),
    glass: Color(0xB8FFFFFF),
    glassBorder: Color(0x99FFFFFF),
  );

  static const dark = ApplePalette._(
    brightness: Brightness.dark,
    background: Color(0xFF000000),
    secondaryBackground: Color(0xFF1C1C1E),
    tertiaryBackground: Color(0xFF2C2C2E),
    groupedBackground: Color(0xFF000000),
    secondaryGroupedBackground: Color(0xFF1C1C1E),
    label: Color(0xFFFFFFFF),
    secondaryLabel: Color(0xFF98989F),
    tertiaryLabel: Color(0xFF5A5A5F),
    placeholder: Color(0xFF6C6C70),
    separator: Color(0xFF38383A),
    opaqueSeparator: Color(0xFF38383A),
    systemFill: Color(0xFF3A3A3C),
    secondaryFill: Color(0xFF323234),
    tertiaryFill: Color(0xFF1C1C1E),
    quaternaryFill: Color(0xFF39393D),
    bar: Color(0xE61C1C1E),
    menu: Color(0xFF252527),
    glass: Color(0xB82C2C2E),
    glassBorder: Color(0x26FFFFFF),
  );

  static ApplePalette of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  static ApplePalette ofContext(BuildContext context) =>
      of(Theme.of(context).brightness);

  final Brightness brightness;
  final Color background;
  final Color secondaryBackground;
  final Color tertiaryBackground;
  final Color groupedBackground;
  final Color secondaryGroupedBackground;
  final Color label;
  final Color secondaryLabel;
  final Color tertiaryLabel;
  final Color placeholder;
  final Color separator;
  final Color opaqueSeparator;
  final Color systemFill;
  final Color secondaryFill;
  final Color tertiaryFill;
  final Color quaternaryFill;

  /// Translucent navigation / toolbar chrome (used with a blur).
  final Color bar;

  /// Popup menu / alert surface.
  final Color menu;

  /// "Liquid glass" floating controls fill (used with a blur).
  final Color glass;
  final Color glassBorder;
}

extension AppleThemeContext on BuildContext {
  ApplePalette get palette => ApplePalette.ofContext(this);
}
