package com.atlanyuey.nhentai.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.RectangleShape
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.isSpecified
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.util.fastCoerceAtMost
import androidx.compose.ui.util.lerp
import androidx.compose.foundation.clickable
import com.atlanyuey.nhentai.ui.glass.InteractiveHighlight
import com.atlanyuey.nhentai.ui.theme.AppTheme
import com.kyant.backdrop.Backdrop
import com.kyant.backdrop.backdrops.emptyBackdrop
import com.kyant.backdrop.drawBackdrop
import com.kyant.backdrop.drawPlainBackdrop
import com.kyant.backdrop.effects.blur
import com.kyant.backdrop.effects.lens
import com.kyant.backdrop.effects.runtimeShaderEffect
import com.kyant.backdrop.effects.vibrancy
import com.kyant.backdrop.isRenderEffectSupported
import com.kyant.backdrop.isRuntimeShaderSupported
import com.kyant.shapes.Capsule
import kotlin.math.abs
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.tanh

/** The content behind the glass drawn at this point (set by scaffolds). */
val LocalBackdrop = staticCompositionLocalOf<Backdrop> { emptyBackdrop() }

enum class GlassStyle { Control, Panel }

/**
 * Liquid Glass: blurs, saturates and refracts what is behind (Android 12+
 * blur, Android 13+ refraction). Older versions get a frosted fill.
 */
@Composable
fun Modifier.glass(
    shape: Shape = Capsule(),
    style: GlassStyle = GlassStyle.Control,
    backdrop: Backdrop = LocalBackdrop.current,
    tint: Color = Color.Unspecified,
    surface: Color = Color.Unspecified,
    interactive: InteractiveHighlight? = null,
    pressScale: Dp = 4.dp,
): Modifier {
    val colors = AppTheme.colors
    val blurSupported = isRenderEffectSupported()
    val surfaceColor = when {
        surface.isSpecified -> surface
        !blurSupported -> colors.glassSurface.copy(alpha = 0.94f)
        style == GlassStyle.Panel -> colors.glassSurface.copy(alpha = if (colors.isDark) 0.62f else 0.66f)
        else -> colors.glassSurface
    }
    return this.drawBackdrop(
        backdrop = backdrop,
        shape = { shape },
        effects = {
            vibrancy()
            if (style == GlassStyle.Panel) {
                blur(12.dp.toPx())
                lens(20.dp.toPx(), 28.dp.toPx())
            } else {
                blur(3.dp.toPx())
                lens(12.dp.toPx(), 24.dp.toPx())
            }
        },
        layerBlock = interactive?.let { highlight ->
            {
                val width = size.width
                val height = size.height
                val progress = highlight.pressProgress
                val scale = lerp(1f, 1f + pressScale.toPx() / size.height, progress)
                val maxOffset = size.minDimension
                val offset = highlight.offset
                translationX = maxOffset * tanh(0.05f * offset.x / maxOffset)
                translationY = maxOffset * tanh(0.05f * offset.y / maxOffset)
                val maxDragScale = pressScale.toPx() / size.height
                val angle = atan2(offset.y, offset.x)
                scaleX = scale + maxDragScale * abs(cos(angle) * offset.x / size.maxDimension) *
                    (width / height).fastCoerceAtMost(1f)
                scaleY = scale + maxDragScale * abs(sin(angle) * offset.y / size.maxDimension) *
                    (height / width).fastCoerceAtMost(1f)
            }
        },
        onDrawSurface = {
            if (tint.isSpecified) {
                drawRect(tint, blendMode = BlendMode.Hue)
                drawRect(tint.copy(alpha = 0.78f))
            } else {
                drawRect(surfaceColor)
            }
        },
    )
}

/** Press feedback of glass controls (stretch and glow under the finger). */
@Composable
fun rememberGlassHighlight(): InteractiveHighlight {
    val scope = rememberCoroutineScope()
    return remember(scope) { InteractiveHighlight(animationScope = scope) }
}

/** A round glass button (navigation bars, reader controls). */
@Composable
fun GlassCircleButton(
    icon: ImageVector,
    contentDescription: String?,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    size: Dp = 44.dp,
    iconSize: Dp = 20.dp,
    tint: Color = Color.Unspecified,
    iconColor: Color = Color.Unspecified,
    enabled: Boolean = true,
    backdrop: Backdrop = LocalBackdrop.current,
) {
    val highlight = rememberGlassHighlight()
    val color = when {
        iconColor.isSpecified -> iconColor
        tint.isSpecified -> Color.White
        else -> AppTheme.colors.label
    }
    Box(
        modifier
            .size(size)
            .glass(Capsule(), tint = tint, backdrop = backdrop, interactive = highlight)
            .then(highlight.modifier)
            .then(highlight.gestureModifier)
            .clickable(enabled = enabled, interactionSource = null, indication = null, role = Role.Button, onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        AppIcon(icon, contentDescription, tint = if (enabled) color else color.copy(alpha = 0.35f), size = iconSize)
    }
}

/** A capsule glass button with free content (text, icon and text). */
@Composable
fun GlassCapsuleButton(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    tint: Color = Color.Unspecified,
    height: Dp = 44.dp,
    horizontalPadding: Dp = 16.dp,
    content: @Composable RowScope.() -> Unit,
) {
    val highlight = rememberGlassHighlight()
    Row(
        modifier
            .height(height)
            .glass(Capsule(), tint = tint, interactive = highlight)
            .then(highlight.modifier)
            .then(highlight.gestureModifier)
            .clickable(interactionSource = null, indication = null, role = Role.Button, onClick = onClick)
            .padding(horizontal = horizontalPadding),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = androidx.compose.foundation.layout.Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally),
        content = content,
    )
}

/** A glass panel (menus, alerts, reader controls). */
@Composable
fun GlassPanel(
    modifier: Modifier = Modifier,
    cornerRadius: Dp = 28.dp,
    content: @Composable BoxScope.() -> Unit,
) {
    Box(modifier.glass(RoundedCornerShape(cornerRadius), GlassStyle.Panel), content = content)
}

/**
 * iOS 26 soft scroll edge: content under the bars is blurred progressively
 * and fades into the background (Android 13+; a fade on older versions).
 */
@Composable
fun SoftEdge(height: Dp, modifier: Modifier = Modifier, top: Boolean = true, backdrop: Backdrop = LocalBackdrop.current) {
    val background = AppTheme.colors.background
    if (isRuntimeShaderSupported()) {
        Box(
            modifier
                .fillMaxWidth()
                .height(height)
                .drawPlainBackdrop(
                    backdrop = backdrop,
                    shape = { RectangleShape },
                    effects = {
                        blur(6.dp.toPx())
                        runtimeShaderEffect(
                            "SoftEdge",
                            """
uniform shader content;
uniform float2 size;
layout(color) uniform half4 tint;
uniform float top;

half4 main(float2 coord) {
    float y = top > 0.5 ? coord.y : size.y - coord.y;
    float alpha = smoothstep(size.y, size.y * 0.35, y);
    half4 blurred = content.eval(coord);
    return mix(blurred, tint, 0.55 * alpha) * alpha;
}""",
                            "content",
                        ) {
                            setFloatUniform("size", size.width, size.height)
                            setColorUniform("tint", background)
                            setFloatUniform("top", if (top) 1f else 0f)
                        }
                    },
                ),
        )
    } else {
        Box(
            modifier
                .fillMaxWidth()
                .height(height)
                .background(
                    Brush.verticalGradient(
                        if (top) listOf(background.copy(alpha = 0.92f), background.copy(alpha = 0f))
                        else listOf(background.copy(alpha = 0f), background.copy(alpha = 0.92f)),
                    ),
                ),
        )
    }
}
