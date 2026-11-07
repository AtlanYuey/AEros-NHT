package com.atlanyuey.nhentai.ui

import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.tween
import androidx.compose.ui.BiasAlignment
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.foundation.layout.statusBarsPadding
import com.atlanyuey.nhentai.ui.components.BarsState
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.layout.boundsInRoot
import androidx.compose.ui.layout.onGloballyPositioned
import android.content.ClipboardManager
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.saveable.rememberSaveableStateHolder
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LifecycleEventEffect
import com.atlanyuey.nhentai.core.AppSettings
import com.atlanyuey.nhentai.core.HandTracker
import com.atlanyuey.nhentai.core.TabBarPosition
import androidx.compose.ui.input.pointer.PointerEventPass
import androidx.compose.ui.input.pointer.PointerEventType
import androidx.compose.ui.input.pointer.pointerInput
import com.atlanyuey.nhentai.core.tr
import com.atlanyuey.nhentai.screens.FavoritesScreen
import com.atlanyuey.nhentai.screens.GalleryScreen
import com.atlanyuey.nhentai.screens.HistoryScreen
import com.atlanyuey.nhentai.screens.HomeScreen
import com.atlanyuey.nhentai.screens.MoreScreen
import com.atlanyuey.nhentai.ui.components.LocalBackdrop
import com.atlanyuey.nhentai.ui.components.ButtonRole
import com.atlanyuey.nhentai.ui.components.DialogButton
import com.atlanyuey.nhentai.ui.components.GlassCircleButton
import com.atlanyuey.nhentai.ui.components.LocalBottomBarHeight
import com.atlanyuey.nhentai.ui.components.LocalOverlays
import com.atlanyuey.nhentai.ui.components.NavHost
import com.atlanyuey.nhentai.ui.components.Navigator
import com.atlanyuey.nhentai.ui.components.OverlayController
import com.atlanyuey.nhentai.ui.components.OverlayHost
import com.atlanyuey.nhentai.ui.components.AppIcon
import com.atlanyuey.nhentai.ui.components.Txt
import com.atlanyuey.nhentai.ui.glass.LiquidBottomTab
import com.atlanyuey.nhentai.ui.glass.LiquidBottomTabs
import com.atlanyuey.nhentai.ui.theme.AppTheme
import com.atlanyuey.nhentai.ui.theme.Icons
import com.atlanyuey.nhentai.ui.theme.Type
import com.kyant.backdrop.backdrops.layerBackdrop
import com.kyant.backdrop.backdrops.rememberLayerBackdrop

private class TabInfo(val title: String, val icon: ImageVector)

/** Navigation stacks of the tabs; they live as long as the activity. */
class Tabs {
    val home = Navigator(HomeScreen())
    val favorites = Navigator(FavoritesScreen())
    val history = Navigator(HistoryScreen())
    val more = Navigator(MoreScreen())
    val all = listOf(home, favorites, history, more)
}


/** Tabs with the iOS 26 floating glass tab bar. Search is on the Home page. */
@Composable
fun RootView(
    linkedGallery: androidx.compose.runtime.MutableState<Int?>,
    tabs: Tabs = remember { Tabs() },
    initialTab: Int = 0,
    overlays: OverlayController = remember { OverlayController() },
) {
    var selected by rememberSaveable { mutableIntStateOf(initialTab.coerceIn(0, 3)) }
    var lastTab by rememberSaveable { mutableIntStateOf(initialTab.coerceIn(0, 3)) }
    val holder = rememberSaveableStateHolder()
    val backdrop = rememberLayerBackdrop()
    val navigator = tabs.all[selected]
    val showTabBar = !navigator.top.hidesTabBar
    // Large screens: the bar sits left, center or right (automatically on
    // the side of the hand in use); phones keep it centered.
    val configuration = androidx.compose.ui.platform.LocalConfiguration.current
    val large = configuration.smallestScreenWidthDp >= 600
    // Where the bar is; touches on it don't move it.
    var barBounds by remember { mutableStateOf(Rect.Zero) }
    // Scrolling a list down slides the tab bar away.
    val barsHidden = BarsState.hiding
    val tabsAway by animateFloatAsState(if (barsHidden) 1f else 0f, label = "tabsAway")
    LaunchedEffect(selected) { BarsState.show() }
    val tracksHand by rememberUpdatedState(large && showTabBar && !barsHidden && AppSettings.followHand)
    val position = if (AppSettings.followHand) {
        when (HandTracker.side) {
            HandTracker.Side.Leading -> TabBarPosition.Leading
            HandTracker.Side.Center -> TabBarPosition.Center
            HandTracker.Side.Trailing -> TabBarPosition.Trailing
        }
    } else {
        AppSettings.tabBarPosition
    }
    // The bar slides across at the follow speed.
    val bias by animateFloatAsState(
        when {
            !large -> 0f
            position == TabBarPosition.Leading -> -1f
            position == TabBarPosition.Trailing -> 1f
            else -> 0f
        },
        tween(AppSettings.followSpeed.durationMillis, easing = FastOutSlowInEasing),
        label = "barPosition",
    )
    val barAlignment = BiasAlignment(bias, 1f)

    val items = listOf(
        TabInfo(tr("Home"), Icons.Home),
        TabInfo(tr("Favorites"), Icons.Heart),
        TabInfo(tr("History"), Icons.Clock),
        TabInfo(tr("Me"), Icons.PersonCircleOutline),
    )

    fun select(index: Int) {
        if (index == selected) {
            tabs.all[index].popToRoot()
        } else {
            selected = index
            lastTab = index
        }
    }

    // Links opened from outside (nhentai.net/g/<id>).
    val linked = linkedGallery.value
    LaunchedEffect(linked) {
        if (linked != null) {
            tabs.all[selected].push(GalleryScreen(linked, null))
            linkedGallery.value = null
        }
    }
    ClipboardLinks(overlays) { id -> tabs.all[selected].push(GalleryScreen(id, null)) }

    CompositionLocalProvider(
        LocalOverlays provides overlays,
        LocalBottomBarHeight provides if (showTabBar) 86.dp else 0.dp,
    ) {
        Box(
            Modifier
                .fillMaxSize()
                .background(AppTheme.colors.background)
                .pointerInput(Unit) {
                    // Which side the screen is touched on (tab bar position).
                    awaitPointerEventScope {
                        while (true) {
                            val event = awaitPointerEvent(PointerEventPass.Initial)
                            if (event.type == PointerEventType.Press && size.width > 0 && tracksHand) {
                                event.changes.firstOrNull()
                                    ?.takeUnless { barBounds.inflate(10.dp.toPx()).contains(it.position) }
                                    ?.let { HandTracker.record(it.position.x / size.width, AppSettings.followSpeed.touches) }
                            }
                        }
                    }
                },
        ) {
            Box(Modifier.fillMaxSize().layerBackdrop(backdrop)) {
                holder.SaveableStateProvider("tab$selected") {
                    NavHost(navigator)
                }
            }
            AnimatedVisibility(
                visible = showTabBar,
                modifier = Modifier.align(barAlignment),
                enter = fadeIn() + slideInVertically { it / 2 },
                exit = fadeOut() + slideOutVertically { it / 2 },
            ) {
                // The tabs only (search is on the Home page). Scrolling a list
                // down slides them away; their space doesn't change.
                LiquidBottomTabs(
                    selectedTabIndex = { lastTab },
                    onTabSelected = { select(it) },
                    backdrop = backdrop,
                    tabsCount = items.size,
                    modifier = Modifier
                        .navigationBarsPadding()
                        .padding(start = 16.dp, end = 16.dp, bottom = 8.dp)
                        .then(if (large) Modifier.width(366.dp) else Modifier.widthIn(max = 420.dp))
                        .onGloballyPositioned { barBounds = it.boundsInRoot() }
                        .away(tabsAway),
                ) {
                    items.forEachIndexed { index, item ->
                        LiquidBottomTab({ select(index) }) {
                            AppIcon(item.icon, null, size = 24.dp)
                            Txt(item.title, style = Type.caption2.copy(fontWeight = FontWeight.Medium), maxLines = 1)
                        }
                    }
                }
            }
            OverlayHost(overlays, backdrop)
        }
    }
}

/** Offers to open a gallery link found on the clipboard (once per link). */
@Composable
private fun ClipboardLinks(overlays: OverlayController, open: (Int) -> Unit) {
    val context = LocalContext.current
    val title = tr("Open Gallery?")
    val openLabel = tr("Open")
    val cancel = tr("Cancel")
    val messageFormat = "The clipboard contains a link to gallery #%lld."
    val message = { id: Int -> com.atlanyuey.nhentai.core.L10n.string(messageFormat, id) }
    LifecycleEventEffect(Lifecycle.Event.ON_RESUME) {
        if (!AppSettings.detectClipboard) return@LifecycleEventEffect
        val clipboard = context.getSystemService(ClipboardManager::class.java)
        val text = clipboard.primaryClip?.getItemAt(0)?.coerceToText(context)?.toString() ?: return@LifecycleEventEffect
        if (!text.contains("nhentai.net/g/")) return@LifecycleEventEffect
        val id = Regex("/g/(\\d+)").find(text)?.groupValues?.get(1)?.toIntOrNull() ?: return@LifecycleEventEffect
        val prefs = context.getSharedPreferences("settings", android.content.Context.MODE_PRIVATE)
        if (prefs.getInt("lastClipboardGallery", 0) == id) return@LifecycleEventEffect
        prefs.edit().putInt("lastClipboardGallery", id).apply()
        overlays.alert(
            title,
            message(id),
            listOf(DialogButton(cancel, ButtonRole.Cancel), DialogButton(openLabel, ButtonRole.Preferred) { open(id) }),
        )
    }
}

/** Slides a bar part down and out of sight ([fraction] 1 = gone). */
private fun Modifier.away(fraction: Float) = graphicsLayer {
    alpha = 1f - fraction
    translationY = fraction * (size.height + 40.dp.toPx())
}
