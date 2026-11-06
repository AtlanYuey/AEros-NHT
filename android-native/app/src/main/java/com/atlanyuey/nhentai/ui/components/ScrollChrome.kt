package com.atlanyuey.nhentai.ui.components

import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.input.nestedscroll.NestedScrollConnection
import androidx.compose.ui.input.nestedscroll.NestedScrollSource
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.dp
import com.atlanyuey.nhentai.core.AppSettings

/**
 * Scrolling a list down hides the navigation bar and the tab bar (when
 * Appearance › Hide Bars When Scrolling is on); scrolling up, or reaching
 * the top, shows them again.
 */
object BarsState {
    var hidden by mutableStateOf(false)

    /** Bumped to open the search (the floating search button while the bars are hidden). */
    var searchRequest by mutableIntStateOf(0)

    /** Whether the bars are hidden right now. */
    val hiding: Boolean get() = AppSettings.hideBarsOnScroll && hidden

    fun show() {
        hidden = false
    }
}

/** Hides the bars when this scrolling list goes down; [atTop] tells when it is back at the top. */
@Composable
fun Modifier.hidesBarsOnScroll(atTop: () -> Boolean): Modifier {
    val threshold = with(LocalDensity.current) { 24.dp.toPx() }
    val isAtTop by rememberUpdatedState(atTop)
    val connection = remember(threshold) {
        object : NestedScrollConnection {
            private var travel = 0f

            override fun onPostScroll(consumed: Offset, available: Offset, source: NestedScrollSource): Offset {
                if (!AppSettings.hideBarsOnScroll) return Offset.Zero
                if (isAtTop()) {
                    travel = 0f
                    BarsState.hidden = false
                    return Offset.Zero
                }
                val delta = -consumed.y
                if (delta == 0f) return Offset.Zero
                if ((delta > 0f) != (travel > 0f)) travel = 0f
                travel += delta
                if (travel > threshold) BarsState.hidden = true else if (travel < -threshold) BarsState.hidden = false
                return Offset.Zero
            }
        }
    }
    DisposableEffect(Unit) { onDispose { BarsState.show() } }
    return this.nestedScroll(connection)
}
