package com.atlanyuey.nhentai.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.text.selection.LocalTextSelectionColors
import androidx.compose.foundation.text.selection.TextSelectionColors
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.em
import androidx.compose.ui.unit.sp
import com.atlanyuey.nhentai.R
import com.atlanyuey.nhentai.core.AccentChoice
import com.atlanyuey.nhentai.core.AppSettings
import com.atlanyuey.nhentai.core.ThemeMode

/** iOS system colors (UIColor semantic colors), light and dark. */
@Immutable
data class AppColors(
    val background: Color,
    val secondaryBackground: Color,
    val tertiaryBackground: Color,
    val groupedBackground: Color,
    val secondaryGroupedBackground: Color,
    val tertiaryGroupedBackground: Color,
    val label: Color,
    val secondaryLabel: Color,
    val tertiaryLabel: Color,
    val quaternaryLabel: Color,
    val separator: Color,
    val opaqueSeparator: Color,
    val fill: Color,
    val secondaryFill: Color,
    val tertiaryFill: Color,
    val quaternaryFill: Color,
    val gray: Color,
    val red: Color,
    val green: Color,
    val orange: Color,
    val pink: Color,
    /** Surface tint of Liquid Glass (on top of the blurred backdrop). */
    val glassSurface: Color,
    val isDark: Boolean,
)

val LightColors = AppColors(
    background = Color.White,
    secondaryBackground = Color(0xFFF2F2F7),
    tertiaryBackground = Color.White,
    groupedBackground = Color(0xFFF2F2F7),
    secondaryGroupedBackground = Color.White,
    tertiaryGroupedBackground = Color(0xFFF2F2F7),
    label = Color.Black,
    secondaryLabel = Color(0x993C3C43),
    tertiaryLabel = Color(0x4D3C3C43),
    quaternaryLabel = Color(0x2E3C3C43),
    separator = Color(0x4A3C3C43),
    opaqueSeparator = Color(0xFFC6C6C8),
    fill = Color(0x33787880),
    secondaryFill = Color(0x29787880),
    tertiaryFill = Color(0x1F767680),
    quaternaryFill = Color(0x14747480),
    gray = Color(0xFF8E8E93),
    red = Color(0xFFFF3B30),
    green = Color(0xFF34C759),
    orange = Color(0xFFFF9500),
    pink = Color(0xFFFF2D55),
    glassSurface = Color(0xFFFAFAFA).copy(alpha = 0.45f),
    isDark = false,
)

val DarkColors = AppColors(
    background = Color.Black,
    secondaryBackground = Color(0xFF1C1C1E),
    tertiaryBackground = Color(0xFF2C2C2E),
    groupedBackground = Color.Black,
    secondaryGroupedBackground = Color(0xFF1C1C1E),
    tertiaryGroupedBackground = Color(0xFF2C2C2E),
    label = Color.White,
    secondaryLabel = Color(0x99EBEBF5),
    tertiaryLabel = Color(0x4DEBEBF5),
    quaternaryLabel = Color(0x29EBEBF5),
    separator = Color(0x99545458),
    opaqueSeparator = Color(0xFF38383A),
    fill = Color(0x5C787880),
    secondaryFill = Color(0x52787880),
    tertiaryFill = Color(0x3D767680),
    quaternaryFill = Color(0x2E767680),
    gray = Color(0xFF8E8E93),
    red = Color(0xFFFF453A),
    green = Color(0xFF30D158),
    orange = Color(0xFFFF9F0A),
    pink = Color(0xFFFF375F),
    glassSurface = Color(0xFF121212).copy(alpha = 0.45f),
    isDark = true,
)

fun AccentChoice.color(dark: Boolean): Color = when (this) {
    AccentChoice.Blue -> if (dark) Color(0xFF0A84FF) else Color(0xFF007AFF)
    AccentChoice.Indigo -> if (dark) Color(0xFF5E5CE6) else Color(0xFF5856D6)
    AccentChoice.Purple -> if (dark) Color(0xFFBF5AF2) else Color(0xFFAF52DE)
    AccentChoice.Pink -> if (dark) Color(0xFFFF375F) else Color(0xFFFF2D55)
    AccentChoice.Red -> if (dark) Color(0xFFFF453A) else Color(0xFFFF3B30)
    AccentChoice.Orange -> if (dark) Color(0xFFFF9F0A) else Color(0xFFFF9500)
    AccentChoice.Yellow -> if (dark) Color(0xFFFFD60A) else Color(0xFFFFCC00)
    AccentChoice.Green -> if (dark) Color(0xFF30D158) else Color(0xFF34C759)
    AccentChoice.Mint -> if (dark) Color(0xFF63E6E2) else Color(0xFF00C7BE)
    AccentChoice.Teal -> if (dark) Color(0xFF40C8E0) else Color(0xFF30B0C7)
    AccentChoice.Cyan -> if (dark) Color(0xFF64D2FF) else Color(0xFF32ADE6)
    AccentChoice.Brown -> if (dark) Color(0xFFAC8E68) else Color(0xFFA2845E)
}

val Inter = FontFamily(
    Font(R.font.inter_regular, FontWeight.Normal),
    Font(R.font.inter_medium, FontWeight.Medium),
    Font(R.font.inter_semibold, FontWeight.SemiBold),
    Font(R.font.inter_bold, FontWeight.Bold),
)

/** The iOS Dynamic Type styles at the default size. */
object Type {
    private fun style(size: Float, line: Float, weight: FontWeight = FontWeight.Normal, tracking: Float = 0f) =
        TextStyle(
            fontFamily = Inter,
            fontSize = size.sp,
            lineHeight = line.sp,
            fontWeight = weight,
            letterSpacing = tracking.em,
        )

    val largeTitle = style(34f, 41f, FontWeight.Bold, -0.012f)
    val title1 = style(28f, 34f, FontWeight.Bold, -0.01f)
    val title2 = style(22f, 28f, FontWeight.Bold, -0.008f)
    val title3 = style(20f, 25f, FontWeight.SemiBold, -0.006f)
    val headline = style(17f, 22f, FontWeight.SemiBold, -0.012f)
    val body = style(17f, 22f, FontWeight.Normal, -0.012f)
    val callout = style(16f, 21f, FontWeight.Normal, -0.01f)
    val subheadline = style(15f, 20f, FontWeight.Normal, -0.008f)
    val footnote = style(13f, 18f, FontWeight.Normal, -0.004f)
    val caption1 = style(12f, 16f)
    val caption2 = style(11f, 13f, FontWeight.Normal, 0.004f)
}

val LocalColors = staticCompositionLocalOf { LightColors }
val LocalIsDark = staticCompositionLocalOf { false }
val LocalTint = staticCompositionLocalOf { Color(0xFF007AFF) }

object AppTheme {
    val colors: AppColors @Composable get() = LocalColors.current
    val tint: Color @Composable get() = LocalTint.current
    val isDark: Boolean @Composable get() = LocalIsDark.current
}

@Composable
fun AppTheme(content: @Composable () -> Unit) {
    val dark = when (AppSettings.theme) {
        ThemeMode.System -> isSystemInDarkTheme()
        ThemeMode.Light -> false
        ThemeMode.Dark -> true
    }
    val colors = if (dark) DarkColors else LightColors
    val tint = AppSettings.accent.color(dark)
    CompositionLocalProvider(
        LocalColors provides colors,
        LocalIsDark provides dark,
        LocalTint provides tint,
        LocalTextSelectionColors provides TextSelectionColors(tint, tint.copy(alpha = 0.3f)),
        content = content,
    )
}
