package com.atlanyuey.nhentai.ui.components

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.isSpecified
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.nestedscroll.NestedScrollConnection
import androidx.compose.ui.input.nestedscroll.NestedScrollSource
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.Velocity
import androidx.compose.ui.unit.dp
import com.atlanyuey.nhentai.core.tr
import com.atlanyuey.nhentai.ui.glass.LiquidSlider
import com.atlanyuey.nhentai.ui.glass.LiquidToggle
import com.atlanyuey.nhentai.ui.theme.AppTheme
import com.atlanyuey.nhentai.ui.theme.Icons
import com.atlanyuey.nhentai.ui.theme.Type
import com.kyant.backdrop.backdrops.rememberCanvasBackdrop
import com.kyant.shapes.Capsule
import kotlinx.coroutines.launch
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.roundToInt
import kotlin.math.sin

/** iOS activity indicator (eight fading spokes). */
@Composable
fun ActivityIndicator(modifier: Modifier = Modifier, size: Dp = 22.dp, color: Color = Color.Unspecified, progress: Float? = null) {
    val tint = if (color.isSpecified) color else AppTheme.colors.secondaryLabel
    val transition = rememberInfiniteTransition(label = "spinner")
    val step by transition.animateFloat(
        initialValue = 0f,
        targetValue = 8f,
        animationSpec = infiniteRepeatable(tween(800, easing = LinearEasing), RepeatMode.Restart),
        label = "step",
    )
    Canvas(modifier.size(size)) {
        val spokes = 8
        val visible = progress?.let { (it * spokes).toInt().coerceIn(0, spokes) } ?: spokes
        val head = if (progress == null) step.toInt() else 0
        val radius = this.size.minDimension / 2f
        val stroke = radius * 0.24f
        for (i in 0 until visible) {
            val angle = (i * 2 * PI / spokes - PI / 2).toFloat()
            val age = ((head - i) % spokes + spokes) % spokes
            val alpha = if (progress != null) 0.8f else 1f - age / spokes.toFloat() * 0.75f
            val inner = radius * 0.45f
            val outer = radius - stroke / 2
            drawLine(
                tint.copy(alpha = alpha * tint.alpha),
                start = Offset(center.x + cos(angle) * inner, center.y + sin(angle) * inner),
                end = Offset(center.x + cos(angle) * outer, center.y + sin(angle) * outer),
                strokeWidth = stroke,
                cap = StrokeCap.Round,
            )
        }
    }
}

/**
 * iOS pull to refresh: pull the list down past the top to show a spinner,
 * release to refresh.
 */
@Composable
fun PullToRefresh(
    refreshing: Boolean,
    onRefresh: () -> Unit,
    modifier: Modifier = Modifier,
    topInset: Dp = 0.dp,
    content: @Composable BoxScope.() -> Unit,
) {
    val density = LocalDensity.current
    val threshold = with(density) { 80.dp.toPx() }
    val scope = rememberCoroutineScope()
    val offset = remember { Animatable(0f) }
    var dragging by remember { mutableStateOf(false) }
    val connection = remember(refreshing) {
        object : NestedScrollConnection {
            override fun onPreScroll(available: Offset, source: NestedScrollSource): Offset {
                if (source == NestedScrollSource.UserInput && available.y < 0 && offset.value > 0f) {
                    val consumed = maxOf(available.y, -offset.value)
                    scope.launch { offset.snapTo(offset.value + consumed) }
                    return Offset(0f, consumed)
                }
                return Offset.Zero
            }

            override fun onPostScroll(consumed: Offset, available: Offset, source: NestedScrollSource): Offset {
                if (source == NestedScrollSource.UserInput && available.y > 0) {
                    dragging = true
                    scope.launch { offset.snapTo(offset.value + available.y * 0.5f) }
                    return Offset(0f, available.y)
                }
                return Offset.Zero
            }

            override suspend fun onPreFling(available: Velocity): Velocity {
                dragging = false
                if (offset.value >= threshold && !refreshing) onRefresh()
                if (offset.value > 0f) {
                    offset.animateTo(if (offset.value >= threshold) threshold * 0.7f else 0f, spring(stiffness = 500f))
                    return available
                }
                return Velocity.Zero
            }
        }
    }
    LaunchedEffect(refreshing) {
        if (!refreshing && !dragging) offset.animateTo(0f, spring(stiffness = 400f))
        if (refreshing && offset.value == 0f) offset.animateTo(threshold * 0.7f, spring(stiffness = 400f))
    }
    Box(modifier.nestedScroll(connection)) {
        Box(Modifier.fillMaxSize().offset { IntOffset(0, offset.value.roundToInt()) }, content = content)
        val value = offset.value
        if (value > 1f || refreshing) {
            Box(
                Modifier
                    .fillMaxWidth()
                    .padding(top = topInset)
                    .height(with(density) { value.toDp() }),
                contentAlignment = Alignment.Center,
            ) {
                ActivityIndicator(progress = if (refreshing) null else (value / threshold).coerceIn(0f, 1f))
            }
        }
    }
}

/** iOS segmented control with a sliding thumb. */
@Composable
fun <T> SegmentedControl(
    options: List<T>,
    selected: T,
    label: @Composable (T) -> String,
    onSelect: (T) -> Unit,
    modifier: Modifier = Modifier,
) {
    val colors = AppTheme.colors
    val index = options.indexOf(selected).coerceAtLeast(0)
    val position by animateFloatAsState(index.toFloat(), spring(dampingRatio = 0.8f, stiffness = 500f), label = "segment")
    var width by remember { mutableFloatStateOf(0f) }
    val density = LocalDensity.current
    Box(
        modifier
            .height(36.dp)
            .clip(Capsule())
            .background(colors.tertiaryFill)
            .onSizeChanged { width = it.width.toFloat() }
            .padding(2.dp),
    ) {
        val segment = if (options.isEmpty()) 0f else (width - with(density) { 4.dp.toPx() }) / options.size
        Box(
            Modifier
                .fillMaxHeight()
                .width(with(density) { segment.toDp() })
                .graphicsLayer { translationX = segment * position }
                .clip(Capsule())
                .background(if (colors.isDark) Color(0xFF636366) else Color.White),
        )
        Row(Modifier.fillMaxSize()) {
            options.forEach { option ->
                Box(
                    Modifier
                        .weight(1f)
                        .fillMaxHeight()
                        .clickable(interactionSource = remember { MutableInteractionSource() }, indication = null) { onSelect(option) },
                    contentAlignment = Alignment.Center,
                ) {
                    Txt(
                        label(option),
                        style = Type.subheadline.copy(fontWeight = if (option == selected) FontWeight.SemiBold else FontWeight.Medium),
                        maxLines = 1,
                    )
                }
            }
        }
    }
}

/** iOS stepper (minus / plus). */
@Composable
fun Stepper(value: Int, range: IntRange, onChange: (Int) -> Unit) {
    val colors = AppTheme.colors
    Row(
        Modifier.height(34.dp).clip(Capsule()).background(colors.tertiaryFill),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        StepperHalf(Icons.Minus, value > range.first) { onChange(value - 1) }
        Box(Modifier.width(0.5.dp).height(18.dp).background(colors.separator))
        StepperHalf(Icons.Plus, value < range.last) { onChange(value + 1) }
    }
}

@Composable
private fun StepperHalf(icon: ImageVector, enabled: Boolean, onClick: () -> Unit) {
    Box(
        Modifier.width(46.dp).fillMaxHeight().clickable(enabled = enabled, onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        AppIcon(icon, null, tint = if (enabled) AppTheme.colors.label else AppTheme.colors.tertiaryLabel, size = 18.dp)
    }
}

/** The glass switch (Liquid Glass thumb while dragging). */
@Composable
fun GlassToggle(checked: Boolean, onChange: (Boolean) -> Unit, background: Color = AppTheme.colors.secondaryGroupedBackground) {
    val backdrop = rememberCanvasBackdrop { drawRect(background) }
    LiquidToggle(selected = { checked }, onSelect = onChange, backdrop = backdrop)
}

/** The glass slider. */
@Composable
fun GlassSlider(
    value: Float,
    onChange: (Float) -> Unit,
    range: ClosedFloatingPointRange<Float>,
    modifier: Modifier = Modifier,
    background: Color = AppTheme.colors.secondaryGroupedBackground,
) {
    val backdrop = rememberCanvasBackdrop { drawRect(background) }
    LiquidSlider(
        value = { value },
        onValueChange = onChange,
        valueRange = range,
        visibilityThreshold = (range.endInclusive - range.start) / 1000f,
        backdrop = backdrop,
        modifier = modifier,
    )
}

/** iOS 26 search field (glass capsule). */
@Composable
fun SearchField(
    text: String,
    onTextChange: (String) -> Unit,
    placeholder: String,
    onSubmit: () -> Unit,
    modifier: Modifier = Modifier,
    focusRequester: FocusRequester = remember { FocusRequester() },
    onFocus: (Boolean) -> Unit = {},
    filled: Boolean = false,
) {
    val colors = AppTheme.colors
    Row(
        modifier
            .height(if (filled) 40.dp else 48.dp)
            .then(if (filled) Modifier.clip(Capsule()).background(colors.tertiaryFill) else Modifier.glass(Capsule()))
            .padding(start = if (filled) 12.dp else 16.dp, end = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        AppIcon(Icons.Search, null, tint = colors.secondaryLabel, size = 18.dp)
        Box(Modifier.weight(1f), contentAlignment = Alignment.CenterStart) {
            if (text.isEmpty()) Txt(placeholder, style = Type.body, color = colors.secondaryLabel, maxLines = 1)
            BasicTextField(
                value = text,
                onValueChange = onTextChange,
                singleLine = true,
                textStyle = Type.body.copy(color = colors.label),
                cursorBrush = SolidColor(AppTheme.tint),
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                keyboardActions = KeyboardActions(onSearch = { onSubmit() }),
                modifier = Modifier
                    .fillMaxWidth()
                    .focusRequester(focusRequester)
                    .onFocusChanged { onFocus(it.isFocused) },
            )
        }
        if (text.isNotEmpty()) {
            Box(
                Modifier.size(30.dp).clip(Capsule()).clickable { onTextChange("") },
                contentAlignment = Alignment.Center,
            ) {
                AppIcon(Icons.CloseCircle, tr("Clear"), tint = colors.tertiaryLabel, size = 18.dp)
            }
        }
    }
}

/** A large tinted glass capsule button (Read). */
@Composable
fun ProminentButton(
    text: String,
    icon: ImageVector?,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    height: Dp = 46.dp,
) {
    GlassCapsuleButton(onClick, modifier, tint = AppTheme.tint, height = height) {
        icon?.let { AppIcon(it, null, tint = Color.White, size = 18.dp) }
        Txt(text, style = Type.headline, color = Color.White, maxLines = 1)
    }
}

/** A plain text button in the tint color. */
@Composable
fun TextButton(text: String, onClick: () -> Unit, modifier: Modifier = Modifier, enabled: Boolean = true, bold: Boolean = false) {
    Txt(
        text,
        modifier
            .clip(Capsule())
            .clickable(enabled = enabled, onClick = onClick)
            .padding(horizontal = 6.dp, vertical = 4.dp),
        style = if (bold) Type.headline else Type.body,
        color = if (enabled) AppTheme.tint else AppTheme.colors.tertiaryLabel,
        maxLines = 1,
    )
}
