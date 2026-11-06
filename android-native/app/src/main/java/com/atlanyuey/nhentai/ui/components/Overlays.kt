package com.atlanyuey.nhentai.ui.components

import androidx.activity.compose.BackHandler
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.gestures.detectVerticalDragGestures
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.foundation.layout.systemBars
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.boundsInRoot
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import com.atlanyuey.nhentai.core.tr
import com.atlanyuey.nhentai.ui.theme.AppTheme
import com.atlanyuey.nhentai.ui.theme.Icons
import com.atlanyuey.nhentai.ui.theme.Type
import com.kyant.backdrop.Backdrop
import com.kyant.shapes.Capsule
import kotlinx.coroutines.launch
import kotlin.math.roundToInt

data class MenuItem(
    val title: String,
    val icon: ImageVector? = null,
    val checked: Boolean = false,
    val destructive: Boolean = false,
    val enabled: Boolean = true,
    val onClick: () -> Unit,
)

enum class ButtonRole { Default, Cancel, Destructive, Preferred }

data class DialogButton(val title: String, val role: ButtonRole = ButtonRole.Default, val onClick: () -> Unit = {})

sealed class Overlay {
    internal val visible = Animatable(0f)

    class Menu(val anchor: Rect, val sections: List<List<MenuItem>>, val title: String?) : Overlay()
    class Alert(val title: String, val message: String?, val buttons: List<DialogButton>) : Overlay()
    class ActionSheet(val title: String?, val message: String?, val buttons: List<DialogButton>) : Overlay()
    class Sheet(val content: @Composable (dismiss: () -> Unit) -> Unit) : Overlay()
}

/** Menus, alerts, action sheets and sheets, drawn above the app in glass. */
class OverlayController {
    val items = mutableStateListOf<Overlay>()

    /** The host's coroutine scope (animations need its frame clock). */
    internal var uiScope: kotlinx.coroutines.CoroutineScope? = null

    fun menu(anchor: Rect, sections: List<List<MenuItem>>, title: String? = null) {
        items.add(Overlay.Menu(anchor, sections, title))
    }

    fun alert(title: String, message: String? = null, buttons: List<DialogButton> = emptyList()) {
        items.add(Overlay.Alert(title, message, buttons))
    }

    fun actionSheet(title: String?, message: String? = null, buttons: List<DialogButton>) {
        items.add(Overlay.ActionSheet(title, message, buttons))
    }

    fun sheet(content: @Composable (dismiss: () -> Unit) -> Unit) {
        items.add(Overlay.Sheet(content))
    }

    internal fun remove(overlay: Overlay) {
        items.remove(overlay)
    }
}

val LocalOverlays = staticCompositionLocalOf { OverlayController() }

/** Remembers where a view is, for menus opened from it. */
class AnchorState {
    var bounds by mutableStateOf(Rect.Zero)
}

@Composable
fun rememberAnchor() = remember { AnchorState() }

fun Modifier.anchor(state: AnchorState) = onGloballyPositioned { state.bounds = it.boundsInRoot() }

/** A glass button that opens a menu (iOS pull-down button). */
@Composable
fun MenuButton(
    icon: ImageVector,
    contentDescription: String?,
    sections: () -> List<List<MenuItem>>,
    modifier: Modifier = Modifier,
    title: String? = null,
) {
    val anchor = rememberAnchor()
    val overlays = LocalOverlays.current
    GlassCircleButton(
        icon = icon,
        contentDescription = contentDescription,
        onClick = { overlays.menu(anchor.bounds, sections(), title) },
        modifier = modifier.anchor(anchor),
    )
}

/** Menu items for choosing one of [options] (a checkmark on [selected]). */
fun <T> pickerItems(options: List<T>, selected: T, title: (T) -> String, onSelect: (T) -> Unit): List<MenuItem> =
    options.map { option -> MenuItem(title(option), checked = option == selected) { onSelect(option) } }

@Composable
fun OverlayHost(controller: OverlayController, backdrop: Backdrop) {
    controller.uiScope = rememberCoroutineScope()
    val items = controller.items
    BackHandler(enabled = items.isNotEmpty()) {
        items.lastOrNull()?.let { controller.dismissAnimated(it) }
    }
    CompositionLocalProvider(LocalBackdrop provides backdrop) {
        for (overlay in items.toList()) {
            androidx.compose.runtime.key(overlay) {
                LaunchedEffect(overlay) {
                    overlay.visible.animateTo(1f, spring(dampingRatio = 0.82f, stiffness = 520f))
                }
                val dismiss: () -> Unit = { controller.dismissAnimated(overlay) }
                when (overlay) {
                    is Overlay.Menu -> MenuOverlay(overlay, dismiss)
                    is Overlay.Alert -> AlertOverlay(overlay, dismiss)
                    is Overlay.ActionSheet -> ActionSheetOverlay(overlay, dismiss)
                    is Overlay.Sheet -> SheetOverlay(overlay, dismiss)
                }
            }
        }
    }
}

fun OverlayController.dismissAnimated(overlay: Overlay) {
    val scope = uiScope
    if (scope == null) {
        remove(overlay)
        return
    }
    scope.launch {
        overlay.visible.animateTo(0f, spring(dampingRatio = 1f, stiffness = 900f))
        remove(overlay)
    }
}

@Composable
private fun Scrim(alpha: Float, onTap: () -> Unit) {
    Box(
        Modifier
            .fillMaxSize()
            .graphicsLayer { this.alpha = alpha }
            .background(Color.Black.copy(alpha = 0.22f))
            .pointerInput(Unit) { detectTapGestures { onTap() } },
    )
}

// MARK: Menu

@Composable
private fun MenuOverlay(menu: Overlay.Menu, dismiss: () -> Unit) {
    val density = LocalDensity.current
    val insets = WindowInsets.systemBars
    var origin by remember { mutableStateOf(TransformOrigin(1f, 0f)) }
    Box(
        Modifier
            .fillMaxSize()
            .pointerInput(Unit) { detectTapGestures { dismiss() } },
    )
    androidx.compose.ui.layout.Layout(
        content = {
            Column(
                Modifier
                    .graphicsLayer {
                        val v = menu.visible.value
                        alpha = v.coerceIn(0f, 1f)
                        scaleX = 0.6f + 0.4f * v
                        scaleY = 0.6f + 0.4f * v
                        transformOrigin = origin
                    }
                    .glass(RoundedCornerShape(24.dp), GlassStyle.Panel)
                    .verticalScroll(rememberScrollState())
                    .padding(vertical = 6.dp),
            ) {
                menu.title?.let {
                    Txt(it, Modifier.padding(horizontal = 18.dp, vertical = 8.dp), style = Type.footnote, color = AppTheme.colors.secondaryLabel)
                }
                menu.sections.forEachIndexed { index, section ->
                    if (index > 0) {
                        Box(Modifier.fillMaxWidth().padding(vertical = 6.dp).height(0.5.dp).background(AppTheme.colors.separator))
                    }
                    section.forEach { item -> MenuRow(item) { dismiss(); item.onClick() } }
                }
            }
        },
        modifier = Modifier.fillMaxSize(),
    ) { measurables, constraints ->
        val margin = 16.dp.roundToPx()
        val gap = 8.dp.roundToPx()
        val top = insets.getTop(density) + margin
        val bottom = constraints.maxHeight - insets.getBottom(density) - margin
        val anchor = menu.anchor
        val width = minOf(260.dp.roundToPx(), constraints.maxWidth - 2 * margin)
        val below = anchor.bottom < constraints.maxHeight * 0.6f
        val available = if (below) bottom - anchor.bottom.toInt() - gap else anchor.top.toInt() - gap - top
        val placeable = measurables.first().measure(
            androidx.compose.ui.unit.Constraints(minWidth = width, maxWidth = width, maxHeight = available.coerceAtLeast(0)),
        )
        val alignEnd = anchor.center.x > constraints.maxWidth / 2f
        val x = if (alignEnd) {
            (anchor.right.toInt() - width).coerceIn(margin, constraints.maxWidth - width - margin)
        } else {
            anchor.left.toInt().coerceIn(margin, constraints.maxWidth - width - margin)
        }
        val y = if (below) anchor.bottom.toInt() + gap else anchor.top.toInt() - gap - placeable.height
        origin = TransformOrigin(if (alignEnd) 1f else 0f, if (below) 0f else 1f)
        layout(constraints.maxWidth, constraints.maxHeight) { placeable.place(x, y) }
    }
}

@Composable
private fun MenuRow(item: MenuItem, onClick: () -> Unit) {
    val colors = AppTheme.colors
    val color = when {
        !item.enabled -> colors.tertiaryLabel
        item.destructive -> colors.red
        else -> colors.label
    }
    Row(
        Modifier
            .fillMaxWidth()
            .heightIn(min = 46.dp)
            .clip(RoundedCornerShape(14.dp))
            .clickable(enabled = item.enabled, onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Box(Modifier.size(22.dp), contentAlignment = Alignment.Center) {
            when {
                item.checked -> AppIcon(Icons.Check, null, tint = color, size = 18.dp)
                item.icon != null -> AppIcon(item.icon, null, tint = color, size = 20.dp)
            }
        }
        Txt(item.title, Modifier.weight(1f), style = Type.body, color = color, maxLines = 2)
    }
}

// MARK: Alert

@Composable
private fun AlertOverlay(alert: Overlay.Alert, dismiss: () -> Unit) {
    val v = alert.visible.value
    Scrim(v) {}
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Column(
            Modifier
                .padding(32.dp)
                .widthIn(max = 320.dp)
                .graphicsLayer {
                    alpha = v.coerceIn(0f, 1f)
                    scaleX = 1.12f - 0.12f * v
                    scaleY = 1.12f - 0.12f * v
                }
                .glass(RoundedCornerShape(34.dp), GlassStyle.Panel)
                .padding(start = 20.dp, end = 20.dp, top = 22.dp, bottom = 16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Txt(alert.title, style = Type.headline, align = TextAlign.Center)
            alert.message?.let {
                Spacer(Modifier.height(6.dp))
                Txt(it, style = Type.subheadline, align = TextAlign.Center, color = AppTheme.colors.label.copy(alpha = 0.85f))
            }
            Spacer(Modifier.height(18.dp))
            val buttons = alert.buttons.ifEmpty { listOf(DialogButton(tr("OK"), ButtonRole.Preferred)) }
            DialogButtons(buttons, sideBySide = buttons.size == 2) { button ->
                dismiss()
                button.onClick()
            }
        }
    }
}

@Composable
private fun DialogButtons(buttons: List<DialogButton>, sideBySide: Boolean, onClick: (DialogButton) -> Unit) {
    if (sideBySide) {
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            buttons.forEach { DialogCapsule(it, Modifier.weight(1f)) { onClick(it) } }
        }
    } else {
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            buttons.forEach { DialogCapsule(it, Modifier.fillMaxWidth()) { onClick(it) } }
        }
    }
}

@Composable
private fun DialogCapsule(button: DialogButton, modifier: Modifier, onClick: () -> Unit) {
    val colors = AppTheme.colors
    val tint = AppTheme.tint
    val (background, foreground) = when (button.role) {
        ButtonRole.Preferred -> tint to Color.White
        ButtonRole.Destructive -> colors.fill to colors.red
        ButtonRole.Cancel -> colors.fill to colors.label
        ButtonRole.Default -> colors.fill to colors.label
    }
    Box(
        modifier
            .height(48.dp)
            .clip(Capsule())
            .background(background)
            .clickable(onClick = onClick)
            .padding(horizontal = 14.dp),
        contentAlignment = Alignment.Center,
    ) {
        Txt(
            button.title,
            style = Type.body.copy(fontWeight = if (button.role == ButtonRole.Cancel) FontWeight.Medium else FontWeight.SemiBold),
            color = foreground,
            maxLines = 1,
        )
    }
}

// MARK: Action sheet

@Composable
private fun ActionSheetOverlay(sheet: Overlay.ActionSheet, dismiss: () -> Unit) {
    val v = sheet.visible.value
    Scrim(v, dismiss)
    Box(Modifier.fillMaxSize().navigationBarsPadding(), contentAlignment = Alignment.BottomCenter) {
        Column(
            Modifier
                .padding(10.dp)
                .widthIn(max = 480.dp)
                .fillMaxWidth()
                .graphicsLayer {
                    translationY = (1f - v) * size.height * 1.1f
                }
                .glass(RoundedCornerShape(34.dp), GlassStyle.Panel)
                .padding(14.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            if (sheet.title != null || sheet.message != null) {
                sheet.title?.let { Txt(it, style = Type.footnote.copy(fontWeight = FontWeight.SemiBold), color = AppTheme.colors.secondaryLabel, align = TextAlign.Center) }
                sheet.message?.let { Txt(it, style = Type.footnote, color = AppTheme.colors.secondaryLabel, align = TextAlign.Center) }
                Spacer(Modifier.height(12.dp))
            }
            val buttons = sheet.buttons.filter { it.role != ButtonRole.Cancel }
            DialogButtons(buttons + DialogButton(tr("Cancel"), ButtonRole.Cancel), sideBySide = false) { button ->
                dismiss()
                button.onClick()
            }
        }
    }
}

// MARK: Sheet

@Composable
private fun SheetOverlay(sheet: Overlay.Sheet, dismiss: () -> Unit) {
    val v = sheet.visible.value
    val scope = rememberCoroutineScope()
    val drag = remember { Animatable(0f) }
    Scrim(v, dismiss)
    BoxWithConstraints(Modifier.fillMaxSize().statusBarsPadding(), contentAlignment = Alignment.BottomCenter) {
        val maxHeight = maxHeight
        Column(
            Modifier
                .widthIn(max = 640.dp)
                .fillMaxWidth()
                .heightIn(max = maxHeight * 0.94f)
                .offset { IntOffset(0, drag.value.roundToInt()) }
                .graphicsLayer { translationY = (1f - v) * size.height }
                .clip(RoundedCornerShape(topStart = 30.dp, topEnd = 30.dp))
                .background(AppTheme.colors.groupedBackground)
                .pointerInput(Unit) {
                    detectVerticalDragGestures(
                        onDragEnd = {
                            if (drag.value > 120.dp.toPx()) {
                                dismiss()
                            } else {
                                scope.launch { drag.animateTo(0f, spring(stiffness = 600f)) }
                            }
                        },
                    ) { _, amount ->
                        scope.launch { drag.snapTo((drag.value + amount).coerceAtLeast(0f)) }
                    }
                }
                .clickable(interactionSource = remember { MutableInteractionSource() }, indication = null) {},
        ) {
            Box(Modifier.fillMaxWidth().padding(top = 6.dp), contentAlignment = Alignment.Center) {
                Box(Modifier.size(width = 36.dp, height = 5.dp).clip(Capsule()).background(AppTheme.colors.tertiaryLabel))
            }
            sheet.content(dismiss)
        }
    }
}

@Suppress("unused")
private fun Modifier.centered() = wrapContentSize(Alignment.Center)
