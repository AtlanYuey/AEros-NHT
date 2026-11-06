package com.atlanyuey.nhentai.screens

import android.text.format.DateUtils
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.asPaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.atlanyuey.nhentai.core.DownloadRecord
import com.atlanyuey.nhentai.core.Downloads
import com.atlanyuey.nhentai.core.GalleryComment
import com.atlanyuey.nhentai.core.GalleryDetail
import com.atlanyuey.nhentai.core.GalleryItem
import com.atlanyuey.nhentai.core.HistoryStore
import com.atlanyuey.nhentai.core.NHClient
import com.atlanyuey.nhentai.core.Session
import com.atlanyuey.nhentai.core.TagGroup
import com.atlanyuey.nhentai.core.TagStore
import com.atlanyuey.nhentai.core.tr
import com.atlanyuey.nhentai.ui.components.ActivityIndicator
import com.atlanyuey.nhentai.ui.components.AppIcon
import com.atlanyuey.nhentai.ui.components.ButtonRole
import com.atlanyuey.nhentai.ui.components.CoverView
import com.atlanyuey.nhentai.ui.components.DialogButton
import com.atlanyuey.nhentai.ui.components.EmptyState
import com.atlanyuey.nhentai.ui.components.GlassCircleButton
import com.atlanyuey.nhentai.ui.components.LocalNavigator
import com.atlanyuey.nhentai.ui.components.LocalOverlays
import com.atlanyuey.nhentai.ui.components.NAV_BAR_HEIGHT
import com.atlanyuey.nhentai.ui.components.ProminentButton
import com.atlanyuey.nhentai.ui.components.PullToRefresh
import com.atlanyuey.nhentai.ui.components.RemoteImage
import com.atlanyuey.nhentai.ui.components.Screen
import com.atlanyuey.nhentai.ui.components.ScreenScaffold
import com.atlanyuey.nhentai.ui.components.SectionTitle
import com.atlanyuey.nhentai.ui.components.TagChip
import com.atlanyuey.nhentai.ui.components.TextButton
import com.atlanyuey.nhentai.ui.components.Txt
import com.atlanyuey.nhentai.ui.components.compactCount
import com.atlanyuey.nhentai.ui.components.glass
import com.atlanyuey.nhentai.ui.components.shareLink
import com.atlanyuey.nhentai.ui.theme.AppTheme
import com.atlanyuey.nhentai.ui.theme.Icons
import com.atlanyuey.nhentai.ui.theme.Type
import com.kyant.shapes.Capsule
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

// MARK: - Reader source

data class ReaderPage(val index: Int, val url: Any?, val aspectRatio: Float)

/** What the reader shows: a gallery's pages (local files when downloaded). */
class ReaderSource(
    val id: Int,
    val title: String,
    val pages: List<ReaderPage>,
    val shareUrl: String,
    val item: GalleryItem,
    val numPages: Int,
) {
    companion object {
        fun from(detail: GalleryDetail) = ReaderSource(
            id = detail.id,
            title = detail.displayTitle,
            pages = detail.pages.mapIndexed { index, page ->
                ReaderPage(index, Downloads.localFile(detail.id, index) ?: page.imageUrl, page.aspectRatio)
            },
            shareUrl = detail.url,
            item = detail.asItem,
            numPages = detail.numPages,
        )

        fun from(record: DownloadRecord) = ReaderSource(
            id = record.id,
            title = record.title,
            pages = record.pages.mapIndexed { index, page ->
                val ratio = if (page.width > 0 && page.height > 0) page.width.toFloat() / page.height else 0.7f
                ReaderPage(index, Downloads.localFile(record.id, index) ?: page.remote, ratio)
            },
            shareUrl = com.atlanyuey.nhentai.core.NHHost.gallery(record.id),
            item = record.item,
            numPages = record.pages.size,
        )
    }
}

// MARK: - Gallery page

class GalleryScreen(private val galleryId: Int, private val preview: GalleryItem?) : Screen() {
    private var detail by mutableStateOf<GalleryDetail?>(null)
    private var error by mutableStateOf<String?>(null)
    private val comments = mutableStateListOf<GalleryComment>()
    private var isFavorited by mutableStateOf(false)
    private var numFavorites by mutableStateOf(0)
    private var toggling by mutableStateOf(false)
    private var pulling by mutableStateOf(false)
    private val list = LazyListState()

    private val item: GalleryItem? get() = preview ?: detail?.asItem

    private suspend fun load() {
        error = null
        try {
            val loaded = NHClient.gallery(galleryId)
            val first = detail == null
            detail = loaded
            isFavorited = loaded.isFavorited ?: false
            numFavorites = loaded.numFavorites
            if (first) HistoryStore.record(loaded)
        } catch (e: Exception) {
            if (detail == null) error = e.localizedMessage
        }
        runCatching { NHClient.comments(galleryId) }.getOrNull()?.let {
            comments.clear()
            comments.addAll(it)
        }
        pulling = false
    }

    private fun toggleFavorite(onError: (String) -> Unit) {
        if (toggling) return
        toggling = true
        val target = !isFavorited
        isFavorited = target
        scope.launch {
            try {
                val result = NHClient.setFavorite(galleryId, target)
                isFavorited = result.favorited ?: target
                numFavorites = result.numFavorites ?: numFavorites
            } catch (e: Exception) {
                isFavorited = !target
                onError(e.localizedMessage ?: "")
            }
            toggling = false
        }
    }

    @Composable
    override fun Content() {
        val context = LocalContext.current
        LaunchedEffect(Unit) { if (detail == null) load() }
        ScreenScaffold(
            title = detail?.displayTitle ?: preview?.title,
            showTitle = { list.firstVisibleItemIndex > 1 },
            trailing = {
                detail?.let { d ->
                    GlassCircleButton(Icons.Share, tr("Share"), onClick = { context.shareLink(d.url, d.displayTitle) })
                }
            },
        ) { padding ->
            PullToRefresh(pulling, { pulling = true; scope.launch { load() } }, topInset = padding.calculateTopPadding()) {
                LazyColumn(
                    Modifier.fillMaxSize(),
                    state = list,
                    contentPadding = PaddingValues(bottom = padding.calculateBottomPadding() + 24.dp),
                ) {
                    item("header") { Header() }
                    val d = detail
                    if (d != null) {
                        item("actions") { Actions(d) }
                        item("info") { InfoStrip(d, numFavorites) }
                        item("tags") { TagsSection(d) }
                        item("pages") { PreviewSection(d) }
                        if (d.related.isNotEmpty()) {
                            item("relatedTitle") { SectionTitle(tr("More Like This")) }
                            item("related") { Box(Modifier.padding(horizontal = 16.dp)) { PopularRow(d.related) } }
                        }
                        item("comments") { CommentsPreview(d) }
                    } else if (error != null) {
                        item("error") {
                            EmptyState(
                                Icons.Offline, tr("Couldn't Load"), error,
                                action = tr("Try Again") to { scope.launch { load() } },
                            )
                        }
                    } else {
                        item("loading") {
                            Box(Modifier.fillMaxWidth().padding(top = 60.dp), contentAlignment = Alignment.Center) {
                                ActivityIndicator(size = 30.dp)
                            }
                        }
                    }
                }
            }
        }
    }

    @Composable
    private fun Header() {
        val navigator = LocalNavigator.current
        val top = WindowInsets.statusBars.asPaddingValues().calculateTopPadding() + NAV_BAR_HEIGHT.dp
        BoxWithConstraints(Modifier.fillMaxWidth()) {
            val wide = maxWidth > 600.dp
            // Blurred cover behind the header (a tiny image scaled up is
            // blurry on every Android version; RenderEffect smooths it more).
            Box(Modifier.matchParentSize()) {
                RemoteImage(
                    item?.thumbUrl,
                    Modifier.fillMaxSize().blur(30.dp),
                    contentScale = ContentScale.Crop,
                    targetWidth = 12.dp,
                )
                Box(
                    Modifier
                        .fillMaxSize()
                        .background(
                            Brush.verticalGradient(
                                0f to Color.Black.copy(alpha = 0.1f),
                                0.55f to AppTheme.colors.background.copy(alpha = 0.35f),
                                1f to AppTheme.colors.background,
                            ),
                        ),
                )
            }
            Row(
                Modifier.fillMaxWidth().padding(start = 16.dp, end = 16.dp, top = top + 12.dp),
                verticalAlignment = Alignment.Bottom,
                horizontalArrangement = Arrangement.spacedBy(18.dp),
            ) {
                Box(Modifier.width(if (wide) 200.dp else 132.dp).shadow(14.dp, RoundedCornerShape(14.dp))) {
                    val cover = item
                    if (cover != null) {
                        CoverView(cover, cornerRadius = 14.dp, targetWidth = 500.dp)
                    } else {
                        Box(Modifier.fillMaxWidth().height(180.dp).clip(RoundedCornerShape(14.dp)).background(AppTheme.colors.quaternaryFill))
                    }
                }
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    SelectionContainer {
                        Txt(
                            detail?.displayTitle ?: preview?.title ?: "",
                            style = if (wide) Type.title2.copy(fontWeight = FontWeight.SemiBold) else Type.title3,
                        )
                    }
                    detail?.subtitle?.let {
                        Txt(it, style = Type.subheadline, color = AppTheme.colors.secondaryLabel, maxLines = 3)
                    }
                    detail?.let { d ->
                        val artists = d.tags(TagGroup.Artist) + d.tags(TagGroup.Group)
                        artists.firstOrNull()?.let { first ->
                            Txt(
                                artists.joinToString(", ") { it.name },
                                Modifier.clickable { navigator.push(SearchResultsScreen(first.query, first.name)) },
                                style = Type.subheadline.copy(fontWeight = FontWeight.SemiBold),
                                color = AppTheme.tint,
                                maxLines = 2,
                            )
                        }
                    }
                }
            }
        }
    }

    @Composable
    private fun Actions(d: GalleryDetail) {
        val navigator = LocalNavigator.current
        val overlays = LocalOverlays.current
        val lastPage = HistoryStore.lastReadPage(d.id) ?: 0
        val deleteTitle = tr("Delete the downloaded pages?")
        val deleteLabel = tr("Delete Download")
        val errorTitle = tr("Couldn't Update")
        val record = Downloads.record(d.id)
        Row(
            Modifier.fillMaxWidth().padding(start = 16.dp, end = 16.dp, top = 22.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            ProminentButton(
                text = if (lastPage > 0) tr("Resume · %lld", lastPage + 1) else tr("Read"),
                icon = if (lastPage > 0) Icons.Play else Icons.Book,
                onClick = { navigator.push(ReaderScreen(ReaderSource.from(d), lastPage)) },
                modifier = Modifier.weight(1f),
            )
            GlassCircleButton(
                icon = if (isFavorited) Icons.HeartFill else Icons.Heart,
                contentDescription = if (isFavorited) tr("Unfavorite") else tr("Favorite"),
                onClick = {
                    if (Session.isLoggedIn) {
                        toggleFavorite { message -> overlays.alert(errorTitle, message) }
                    } else {
                        navigator.push(LoginScreen())
                    }
                },
                size = 46.dp,
                iconColor = if (isFavorited) AppTheme.colors.pink else AppTheme.tint,
                enabled = !toggling,
            )
            when (record?.state) {
                DownloadRecord.FINISHED -> GlassCircleButton(
                    Icons.CheckCircle, tr("Downloaded"),
                    onClick = {
                        overlays.actionSheet(deleteTitle, null, listOf(DialogButton(deleteLabel, ButtonRole.Destructive) { Downloads.delete(d.id) }))
                    },
                    size = 46.dp, iconColor = AppTheme.colors.green,
                )
                DownloadRecord.DOWNLOADING, DownloadRecord.QUEUED -> ProgressCircle(record.progress) {
                    GlassCircleButton(Icons.Pause, tr("Pause Download"), onClick = { Downloads.pause(d.id) }, size = 46.dp, iconColor = AppTheme.tint, iconSize = 18.dp)
                }
                DownloadRecord.PAUSED, DownloadRecord.FAILED -> ProgressCircle(record.progress) {
                    GlassCircleButton(Icons.Refresh, tr("Resume Download"), onClick = { Downloads.resume(d.id) }, size = 46.dp, iconColor = AppTheme.tint, iconSize = 18.dp)
                }
                else -> GlassCircleButton(Icons.ArrowDown, tr("Download"), onClick = { Downloads.start(d) }, size = 46.dp, iconColor = AppTheme.tint)
            }
        }
    }

    @Composable
    private fun ProgressCircle(progress: Float, content: @Composable () -> Unit) {
        val tint = AppTheme.tint
        Box(contentAlignment = Alignment.Center) {
            content()
            Canvas(Modifier.size(40.dp)) {
                drawArc(
                    tint, startAngle = -90f, sweepAngle = 360f * progress, useCenter = false,
                    style = Stroke(width = 2.5.dp.toPx(), cap = StrokeCap.Round),
                )
            }
        }
    }

    @Composable
    private fun InfoStrip(d: GalleryDetail, favorites: Int) {
        val colors = AppTheme.colors
        val date = d.uploadDate?.let { SimpleDateFormat("yyyy-MM-dd", Locale.ROOT).format(Date(it * 1000)) } ?: "-"
        Column(Modifier.fillMaxWidth().padding(start = 16.dp, end = 16.dp, top = 22.dp)) {
            Box(Modifier.fillMaxWidth().height(0.5.dp).background(colors.separator))
            Row(Modifier.fillMaxWidth().padding(vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
                InfoItem(tr("Pages"), "${d.numPages}")
                Divider()
                InfoItem(tr("Favorites"), compactCount(favorites), Icons.HeartFill)
                Divider()
                InfoItem(tr("Uploaded"), date)
                Divider()
                InfoItem(tr("ID"), "#${d.id}")
            }
            Box(Modifier.fillMaxWidth().height(0.5.dp).background(colors.separator))
        }
    }

    @Composable
    private fun androidx.compose.foundation.layout.RowScope.InfoItem(title: String, value: String, icon: ImageVector? = null) {
        Column(Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Txt(title, style = Type.caption1.copy(fontWeight = FontWeight.Medium), color = AppTheme.colors.secondaryLabel, maxLines = 1)
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                icon?.let { AppIcon(it, null, size = 12.dp) }
                androidx.compose.foundation.text.BasicText(
                    value,
                    style = Type.headline.copy(color = AppTheme.colors.label),
                    maxLines = 1,
                    autoSize = androidx.compose.foundation.text.TextAutoSize.StepBased(minFontSize = 11.sp, maxFontSize = 17.sp),
                )
            }
        }
    }

    @Composable
    private fun Divider() {
        Box(Modifier.width(0.5.dp).height(34.dp).background(AppTheme.colors.separator))
    }

    @OptIn(ExperimentalLayoutApi::class)
    @Composable
    private fun TagsSection(d: GalleryDetail) {
        val navigator = LocalNavigator.current
        val order = listOf(TagGroup.Category, TagGroup.Language, TagGroup.Tag, TagGroup.Parody, TagGroup.Character, TagGroup.Artist, TagGroup.Group)
        val groups = order.filter { d.tags(it).isNotEmpty() }
        if (groups.isEmpty()) return
        Column(Modifier.fillMaxWidth().padding(start = 16.dp, end = 16.dp, top = 18.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            groups.forEach { group ->
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Txt(tr(group.title), style = Type.subheadline.copy(fontWeight = FontWeight.SemiBold), color = AppTheme.colors.secondaryLabel)
                    FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        d.tags(group).forEach { tag ->
                            TagChip(TagStore.displayName(tag.name, tag.type), tag.count) {
                                navigator.push(SearchResultsScreen(tag.query, tag.name))
                            }
                        }
                    }
                }
            }
        }
    }

    @Composable
    private fun PreviewSection(d: GalleryDetail) {
        val navigator = LocalNavigator.current
        BoxWithConstraints(Modifier.fillMaxWidth()) {
            val height = if (maxWidth > 600.dp) 220.dp else 160.dp
            Column {
                SectionTitle(tr("Pages")) {
                    if (d.pages.size > 1) TextButton(tr("See All"), { navigator.push(PagesScreen(d)) })
                }
                LazyRow(contentPadding = PaddingValues(horizontal = 16.dp), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    items(d.pages, key = { it.number }) { page ->
                        Column(
                            Modifier.clickable { navigator.push(ReaderScreen(ReaderSource.from(d), page.number - 1)) },
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(6.dp),
                        ) {
                            RemoteImage(
                                page.thumbUrl,
                                Modifier
                                    .size(width = height * page.aspectRatio.coerceIn(0.5f, 1.5f), height = height)
                                    .clip(RoundedCornerShape(8.dp)),
                                targetWidth = 240.dp,
                            )
                            Txt("${page.number}", style = Type.caption1, color = AppTheme.colors.secondaryLabel)
                        }
                    }
                }
            }
        }
    }

    @Composable
    private fun CommentsPreview(d: GalleryDetail) {
        val navigator = LocalNavigator.current
        Column {
            SectionTitle(tr("Comments")) {
                TextButton(
                    if (comments.isEmpty()) tr("Write") else tr("See All (%lld)", comments.size),
                    { navigator.push(CommentsScreen(d.id, comments.toList())) },
                )
            }
            if (comments.isEmpty()) {
                Txt(tr("No comments yet"), Modifier.padding(horizontal = 20.dp), style = Type.subheadline, color = AppTheme.colors.secondaryLabel)
            } else {
                LazyRow(contentPadding = PaddingValues(horizontal = 16.dp), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    items(comments.take(10), key = { it.id }) { comment ->
                        Box(
                            Modifier
                                .width(300.dp)
                                .clip(RoundedCornerShape(18.dp))
                                .background(AppTheme.colors.quaternaryFill)
                                .padding(14.dp),
                        ) { CommentBubble(comment, maxLines = 5) }
                    }
                }
            }
        }
    }
}

// MARK: - All pages

class PagesScreen(private val detail: GalleryDetail) : Screen() {
    @Composable
    override fun Content() {
        val navigator = LocalNavigator.current
        ScreenScaffold(title = tr("Pages")) { padding ->
            LazyVerticalGrid(
                columns = GridCells.Adaptive(96.dp),
                contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = padding.calculateTopPadding() + 8.dp, bottom = padding.calculateBottomPadding()),
                horizontalArrangement = Arrangement.spacedBy(10.dp),
                verticalArrangement = Arrangement.spacedBy(14.dp),
            ) {
                items(detail.pages, key = { it.number }) { page ->
                    Column(
                        Modifier.clickable { navigator.push(ReaderScreen(ReaderSource.from(detail), page.number - 1)) },
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(4.dp),
                    ) {
                        RemoteImage(
                            page.thumbUrl,
                            Modifier.fillMaxWidth().height(130.dp).clip(RoundedCornerShape(8.dp)),
                            contentScale = ContentScale.Fit,
                            targetWidth = 240.dp,
                        )
                        Txt("${page.number}", style = Type.caption2, color = AppTheme.colors.secondaryLabel)
                    }
                }
            }
        }
    }
}

// MARK: - Comments

@Composable
fun CommentBubble(comment: GalleryComment, maxLines: Int = Int.MAX_VALUE) {
    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        Box(Modifier.size(34.dp).clip(CircleShape).background(AppTheme.colors.quaternaryFill), contentAlignment = Alignment.Center) {
            val avatar = comment.poster?.avatar
            if (avatar != null) {
                RemoteImage(avatar, Modifier.fillMaxSize(), targetWidth = 80.dp)
            } else {
                AppIcon(Icons.PersonCircle, null, tint = AppTheme.colors.secondaryLabel, size = 34.dp)
            }
        }
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Txt(
                    comment.poster?.username ?: tr("Anonymous"),
                    Modifier.weight(1f),
                    style = Type.subheadline.copy(fontWeight = FontWeight.SemiBold),
                    maxLines = 1,
                )
                Txt(
                    DateUtils.getRelativeTimeSpanString(comment.postDate * 1000, System.currentTimeMillis(), DateUtils.MINUTE_IN_MILLIS).toString(),
                    style = Type.caption1,
                    color = AppTheme.colors.secondaryLabel,
                    maxLines = 1,
                )
            }
            Txt(comment.body, style = Type.subheadline, maxLines = maxLines)
        }
    }
}

class CommentsScreen(private val galleryId: Int, initial: List<GalleryComment>) : Screen() {
    private val comments = mutableStateListOf<GalleryComment>().apply { addAll(initial) }
    private var draft by mutableStateOf("")
    private var posting by mutableStateOf(false)
    private var pulling by mutableStateOf(false)

    private suspend fun load() {
        runCatching { NHClient.comments(galleryId) }.getOrNull()?.let {
            comments.clear()
            comments.addAll(it)
        }
        pulling = false
    }

    @Composable
    override fun Content() {
        val overlays = LocalOverlays.current
        val errorTitle = tr("Couldn't Post")
        LaunchedEffect(Unit) { load() }
        ScreenScaffold(
            title = tr("Comments"),
            overlay = {
                if (Session.isLoggedIn) {
                    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.BottomCenter) {
                        Composer { text ->
                            posting = true
                            scope.launch {
                                try {
                                    comments.add(0, NHClient.postComment(galleryId, text))
                                    draft = ""
                                } catch (e: Exception) {
                                    overlays.alert(errorTitle, e.localizedMessage)
                                }
                                posting = false
                            }
                        }
                    }
                }
            },
        ) { padding ->
            PullToRefresh(pulling, { pulling = true; scope.launch { load() } }, topInset = padding.calculateTopPadding()) {
                LazyColumn(
                    Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(
                        start = 16.dp, end = 16.dp,
                        top = padding.calculateTopPadding() + 8.dp,
                        bottom = padding.calculateBottomPadding() + 80.dp,
                    ),
                    verticalArrangement = Arrangement.spacedBy(18.dp),
                ) {
                    if (comments.isEmpty()) item { EmptyState(Icons.Comment, tr("No Comments")) }
                    items(comments, key = { it.id }) { CommentBubble(it) }
                }
            }
        }
    }

    @Composable
    private fun Composer(post: (String) -> Unit) {
        val colors = AppTheme.colors
        val ready = draft.trim().length >= 10 && !posting
        Row(
            Modifier
                .navigationBarsPadding()
                .imePadding()
                .padding(horizontal = 16.dp, vertical = 8.dp),
            verticalAlignment = Alignment.Bottom,
            horizontalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Box(
                Modifier
                    .weight(1f)
                    .heightIn(min = 46.dp)
                    .glass(RoundedCornerShape(23.dp))
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                contentAlignment = Alignment.CenterStart,
            ) {
                if (draft.isEmpty()) Txt(tr("Add a comment…"), style = Type.body, color = colors.secondaryLabel)
                BasicTextField(
                    draft, { draft = it },
                    textStyle = Type.body.copy(color = colors.label),
                    cursorBrush = SolidColor(AppTheme.tint),
                    maxLines = 5,
                    modifier = Modifier.fillMaxWidth(),
                )
            }
            if (posting) {
                Box(Modifier.size(46.dp), contentAlignment = Alignment.Center) { ActivityIndicator() }
            } else {
                GlassCircleButton(
                    Icons.ArrowUp, tr("Done"),
                    onClick = { post(draft.trim()) },
                    size = 46.dp,
                    tint = if (ready) AppTheme.tint else Color.Unspecified,
                    enabled = ready,
                )
            }
        }
    }
}
