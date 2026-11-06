package com.atlanyuey.nhentai.ui.components

import androidx.activity.compose.PredictiveBackHandler
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveableStateHolder
import androidx.compose.runtime.setValue
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import java.util.UUID

/** A screen in a navigation stack; it keeps its own state while in the stack. */
abstract class Screen {
    val id: String = UUID.randomUUID().toString()

    /** Work tied to this screen, cancelled when it leaves the stack. */
    val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    /** Hides the tab bar while this screen is on top (the reader). */
    open val hidesTabBar: Boolean get() = false

    @Composable
    abstract fun Content()

    open fun onRemoved() {
        scope.cancel()
    }
}

/** A navigation stack with iOS push / pop transitions. */
class Navigator(root: Screen) {
    val stack = mutableStateListOf(root)

    /** How far the top screen is shown (0 = off to the right, 1 = in place). */
    internal val progress = Animatable(1f)
    internal var pendingRemoval: Screen? by mutableStateOf(null)
    /** The NavHost's coroutine scope (animations need its frame clock). */
    internal var uiScope: CoroutineScope? = null
    private val spec = spring<Float>(dampingRatio = 1f, stiffness = 420f)

    val top: Screen get() = stack.last()
    val canPop: Boolean get() = stack.size > 1

    fun push(screen: Screen) {
        BarsState.show()
        stack.add(screen)
        val scope = uiScope ?: return
        scope.launch {
            progress.snapTo(0f)
            progress.animateTo(1f, spec)
        }
    }

    fun pop() {
        if (!canPop) return
        BarsState.show()
        val scope = uiScope
        if (scope == null) {
            stack.removeAt(stack.lastIndex).also { pendingRemoval = it }.onRemoved()
            return
        }
        scope.launch { finishPop() }
    }

    fun popToRoot() {
        while (stack.size > 2) {
            stack.removeAt(stack.size - 2).onRemoved()
        }
        pop()
    }

    /** Replaces the top screen without animation. */
    fun replace(screen: Screen) {
        val old = stack.removeAt(stack.lastIndex)
        stack.add(screen)
        old.onRemoved()
    }

    internal suspend fun finishPop() {
        progress.animateTo(0f, spec)
        if (stack.size > 1) {
            val removed = stack.removeAt(stack.lastIndex)
            pendingRemoval = removed
            removed.onRemoved()
        }
        progress.snapTo(1f)
    }

    internal fun cancelBack() {
        uiScope?.launch { progress.animateTo(1f, spec) }
    }

    internal suspend fun dragBack(fraction: Float) {
        progress.snapTo(1f - fraction)
    }
}

val LocalNavigator = staticCompositionLocalOf<Navigator> { error("No navigator") }

/**
 * Shows the top of a navigation stack. The screen below stays visible while
 * a screen slides in or out (also during Android's predictive back gesture).
 */
@Composable
fun NavHost(navigator: Navigator, modifier: Modifier = Modifier) {
    val holder = rememberSaveableStateHolder()
    navigator.uiScope = androidx.compose.runtime.rememberCoroutineScope()
    navigator.pendingRemoval?.let {
        holder.removeState(it.id)
        navigator.pendingRemoval = null
    }
    val inTransition by remember(navigator) { derivedStateOf { navigator.progress.value < 1f } }

    CompositionLocalProvider(LocalNavigator provides navigator) {
        BoxWithConstraints(modifier.fillMaxSize()) {
            val width = constraints.maxWidth.toFloat()
            val stack = navigator.stack
            stack.forEachIndexed { index, screen ->
                val isTop = index == stack.lastIndex
                val isUnder = index == stack.lastIndex - 1
                if (isTop || (isUnder && inTransition)) {
                    key(screen.id) {
                        Box(
                            Modifier
                                .fillMaxSize()
                                .graphicsLayer {
                                    val p = navigator.progress.value
                                    translationX = if (isTop) width * (1f - p) else -width * 0.3f * p
                                }
                                .then(if (isTop) Modifier.leadingShadow { navigator.progress.value } else Modifier),
                        ) {
                            holder.SaveableStateProvider(screen.id) { screen.Content() }
                            if (isUnder) {
                                Box(
                                    Modifier
                                        .fillMaxSize()
                                        .graphicsLayer { alpha = 0.14f * navigator.progress.value }
                                        .background(Color.Black),
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    PredictiveBackHandler(enabled = navigator.canPop) { events ->
        try {
            events.collect { event -> navigator.dragBack(event.progress) }
            navigator.finishPop()
        } catch (e: CancellationException) {
            navigator.cancelBack()
            throw e
        }
    }
}

/** The soft shadow on the leading edge of a screen sliding over another. */
private fun Modifier.leadingShadow(progress: () -> Float) = drawWithContent {
    val p = progress()
    if (p < 1f) {
        val width = 16.dp.toPx()
        drawRect(
            Brush.horizontalGradient(
                listOf(Color.Transparent, Color.Black.copy(alpha = 0.12f * (1f - p * 0.5f))),
                startX = -width,
                endX = 0f,
            ),
            topLeft = Offset(-width, 0f),
            size = Size(width, size.height),
        )
    }
    drawContent()
}
