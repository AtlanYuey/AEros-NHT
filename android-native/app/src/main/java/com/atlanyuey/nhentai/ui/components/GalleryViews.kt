package com.atlanyuey.nhentai.ui.components

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.staggeredgrid.LazyStaggeredGridScope
import androidx.compose.foundation.lazy.staggeredgrid.LazyStaggeredGridState
import androidx.compose.foundation.lazy.staggeredgrid.LazyVerticalStaggeredGrid
import androidx.compose.foundation.lazy.staggeredgrid.StaggeredGridCells
import androidx.compose.foundation.lazy.staggeredgrid.StaggeredGridItemSpan
import androidx.compose.foundation.lazy.staggeredgrid.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.runtime.Composable
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import coil3.compose.AsyncImage
import coil3.request.ImageRequest
import coil3.size.Dimension
import coil3.size.Size
import com.atlanyuey.nhentai.core.AppSettings
import com.atlanyuey.nhentai.core.Downloads
import com.atlanyuey.nhentai.core.GalleryFeed
import com.atlanyuey.nhentai.core.GalleryItem
import com.atlanyuey.nhentai.core.GalleryLanguage
import com.atlanyuey.nhentai.core.GalleryListStyle
import com.atlanyuey.nhentai.core.NHHost
import com.atlanyuey.nhentai.core.TagName
import com.atlanyuey.nhentai.core.TagStore
import com.atlanyuey.nhentai.core.tr
import com.atlanyuey.nhentai.screens.GalleryScreen
import com.atlanyuey.nhentai.ui.theme.AppTheme
import com.atlanyuey.nhentai.ui.theme.Icons
import com.atlanyuey.nhentai.ui.theme.Type
import com.kyant.shapes.Capsule

// MARK: - Images

/** An image from the network (disk cached), decoded at [targetWidth]. */
@Composable
fun RemoteImage(
    url: Any?,
    modifier: Modifier = Modifier,
    contentScale: ContentScale = ContentScale.Crop,
    targetWidth: Dp? = 400.dp,
    blur: Boolean = false,
    /** Where to load the image from when [url] fails (asked only then). */
    fallback: (() -> Any?)? = null,
) {
    val context = LocalContext.current
    val density = LocalDensity.current
    val placeholder = AppTheme.colors.quaternaryFill
    var failed by remember(url) { mutableStateOf(false) }
    val data = if (failed) fallback?.invoke() ?: url else url
    val request = ImageRequest.Builder(context)
        .data(data)
        .apply {
            targetWidth?.let { size(Size(Dimension(with(density) { it.roundToPx() }), Dimension.Undefined)) }
        }
        .build()
    AsyncImage(
        model = request,
        contentDescription = null,
        contentScale = contentScale,
        onError = { if (!failed && fallback != null) failed = true },
        modifier = modifier
            .background(placeholder)
            .then(if (blur) Modifier.blur(18.dp) else Modifier),
    )
}

@Composable
fun LanguageBadge(language: GalleryLanguage, modifier: Modifier = Modifier) {
    Txt(
        language.badge,
        modifier
            .clip(Capsule())
            .background(Color.Black.copy(alpha = 0.45f))
            .padding(horizontal = 6.dp, vertical = 2.dp),
        style = Type.caption2.copy(fontWeight = FontWeight.Bold),
        color = Color.White,
    )
}

/** A gallery cover with rounded corners and the language badge. */
@Composable
fun CoverView(
    item: GalleryItem,
    modifier: Modifier = Modifier,
    aspectRatio: Float? = null,
    cornerRadius: Dp = 12.dp,
    targetWidth: Dp = 360.dp,
    overlay: @Composable (Modifier) -> Unit = {},
) {
    val shape = RoundedCornerShape(cornerRadius)
    Box(
        modifier
            .fillMaxWidth()
            .aspectRatio(aspectRatio ?: item.aspectRatio.coerceIn(0.4f, 2f))
            .clip(shape)
            .border(0.5.dp, AppTheme.colors.label.copy(alpha = 0.08f), shape),
    ) {
        RemoteImage(item.thumbUrl, Modifier.fillMaxSize(), targetWidth = targetWidth, blur = AppSettings.blurCovers) {
            // Without the network, a downloaded gallery shows its first page.
            Downloads.localFile(item.id, 0)
        }
        item.language?.let { LanguageBadge(it, Modifier.padding(6.dp).align(Alignment.TopStart)) }
        overlay(Modifier.align(Alignment.BottomCenter))
        LocalCoverBadge.current?.invoke(this, item)
    }
}

/** Drawn over a gallery's cover in cards and rows (download or reading progress). */
val LocalCoverBadge = compositionLocalOf<(@Composable BoxScope.(GalleryItem) -> Unit)?> { null }

/** More items for a gallery's long-press menu (Delete in History and Downloads). */
val LocalGalleryMenuItems = compositionLocalOf<((GalleryItem) -> List<MenuItem>)?> { null }

// MARK: - Cards

fun galleryLink(id: Int) = NHHost.gallery(id)

fun Context.shareLink(url: String, title: String? = null) {
    val intent = Intent(Intent.ACTION_SEND).apply {
        type = "text/plain"
        putExtra(Intent.EXTRA_TEXT, url)
        title?.let { putExtra(Intent.EXTRA_SUBJECT, it) }
    }
    startActivity(Intent.createChooser(intent, null).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
}

fun Context.copyText(text: String) {
    val clipboard = getSystemService(ClipboardManager::class.java)
    clipboard.setPrimaryClip(ClipData.newPlainText("link", text))
}

/** Share / Copy Link, shown when a gallery is long-pressed. */
fun galleryMenu(context: Context, item: GalleryItem, share: String, copy: String) = listOf(
    listOf(
        MenuItem(share, Icons.Share) { context.shareLink(galleryLink(item.id), item.title) },
        MenuItem(copy, Icons.Link) { context.copyText(galleryLink(item.id)) },
    ),
)

/** Tapping opens the gallery; a long press shows the gallery menu. */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun Modifier.galleryClick(item: GalleryItem): Modifier {
    val navigator = LocalNavigator.current
    val overlays = LocalOverlays.current
    val context = LocalContext.current
    val anchor = rememberAnchor()
    val share = tr("Share")
    val copy = tr("Copy Link")
    val extra = LocalGalleryMenuItems.current
    return this
        .anchor(anchor)
        .combinedClickable(
            onClick = { navigator.push(GalleryScreen(item.id, item)) },
            onLongClick = {
                val more = extra?.invoke(item)?.takeIf { it.isNotEmpty() }?.let { listOf(it) } ?: emptyList()
                overlays.menu(anchor.bounds, more + galleryMenu(context, item, share, copy))
            },
        )
}

/** Card used by the grid / waterfall styles. */
@Composable
fun GalleryCard(item: GalleryItem, style: GalleryListStyle, modifier: Modifier = Modifier) {
    Column(modifier.galleryClick(item), verticalArrangement = Arrangement.spacedBy(6.dp)) {
        when (style) {
            GalleryListStyle.Grid -> {
                CoverView(item, aspectRatio = 3f / 4f)
                Txt(
                    item.prettyTitle,
                    Modifier.fillMaxWidth().heightIn(min = 34.dp),
                    style = Type.footnote.copy(fontWeight = FontWeight.Medium),
                    maxLines = 2,
                )
            }
            GalleryListStyle.Compact -> CoverView(item) { m -> CompactOverlay(item, m) }
            else -> {
                CoverView(item)
                Txt(item.prettyTitle, style = Type.footnote.copy(fontWeight = FontWeight.Medium), maxLines = 2)
                if (AppSettings.showTags) CardTagLine(item.tagIds, overlay = false)
            }
        }
    }
}

/** Tags and title over the bottom of the cover (compact waterfall). */
@Composable
private fun CompactOverlay(item: GalleryItem, modifier: Modifier) {
    Column(
        modifier
            .fillMaxWidth()
            .background(Brush.verticalGradient(listOf(Color.Transparent, Color.Black.copy(alpha = 0.55f), Color.Black.copy(alpha = 0.8f))))
            .padding(start = 10.dp, end = 10.dp, top = 36.dp, bottom = 10.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        if (AppSettings.showTags) CardTagLine(item.tagIds, overlay = true)
        Txt(item.prettyTitle, style = Type.footnote.copy(fontWeight = FontWeight.SemiBold), color = Color.White, maxLines = 2)
    }
}

/** One line of tag chips; chips that don't fit are left out. */
@Composable
fun CardTagLine(ids: List<Int>, overlay: Boolean) {
    val tags: List<TagName> = TagStore.cardTags(ids)
    if (tags.isEmpty()) return
    val colors = AppTheme.colors
    FittingRow(spacing = 5.dp) {
        tags.forEach { tag ->
            Txt(
                TagStore.displayName(tag.name, tag.type),
                Modifier
                    .clip(Capsule())
                    .background(if (overlay) Color.White.copy(alpha = 0.2f) else colors.tertiaryFill)
                    .padding(horizontal = 7.dp, vertical = 3.dp),
                style = Type.caption2.copy(fontWeight = FontWeight.Medium),
                color = if (overlay) Color.White else colors.secondaryLabel,
                maxLines = 1,
            )
        }
    }
}

/** Lays children out in one row and leaves out the ones that don't fit. */
@Composable
fun FittingRow(spacing: Dp, content: @Composable () -> Unit) {
    Layout(content, Modifier.fillMaxWidth()) { measurables, constraints ->
        val gap = spacing.roundToPx()
        val placeables = measurables.map { it.measure(constraints.copy(minWidth = 0, maxWidth = Int.MAX_VALUE)) }
        var x = 0
        var height = 0
        val shown = placeables.takeWhile { p ->
            val next = if (x == 0) p.width else x + gap + p.width
            (next <= constraints.maxWidth).also { fits ->
                if (fits) {
                    x = next
                    height = maxOf(height, p.height)
                }
            }
        }
        layout(constraints.maxWidth, height) {
            var px = 0
            shown.forEach {
                it.place(px, 0)
                px += it.width + gap
            }
        }
    }
}

/** Row used by the list style and history. */
@Composable
fun GalleryRow(item: GalleryItem, modifier: Modifier = Modifier, subtitle: String? = null) {
    Row(
        modifier.fillMaxWidth().galleryClick(item).padding(vertical = 6.dp),
        horizontalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        CoverView(item, Modifier.width(84.dp), aspectRatio = 0.72f, cornerRadius = 10.dp, targetWidth = 200.dp)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Txt(item.prettyTitle, style = Type.subheadline.copy(fontWeight = FontWeight.SemiBold), maxLines = 3)
            when {
                subtitle != null -> Txt(subtitle, style = Type.footnote, color = AppTheme.colors.secondaryLabel)
                item.numPages > 0 -> Txt(tr("%lld pages", item.numPages), style = Type.footnote, color = AppTheme.colors.secondaryLabel)
            }
        }
    }
}

// MARK: - Collections

/** Number of columns for the list style, the width and the orientation. */
@Composable
fun galleryColumns(width: Dp, style: GalleryListStyle = AppSettings.listStyle, spacing: Dp = 12.dp): Int {
    val configuration = LocalConfiguration.current
    val landscape = configuration.screenWidthDp > configuration.screenHeightDp
    val available = (width - 32.dp).value
    if (available <= 0f) return 2
    return AppSettings.cardSize(landscape).columns(available, style.preferredCardWidth, spacing.value)
}

/**
 * A scrolling gallery list in the user's style (waterfall, compact
 * waterfall, grid or list) with full-width [header] content.
 */
@Composable
fun GalleryGrid(
    items: List<GalleryItem>,
    state: LazyStaggeredGridState,
    contentPadding: PaddingValues,
    modifier: Modifier = Modifier,
    onItemShown: (Int) -> Unit = {},
    header: LazyStaggeredGridScope.() -> Unit = {},
    footer: LazyStaggeredGridScope.() -> Unit = {},
) {
    GalleryLayout(state, contentPadding, modifier) { style ->
        header()
        galleryItems(items, style, onItemShown)
        footer()
    }
}

/**
 * The grid of [GalleryGrid] for screens that lay out their own items
 * (History, with a header for each day): [content] gets the list style.
 */
@Composable
fun GalleryLayout(
    state: LazyStaggeredGridState,
    contentPadding: PaddingValues,
    modifier: Modifier = Modifier,
    content: LazyStaggeredGridScope.(GalleryListStyle) -> Unit,
) {
    val style = AppSettings.listStyle
    val topSlack = with(androidx.compose.ui.platform.LocalDensity.current) { 60.dp.roundToPx() }
    BoxWithConstraints(modifier.fillMaxSize()) {
        val columns = galleryColumns(maxWidth, style)
        LazyVerticalStaggeredGrid(
            columns = StaggeredGridCells.Fixed(columns),
            state = state,
            contentPadding = PaddingValues(
                start = 16.dp, end = 16.dp,
                top = contentPadding.calculateTopPadding(),
                bottom = contentPadding.calculateBottomPadding(),
            ),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalItemSpacing = if (style == GalleryListStyle.Compact) 12.dp else 16.dp,
            modifier = Modifier
                .fillMaxSize()
                .hidesBarsOnScroll { state.firstVisibleItemIndex == 0 && state.firstVisibleItemScrollOffset < topSlack },
        ) {
            content(style)
        }
    }
}

/** Galleries in a [GalleryLayout]: cards, or rows in the list style. */
fun LazyStaggeredGridScope.galleryItems(items: List<GalleryItem>, style: GalleryListStyle, onItemShown: (Int) -> Unit = {}) {
    itemsIndexed(items, key = { _, item -> item.id }) { index, item ->
        androidx.compose.runtime.LaunchedEffect(item.id) { onItemShown(index) }
        if (style == GalleryListStyle.List) GalleryRow(item) else GalleryCard(item, style)
    }
}

/** A full-width item in a [GalleryGrid] (headers, footers). */
fun LazyStaggeredGridScope.fullLine(key: Any? = null, content: @Composable () -> Unit) {
    item(key = key, span = StaggeredGridItemSpan.FullLine) {
        Box(Modifier.padding(horizontal = 0.dp)) { content() }
    }
}

/** Footer of an infinite list: spinner while loading, error with retry. */
fun LazyStaggeredGridScope.feedFooter(feed: GalleryFeed, empty: Pair<String, ImageVector>) {
    fullLine("footer") {
        when {
            !feed.hasLoaded || (feed.isLoading && feed.items.isEmpty()) ->
                Box(Modifier.fillMaxWidth().height(300.dp), contentAlignment = Alignment.Center) {
                    ActivityIndicator(size = 30.dp)
                }
            feed.error != null && feed.items.isEmpty() -> EmptyState(
                icon = Icons.Offline,
                title = tr("Couldn't Load"),
                message = feed.error,
                action = tr("Try Again") to { feed.reload() },
            )
            feed.items.isEmpty() -> EmptyState(icon = empty.second, title = empty.first)
            feed.isLoading -> Box(Modifier.fillMaxWidth().padding(vertical = 24.dp), contentAlignment = Alignment.Center) {
                ActivityIndicator()
            }
            feed.error != null -> Column(
                Modifier.fillMaxWidth().padding(vertical = 24.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                Txt(feed.error ?: "", style = Type.footnote, color = AppTheme.colors.secondaryLabel, align = TextAlign.Center)
                GlassCapsuleButton({ feed.loadMore() }, height = 36.dp) { Txt(tr("Retry"), style = Type.subheadline) }
            }
            else -> Spacer(Modifier.height(8.dp))
        }
    }
}

/** iOS ContentUnavailableView: icon, title, message and an action. */
@Composable
fun EmptyState(
    icon: ImageVector,
    title: String,
    message: String? = null,
    modifier: Modifier = Modifier,
    action: Pair<String, () -> Unit>? = null,
) {
    Column(
        modifier.fillMaxWidth().padding(horizontal = 32.dp, vertical = 60.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        AppIcon(icon, null, tint = AppTheme.colors.secondaryLabel, size = 46.dp)
        Spacer(Modifier.size(2.dp))
        Txt(title, style = Type.title3.copy(fontWeight = FontWeight.Bold), align = TextAlign.Center)
        message?.let { Txt(it, style = Type.subheadline, color = AppTheme.colors.secondaryLabel, align = TextAlign.Center) }
        action?.let { (label, onClick) ->
            Spacer(Modifier.size(6.dp))
            GlassCapsuleButton(onClick, tint = AppTheme.tint, height = 40.dp) {
                Txt(label, style = Type.subheadline.copy(fontWeight = FontWeight.SemiBold), color = Color.White)
            }
        }
    }
}

/** A tag capsule (gallery page). */
@Composable
fun TagChip(name: String, count: Int?, onClick: () -> Unit) {
    val colors = AppTheme.colors
    Row(
        Modifier
            .clip(Capsule())
            .background(colors.tertiaryFill)
            .combinedClickable(onClick = onClick)
            .padding(horizontal = 12.dp, vertical = 7.dp),
        horizontalArrangement = Arrangement.spacedBy(6.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Txt(name, style = Type.subheadline, maxLines = 1)
        if (count != null && count > 0) {
            Txt(compactCount(count), style = Type.caption1, color = colors.secondaryLabel, maxLines = 1)
        }
    }
}

/** 1234 -> 1.2K (locale aware compact notation). */
fun compactCount(value: Int): String {
    val formatter = android.icu.text.CompactDecimalFormat.getInstance(
        java.util.Locale.getDefault(),
        android.icu.text.CompactDecimalFormat.CompactStyle.SHORT,
    )
    return formatter.format(value.toLong())
}
