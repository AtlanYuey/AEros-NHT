package com.atlanyuey.nhentai.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.isSpecified
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.atlanyuey.nhentai.core.tr
import com.atlanyuey.nhentai.ui.theme.AppTheme
import com.atlanyuey.nhentai.ui.theme.Icons
import com.atlanyuey.nhentai.ui.theme.Type

private val SectionShape = RoundedCornerShape(24.dp)

/** Whether a row is the last one of its section (no separator below). */
private val LocalRowIsLast = staticCompositionLocalOf { false }

/**
 * A settings-style screen: inset grouped sections on the grouped
 * background, under an iOS navigation bar.
 */
@Composable
fun GroupedListScreen(
    title: String,
    state: LazyListState = rememberLazyListState(),
    trailing: @Composable RowScope.() -> Unit = {},
    largeTitle: Boolean = false,
    content: LazyListScope.() -> Unit,
) {
    val colors = AppTheme.colors
    ScreenScaffold(
        title = title,
        background = colors.groupedBackground,
        showTitle = { !largeTitle || state.firstVisibleItemIndex > 0 || state.firstVisibleItemScrollOffset > 40 },
        trailing = trailing,
    ) { padding ->
        LazyColumn(
            Modifier.fillMaxSize(),
            state = state,
            contentPadding = PaddingValues(top = padding.calculateTopPadding() + 4.dp, bottom = padding.calculateBottomPadding() + 16.dp),
        ) {
            if (largeTitle) item { LargeTitle(title) }
            content()
        }
    }
}

/** An inset grouped section with optional header and footer. */
fun LazyListScope.section(
    header: String? = null,
    footer: (@Composable () -> Unit)? = null,
    key: Any? = null,
    rows: @Composable ColumnScope.() -> Unit,
) {
    item(key = key) {
        Column(Modifier.fillMaxWidth().padding(horizontal = 16.dp)) {
            if (header != null) {
                Txt(
                    tr(header),
                    Modifier.padding(start = 16.dp, end = 16.dp, top = 18.dp, bottom = 8.dp),
                    style = Type.footnote,
                    color = AppTheme.colors.secondaryLabel,
                )
            } else {
                Spacer(Modifier.height(20.dp))
            }
            Column(
                Modifier
                    .fillMaxWidth()
                    .clip(SectionShape)
                    .background(AppTheme.colors.secondaryGroupedBackground),
                content = rows,
            )
            if (footer != null) {
                Box(Modifier.padding(start = 16.dp, end = 16.dp, top = 8.dp)) {
                    CompositionLocalProvider { footer() }
                }
            }
        }
    }
}

@Composable
fun FooterText(text: String, color: Color = Color.Unspecified) {
    Txt(text, style = Type.footnote, color = if (color.isSpecified) color else AppTheme.colors.secondaryLabel)
}

/** A colored rounded-square icon, like the ones in iOS Settings. */
@Composable
fun SettingsIcon(icon: ImageVector, color: Color) {
    Box(
        Modifier.size(30.dp).clip(RoundedCornerShape(8.dp)).background(color),
        contentAlignment = Alignment.Center,
    ) {
        AppIcon(icon, null, tint = Color.White, size = 18.dp)
    }
}

/**
 * A list row: leading content, title / subtitle, trailing content and an
 * optional chevron; separators are inset to the title.
 */
@Composable
fun ListRow(
    title: String,
    modifier: Modifier = Modifier,
    subtitle: String? = null,
    leading: (@Composable () -> Unit)? = null,
    value: String? = null,
    titleColor: Color = Color.Unspecified,
    chevron: Boolean = false,
    last: Boolean = false,
    minHeight: Dp = 52.dp,
    onClick: (() -> Unit)? = null,
    trailing: (@Composable RowScope.() -> Unit)? = null,
) {
    val colors = AppTheme.colors
    Column(
        modifier
            .fillMaxWidth()
            .then(if (onClick != null) Modifier.clickable(onClick = onClick) else Modifier),
    ) {
        Row(
            Modifier.fillMaxWidth().heightIn(min = minHeight).padding(start = 16.dp, end = 14.dp, top = 8.dp, bottom = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            leading?.invoke()
            Column(Modifier.weight(1f)) {
                Txt(title, style = Type.body, color = if (titleColor.isSpecified) titleColor else colors.label)
                if (subtitle != null) {
                    Txt(subtitle, style = Type.footnote, color = colors.secondaryLabel)
                }
            }
            if (value != null) {
                Txt(value, style = Type.body, color = colors.secondaryLabel, maxLines = 1, align = TextAlign.End)
            }
            trailing?.invoke(this)
            if (chevron) {
                AppIcon(Icons.ChevronForward, null, tint = colors.tertiaryLabel, size = 14.dp)
            }
        }
        if (!last) {
            Box(
                Modifier
                    .fillMaxWidth()
                    .padding(start = if (leading != null) 58.dp else 16.dp)
                    .height(0.5.dp)
                    .background(colors.separator),
            )
        }
    }
}

/** The inset separator between rows that are not [ListRow]s. */
@Composable
fun RowSeparator(inset: Dp = 16.dp) {
    Box(Modifier.fillMaxWidth().padding(start = inset).height(0.5.dp).background(AppTheme.colors.separator))
}

/** A row with a glass switch. */
@Composable
fun ToggleRow(title: String, checked: Boolean, onChange: (Boolean) -> Unit, last: Boolean = false, subtitle: String? = null) {
    ListRow(title, subtitle = subtitle, last = last, onClick = { onChange(!checked) }) {
        GlassToggle(checked, onChange)
    }
}

/** A row that opens a menu of options (iOS menu picker). */
@Composable
fun <T> PickerRow(
    title: String,
    options: List<T>,
    selected: T,
    label: @Composable (T) -> String,
    onSelect: (T) -> Unit,
    last: Boolean = false,
    leading: (@Composable () -> Unit)? = null,
) {
    val anchor = rememberAnchor()
    val overlays = LocalOverlays.current
    val labels = options.map { label(it) }
    val current = label(selected)
    ListRow(
        title,
        modifier = Modifier.anchor(anchor),
        leading = leading,
        last = last,
        onClick = {
            overlays.menu(
                anchor.bounds,
                listOf(options.mapIndexed { i, option -> MenuItem(labels[i], checked = option == selected) { onSelect(option) } }),
            )
        },
    ) {
        Txt(current, style = Type.body, color = AppTheme.colors.secondaryLabel, maxLines = 1)
        AppIcon(Icons.ChevronExpand, null, tint = AppTheme.colors.tertiaryLabel, size = 16.dp)
    }
}

/** A plain centered text button row (destructive or tinted). */
@Composable
fun ButtonRow(title: String, onClick: () -> Unit, destructive: Boolean = false, last: Boolean = false, enabled: Boolean = true) {
    val colors = AppTheme.colors
    ListRow(
        title,
        titleColor = when {
            !enabled -> colors.tertiaryLabel
            destructive -> colors.red
            else -> AppTheme.tint
        },
        last = last,
        onClick = if (enabled) onClick else null,
    )
}
