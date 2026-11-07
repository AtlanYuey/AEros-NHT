package com.atlanyuey.nhentai.screens

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.runtime.derivedStateOf
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.asPaddingValues
import androidx.compose.foundation.layout.widthIn
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import com.atlanyuey.nhentai.ui.components.NAV_BAR_HEIGHT
import com.atlanyuey.nhentai.ui.components.rememberAnchor
import com.atlanyuey.nhentai.ui.components.anchor
import com.atlanyuey.nhentai.ui.components.MenuItem
import com.atlanyuey.nhentai.ui.components.GlassCapsuleButton
import com.atlanyuey.nhentai.ui.components.hidesBarsOnScroll
import com.atlanyuey.nhentai.ui.components.BarsState
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.combinedClickable
import androidx.activity.compose.BackHandler
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalFocusManager
import android.content.Context
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.Orientation
import androidx.compose.foundation.gestures.draggable
import androidx.compose.foundation.gestures.rememberDraggableState
import androidx.compose.foundation.gestures.snapping.rememberSnapFlingBehavior
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.ui.draw.clip
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.lazy.staggeredgrid.LazyStaggeredGridState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.layout
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import com.atlanyuey.nhentai.core.AppSettings
import com.atlanyuey.nhentai.core.GalleryFeed
import com.atlanyuey.nhentai.core.GalleryItem
import com.atlanyuey.nhentai.core.GalleryListStyle
import com.atlanyuey.nhentai.core.HistoryEntry
import com.atlanyuey.nhentai.core.HistoryStore
import com.atlanyuey.nhentai.core.L10n
import com.atlanyuey.nhentai.core.LanguageFilter
import com.atlanyuey.nhentai.core.NHClient
import com.atlanyuey.nhentai.core.SearchSort
import com.atlanyuey.nhentai.core.Session
import com.atlanyuey.nhentai.core.TagSuggestion
import com.atlanyuey.nhentai.core.tr
import com.atlanyuey.nhentai.ui.components.ActivityIndicator
import com.atlanyuey.nhentai.ui.components.AppIcon
import com.atlanyuey.nhentai.ui.components.ButtonRole
import com.atlanyuey.nhentai.ui.components.DialogButton
import com.atlanyuey.nhentai.ui.components.EmptyState
import com.atlanyuey.nhentai.ui.components.GalleryCard
import com.atlanyuey.nhentai.ui.components.GalleryGrid
import com.atlanyuey.nhentai.ui.components.GalleryLayout
import com.atlanyuey.nhentai.ui.components.LocalCoverBadge
import com.atlanyuey.nhentai.ui.components.LocalGalleryMenuItems
import com.atlanyuey.nhentai.ui.components.galleryItems
import com.atlanyuey.nhentai.core.LibraryStyle
import androidx.compose.runtime.CompositionLocalProvider
import com.atlanyuey.nhentai.ui.components.GalleryRow
import com.atlanyuey.nhentai.ui.components.GlassCircleButton
import com.atlanyuey.nhentai.ui.components.LargeTitle
import com.atlanyuey.nhentai.ui.components.LocalNavigator
import com.atlanyuey.nhentai.ui.components.LocalOverlays
import com.atlanyuey.nhentai.ui.components.MenuButton
import com.atlanyuey.nhentai.ui.components.PullToRefresh
import com.atlanyuey.nhentai.ui.components.Screen
import com.atlanyuey.nhentai.ui.components.ScreenScaffold
import com.atlanyuey.nhentai.ui.components.SearchField
import com.atlanyuey.nhentai.ui.components.SectionTitle
import com.atlanyuey.nhentai.ui.components.TextButton
import com.atlanyuey.nhentai.ui.components.Txt
import com.atlanyuey.nhentai.ui.components.feedFooter
import com.atlanyuey.nhentai.ui.components.fullLine
import com.atlanyuey.nhentai.ui.components.pickerItems
import com.atlanyuey.nhentai.ui.theme.AppTheme
import com.atlanyuey.nhentai.ui.theme.Icons
import com.atlanyuey.nhentai.ui.theme.Type
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.drop
import kotlinx.coroutines.launch
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.builtins.serializer
import java.text.DateFormat
import java.util.Calendar
import java.util.Date
import kotlin.math.roundToInt

// MARK: - Shared pieces

/** Language and sort menus of a gallery list. */
@Composable
fun FeedMenus(language: LanguageFilter, sort: SearchSort, onLanguage: (LanguageFilter) -> Unit, onSort: (SearchSort) -> Unit) {
    MenuButton(Icons.Globe, tr("Language"), {
        listOf(pickerItems(LanguageFilter.entries, language, { L10n.string(it.title) }, onLanguage))
    }, title = tr("Language"))
    MenuButton(Icons.Sort, tr("Sort"), {
        listOf(pickerItems(SearchSort.entries, sort, { L10n.string(it.title) }, onSort))
    }, title = tr("Sort"))
}

/** A full-width row that extends into the grid's side padding. */
fun Modifier.bleed(horizontal: androidx.compose.ui.unit.Dp) = layout { measurable, constraints ->
    val extra = (horizontal * 2).roundToPx()
    val placeable = measurable.measure(
        constraints.copy(minWidth = constraints.minWidth + extra, maxWidth = constraints.maxWidth + extra),
    )
    layout(constraints.maxWidth, placeable.height) { placeable.place(-horizontal.roundToPx(), 0) }
}

/** Horizontally scrolling row of covers. */
@Composable
fun PopularRow(items: List<GalleryItem>) {
    val state = rememberLazyListState()
    BoxWithConstraints(Modifier.fillMaxWidth().bleed(16.dp)) {
        val cardWidth = if (maxWidth > 600.dp) 170.dp else 132.dp
        LazyRow(
            state = state,
            contentPadding = PaddingValues(horizontal = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            flingBehavior = rememberSnapFlingBehavior(state),
        ) {
            items(items, key = { it.id }) { item ->
                GalleryCard(item, GalleryListStyle.Grid, Modifier.width(cardWidth))
            }
        }
    }
}

@Composable
private fun FeedTitle(title: String, subtitle: String?) {
    Column(Modifier.fillMaxWidth().padding(top = 18.dp, bottom = 6.dp, start = 4.dp)) {
        Txt(title, style = Type.title2)
        subtitle?.let { Txt(it, style = Type.subheadline, color = AppTheme.colors.secondaryLabel) }
    }
}

/** Shows the inline title once the large title (first item) scrolled away. */
private fun LazyStaggeredGridState.pastTitle() = firstVisibleItemIndex > 0 || firstVisibleItemScrollOffset > 60

// MARK: - Home

class HomeScreen : Screen() {
    private val feed = GalleryFeed(scope) { page ->
        NHClient.galleries(AppSettings.homeLanguage.queryTerm ?: "", AppSettings.homeSort, page)
    }
    private var popular by mutableStateOf(emptyList<GalleryItem>())
    private val grid = LazyStaggeredGridState()
    private var pulling by mutableStateOf(false)

    // Large screens: the search field opens in the navigation bar and the
    // search shows in place of the feed (no separate search tab).
    private val search = SearchState()
    private val searchPanel = SearchPanel(search, scope)
    private var searching by mutableStateOf(false)

    private fun reload() {
        val job = feed.reload()
        scope.launch {
            popular = runCatching { NHClient.popular() }.getOrDefault(popular)
            job.join()
            pulling = false
        }
    }

    @Composable
    override fun Content() {
        LaunchedEffect(Unit) {
            if (!feed.hasLoaded) reload()
            snapshotFlow { AppSettings.homeLanguage to AppSettings.homeSort }.drop(1).collect { feed.reload() }
        }
        val language = AppSettings.homeLanguage
        val sort = AppSettings.homeSort
        val focusManager = LocalFocusManager.current
        val density = LocalDensity.current
        val screenWidth = LocalConfiguration.current.screenWidthDp.dp
        val endSearch = {
            focusManager.clearFocus()
            search.reset()
            searching = false
        }
        if (searching) {
            searchPanel.Effects()
            BackHandler { endSearch() }
        }
        // The feed's header (sort, language, search) has scrolled under the
        // navigation bar: its buttons show in the bar instead.
        val statusTop = WindowInsets.statusBars.asPaddingValues().calculateTopPadding()
        val barBottom = with(density) { (statusTop + NAV_BAR_HEIGHT.dp).roundToPx() }
        val headerIndex = if (popular.isNotEmpty()) 3 else 1
        val docked by remember(headerIndex, barBottom) {
            derivedStateOf {
                val info = grid.layoutInfo
                val header = info.visibleItemsInfo.firstOrNull { it.key == "feedTitle" }
                if (header != null) {
                    header.offset.y + header.size.height < barBottom
                } else {
                    (info.visibleItemsInfo.firstOrNull()?.index ?: 0) > headerIndex
                }
            }
        }
        val sortItems = {
            listOf(pickerItems(SearchSort.entries, AppSettings.homeSort, { L10n.string(it.title) }) { AppSettings.homeSort = it })
        }
        val languageItems = {
            listOf(pickerItems(LanguageFilter.entries, AppSettings.homeLanguage, { L10n.string(it.title) }) { AppSettings.homeLanguage = it })
        }
        ScreenScaffold(
            title = tr("Home"),
            showTitle = { !searching && grid.pastTitle() },
            leading = if (searching) null else {
                {
                    AnimatedVisibility(docked, enter = fadeIn() + scaleIn(initialScale = 0.8f), exit = fadeOut() + scaleOut(targetScale = 0.8f)) {
                        DockedSortButton(sort, sortItems)
                    }
                }
            },
            trailing = {
                if (searching) {
                    val showsMenus = searchPanel.results() != null
                    if (showsMenus) {
                        FeedMenus(AppSettings.searchLanguage, AppSettings.searchSort, { AppSettings.searchLanguage = it }, { AppSettings.searchSort = it })
                    }
                    val focus = remember { FocusRequester() }
                    val room = screenWidth - 32.dp - 54.dp - if (showsMenus) 108.dp else 0.dp
                    SearchField(
                        text = search.text,
                        onTextChange = { search.text = it },
                        placeholder = tr("Titles, tags, artists, IDs"),
                        onSubmit = { search.submit(search.text) },
                        modifier = Modifier.width(minOf(340.dp, room)).height(44.dp),
                        focusRequester = focus,
                    )
                    LaunchedEffect(Unit) { focus.requestFocus() }
                    GlassCircleButton(Icons.Close, tr("Cancel"), endSearch)
                } else {
                    AnimatedVisibility(docked, enter = fadeIn() + scaleIn(initialScale = 0.8f), exit = fadeOut() + scaleOut(targetScale = 0.8f)) {
                        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                            MenuButton(Icons.Globe, tr("Language"), languageItems, title = tr("Language"))
                            GlassCircleButton(Icons.Search, tr("Search"), { searching = true })
                        }
                    }
                }
            },
        ) { padding ->
            if (searching) {
                searchPanel.Body(padding, largeTitle = null)
                return@ScreenScaffold
            }
            PullToRefresh(pulling, { pulling = true; reload() }, topInset = padding.calculateTopPadding()) {
                GalleryGrid(
                    feed.items, grid, padding,
                    onItemShown = { feed.loadMoreIfNeeded(it) },
                    header = {
                        fullLine("title") { LargeTitle(tr("Home"), inset = 4.dp) }
                        if (popular.isNotEmpty()) {
                            fullLine("popularTitle") { FeedTitle(tr("Popular Now"), null) }
                            fullLine("popular") { PopularRow(popular) }
                        }
                        fullLine("feedTitle") {
                            FeedHeader(sort, language, sortItems, languageItems) { searching = true }
                        }
                    },
                    footer = { feedFooter(feed, L10n.string("No Galleries") to Icons.Photo) },
                )
            }
        }
    }
}

/**
 * The feed's header: the sort (tap it to switch), and on the right the
 * language and search buttons. Scrolled under the navigation bar, the same
 * buttons show in the bar.
 */
@Composable
private fun FeedHeader(
    sort: SearchSort,
    language: LanguageFilter,
    sortItems: () -> List<List<MenuItem>>,
    languageItems: () -> List<List<MenuItem>>,
    onSearch: () -> Unit,
) {
    val overlays = LocalOverlays.current
    val anchor = rememberAnchor()
    val sortTitle = tr("Sort")
    Row(
        Modifier.fillMaxWidth().padding(top = 18.dp, bottom = 6.dp, start = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Column(
            Modifier
                .weight(1f)
                .anchor(anchor)
                .clickable(interactionSource = null, indication = null) { overlays.menu(anchor.bounds, sortItems(), sortTitle) }
                .semantics { contentDescription = sortTitle },
        ) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                Txt(tr(sort.title), style = Type.title2, maxLines = 1)
                AppIcon(Icons.ChevronDown, null, tint = AppTheme.colors.secondaryLabel, size = 16.dp)
            }
            Txt(tr(language.title), style = Type.subheadline, color = AppTheme.colors.secondaryLabel, maxLines = 1)
        }
        MenuButton(Icons.Globe, tr("Language"), languageItems, title = tr("Language"))
        GlassCircleButton(Icons.Search, tr("Search"), onSearch)
    }
}

/** The sort, as a small glass button in the navigation bar (header docked). */
@Composable
private fun DockedSortButton(sort: SearchSort, items: () -> List<List<MenuItem>>) {
    val overlays = LocalOverlays.current
    val anchor = rememberAnchor()
    val title = tr("Sort")
    GlassCapsuleButton(
        onClick = { overlays.menu(anchor.bounds, items(), title) },
        modifier = Modifier.anchor(anchor).widthIn(max = 160.dp),
        horizontalPadding = 14.dp,
    ) {
        Txt(tr(sort.title), Modifier.weight(1f, fill = false), style = Type.subheadline.copy(fontWeight = FontWeight.SemiBold), maxLines = 1)
        AppIcon(Icons.ChevronDown, null, tint = AppTheme.colors.secondaryLabel, size = 12.dp)
    }
}

// MARK: - Favorites

class FavoritesScreen : Screen() {
    private val feed = GalleryFeed(scope) { page -> NHClient.favorites(page) }
    private val grid = LazyStaggeredGridState()
    private var pulling by mutableStateOf(false)

    @Composable
    override fun Content() {
        val navigator = LocalNavigator.current
        val loggedIn = Session.isLoggedIn
        LaunchedEffect(loggedIn) {
            if (loggedIn) feed.reload()
        }
        LaunchedEffect(feed.isLoading) { if (!feed.isLoading) pulling = false }
        ScreenScaffold(title = tr("Favorites"), showTitle = { !loggedIn || grid.pastTitle() }) { padding ->
            if (!loggedIn) {
                Box(Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                    EmptyState(
                        icon = Icons.Heart,
                        title = tr("Favorites"),
                        message = tr("Log in to your nhentai account to see your favorites."),
                        action = tr("Log In") to { navigator.push(LoginScreen()) },
                    )
                }
            } else {
                PullToRefresh(pulling, { pulling = true; feed.reload() }, topInset = padding.calculateTopPadding()) {
                    GalleryGrid(
                        feed.items, grid, padding,
                        onItemShown = { feed.loadMoreIfNeeded(it) },
                        header = { fullLine("title") { LargeTitle(tr("Favorites"), inset = 4.dp) } },
                        footer = { feedFooter(feed, L10n.string("No Favorites") to Icons.Heart) },
                    )
                }
            }
        }
    }
}

// MARK: - History

class HistoryScreen : Screen() {
    private val list = LazyListState()
    private val grid = LazyStaggeredGridState()
    private var search by mutableStateOf("")

    @Composable
    override fun Content() {
        val overlays = LocalOverlays.current
        val entries = HistoryStore.entries
        val text = search.trim()
        val filtered = if (text.isEmpty()) entries.toList() else entries.filter {
            it.title.contains(text, ignoreCase = true) || "${it.gid}" == text
        }
        val sections = filtered.groupBy { startOfDay(it.lastRead) }.toSortedMap(compareByDescending { it })
        val clearTitle = tr("Clear all history?")
        val clearLabel = tr("Clear History")
        val cards = AppSettings.libraryStyle == LibraryStyle.Cards
        ScreenScaffold(
            title = tr("History"),
            showTitle = {
                if (cards) grid.pastTitle() else list.firstVisibleItemIndex > 0 || list.firstVisibleItemScrollOffset > 60
            },
            trailing = {
                GlassCircleButton(
                    Icons.Trash, tr("Clear"),
                    onClick = {
                        overlays.actionSheet(clearTitle, null, listOf(DialogButton(clearLabel, ButtonRole.Destructive) { HistoryStore.clear() }))
                    },
                    enabled = entries.isNotEmpty(),
                )
            },
        ) { padding ->
            if (cards) {
                Cards(padding, entries.isEmpty(), filtered, sections)
            } else {
                Rows(padding, entries.isEmpty(), filtered, sections)
            }
        }
    }

    @Composable
    private fun SearchBox(modifier: Modifier) {
        SearchField(search, { search = it }, tr("Search History"), onSubmit = {}, modifier = modifier, filled = true)
    }

    /** Cards like Favorites (in the list style), by day. */
    @Composable
    private fun Cards(padding: PaddingValues, empty: Boolean, filtered: List<HistoryEntry>, sections: Map<Long, List<HistoryEntry>>) {
        val byId = filtered.associateBy { it.gid }
        val deleteLabel = tr("Delete")
        CompositionLocalProvider(
            LocalCoverBadge provides { item -> ReadingProgress(byId[item.id]) },
            LocalGalleryMenuItems provides { item ->
                listOf(MenuItem(deleteLabel, Icons.Trash, destructive = true) { HistoryStore.delete(item.id) })
            },
        ) {
            GalleryLayout(grid, padding) { style ->
                fullLine("title") { LargeTitle(tr("History"), inset = 4.dp) }
                fullLine("search") { SearchBox(Modifier.fillMaxWidth().padding(vertical = 6.dp)) }
                when {
                    empty -> fullLine("empty") { EmptyState(Icons.Clock, tr("No History"), tr("Galleries you open appear here.")) }
                    filtered.isEmpty() -> fullLine("noresults") { EmptyState(Icons.Search, tr("No Results")) }
                }
                sections.forEach { (day, dayEntries) ->
                    fullLine("day$day") { DayHeader(day, inset = 4.dp) }
                    galleryItems(dayEntries.map { it.item }, style)
                }
            }
        }
    }

    /** Rows with the page read, by day; swipe left to delete. */
    @Composable
    private fun Rows(padding: PaddingValues, empty: Boolean, filtered: List<HistoryEntry>, sections: Map<Long, List<HistoryEntry>>) {
        val topSlack = with(LocalDensity.current) { 60.dp.roundToPx() }
        LazyColumn(
            Modifier
                .fillMaxSize()
                .hidesBarsOnScroll { list.firstVisibleItemIndex == 0 && list.firstVisibleItemScrollOffset < topSlack },
            state = list,
            contentPadding = PaddingValues(top = padding.calculateTopPadding(), bottom = padding.calculateBottomPadding()),
        ) {
            item("title") { LargeTitle(tr("History")) }
            item("search") { SearchBox(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 6.dp)) }
            when {
                empty -> item("empty") {
                    EmptyState(Icons.Clock, tr("No History"), tr("Galleries you open appear here."))
                }
                filtered.isEmpty() -> item("noresults") { EmptyState(Icons.Search, tr("No Results")) }
            }
            sections.forEach { (day, dayEntries) ->
                item("day$day") { DayHeader(day) }
                items(dayEntries, key = { it.gid }) { entry ->
                    SwipeToDelete(onDelete = { HistoryStore.delete(entry.gid) }) {
                        GalleryRow(
                            entry.item,
                            Modifier.background(AppTheme.colors.background).padding(horizontal = 16.dp),
                            subtitle = historySubtitle(entry),
                        )
                    }
                }
            }
        }
    }

    private fun startOfDay(time: Long): Long = Calendar.getInstance().apply {
        timeInMillis = time
        set(Calendar.HOUR_OF_DAY, 0)
        set(Calendar.MINUTE, 0)
        set(Calendar.SECOND, 0)
        set(Calendar.MILLISECOND, 0)
    }.timeInMillis

    @Composable
    private fun DayHeader(day: Long, inset: androidx.compose.ui.unit.Dp = 20.dp) {
        val today = startOfDay(System.currentTimeMillis())
        val title = when (day) {
            today -> tr("Today")
            today - 24L * 3600 * 1000 -> tr("Yesterday")
            else -> DateFormat.getDateInstance(DateFormat.FULL).format(Date(day))
        }
        Txt(
            title,
            Modifier.fillMaxWidth().padding(start = inset, end = 16.dp, top = 18.dp, bottom = 4.dp),
            style = Type.subheadline.copy(fontWeight = FontWeight.SemiBold),
            color = AppTheme.colors.secondaryLabel,
        )
    }

    @Composable
    private fun historySubtitle(entry: HistoryEntry): String {
        val time = DateFormat.getTimeInstance(DateFormat.SHORT).format(Date(entry.lastRead))
        if (entry.numPages <= 0) return time
        return tr("Page %lld of %lld · %@", entry.lastPage + 1, entry.numPages, time)
    }
}

/** How far a gallery has been read: a thin bar at the bottom of its cover. */
@Composable
private fun androidx.compose.foundation.layout.BoxScope.ReadingProgress(entry: HistoryEntry?) {
    if (entry == null || entry.numPages <= 1 || entry.lastPage <= 0) return
    val fraction = ((entry.lastPage + 1).toFloat() / entry.numPages).coerceIn(0f, 1f)
    Box(
        Modifier
            .align(Alignment.BottomCenter)
            .padding(start = 8.dp, end = 8.dp, bottom = 6.dp)
            .fillMaxWidth()
            .height(4.dp)
            .clip(RoundedCornerShape(2.dp))
            .background(Color.Black.copy(alpha = 0.35f)),
    ) {
        Box(Modifier.fillMaxWidth(fraction).fillMaxHeight().clip(RoundedCornerShape(2.dp)).background(Color.White))
    }
}

/** Swipe left to reveal Delete (iOS swipe action); a full swipe deletes. */
@Composable
fun SwipeToDelete(onDelete: () -> Unit, content: @Composable () -> Unit) {
    val density = LocalDensity.current
    val scope = rememberCoroutineScope()
    val offset = remember { Animatable(0f) }
    val reveal = with(density) { 88.dp.toPx() }
    BoxWithConstraints(Modifier.fillMaxWidth()) {
        val width = with(density) { maxWidth.toPx() }
        Box(
            Modifier
                .matchParentSize()
                .background(AppTheme.colors.red)
                .clickable { onDelete() },
            contentAlignment = Alignment.CenterEnd,
        ) {
            Txt(tr("Delete"), Modifier.padding(end = 20.dp), style = Type.body.copy(fontWeight = FontWeight.SemiBold), color = Color.White)
        }
        Box(
            Modifier
                .offset { IntOffset(offset.value.roundToInt(), 0) }
                .draggable(
                    orientation = Orientation.Horizontal,
                    state = rememberDraggableState { delta ->
                        scope.launch { offset.snapTo((offset.value + delta).coerceIn(-width, 0f)) }
                    },
                    onDragStopped = {
                        when {
                            offset.value < -width * 0.6f -> {
                                offset.animateTo(-width, spring(stiffness = 600f))
                                onDelete()
                            }
                            offset.value < -reveal / 2 -> offset.animateTo(-reveal, spring(stiffness = 500f))
                            else -> offset.animateTo(0f, spring(stiffness = 500f))
                        }
                    },
                ),
        ) { content() }
    }
}

private fun Modifier.matchParentSize() = this.then(Modifier.fillMaxWidth().height(androidx.compose.ui.unit.Dp.Unspecified))

// MARK: - Search

/** A search field's text and the search it started. */
class SearchState {
    var text by mutableStateOf("")
    var query by mutableStateOf("")
    val suggestions = mutableStateListOf<TagSuggestion>()
    var submitCount by mutableStateOf(0)

    /** Searches for [term] (typed and submitted, or a recent search). */
    fun submit(term: String) {
        val trimmed = term.trim()
        if (trimmed.isEmpty()) return
        text = term
        suggestions.clear()
        query = trimmed
        submitCount++
    }

    /** Ends the search and clears the field. */
    fun reset() {
        text = ""
        query = ""
        suggestions.clear()
    }

    /** Replaces the word being typed with the tag. */
    fun complete(tag: TagSuggestion) {
        val parts = text.split(" ").toMutableList()
        if (parts.isNotEmpty()) parts.removeAt(parts.lastIndex)
        parts.add(tag.query)
        text = parts.joinToString(" ") + " "
        suggestions.clear()
    }
}

/** Recent searches, tag suggestions and results for a [SearchState]: the Home page searches in place. */
class SearchPanel(private val state: SearchState, private val scope: kotlinx.coroutines.CoroutineScope) {
    private var results: SearchResults? = null

    /** Results of the submitted query, if there is one. */
    @Composable
    fun results(): SearchResults? {
        val query = state.query
        if (query.isEmpty()) return null
        return results?.takeIf { it.query == query } ?: SearchResults(query, scope).also { results = it }
    }

    /** Tag suggestions while typing; recent searches on submit. */
    @Composable
    fun Effects() {
        LaunchedEffect(state.text) {
            val text = state.text
            val word = text.split(" ").lastOrNull() ?: ""
            if (word.length < 2 || word.contains(":") || text.endsWith(" ")) {
                state.suggestions.clear()
                return@LaunchedEffect
            }
            delay(250)
            val found = runCatching { NHClient.suggestTags(word) }.getOrDefault(emptyList())
            state.suggestions.clear()
            state.suggestions.addAll(found)
        }
        LaunchedEffect(state.text) { if (state.text.isEmpty()) state.query = "" }
        LaunchedEffect(state.submitCount) {
            val query = state.query
            if (query.isEmpty()) return@LaunchedEffect
            AppSettings.addRecentSearch(query)
        }
    }

    @Composable
    fun Body(padding: PaddingValues, largeTitle: String?) {
        val current = results()
        when {
            state.suggestions.isNotEmpty() -> Suggestions(padding)
            current != null -> current.Content(padding)
            else -> Recents(padding, largeTitle)
        }
    }

    @Composable
    private fun Suggestions(padding: PaddingValues) {
        LazyColumn(Modifier.fillMaxSize(), contentPadding = padding) {
            items(state.suggestions, key = { it.id }) { tag ->
                Row(
                    Modifier
                        .fillMaxWidth()
                        .clickable { state.complete(tag) }
                        .padding(horizontal = 20.dp, vertical = 14.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    AppIcon(Icons.Tag, null, tint = AppTheme.colors.secondaryLabel, size = 18.dp)
                    Txt(tag.name, Modifier.weight(1f), maxLines = 1)
                    Txt(tag.type.replaceFirstChar { it.uppercase() }, style = Type.subheadline, color = AppTheme.colors.secondaryLabel)
                }
            }
        }
    }

    @Composable
    private fun Recents(padding: PaddingValues, largeTitle: String?) {
        val overlays = LocalOverlays.current
        val deleteLabel = tr("Delete")
        val recents = AppSettings.recentSearches
        LazyColumn(Modifier.fillMaxSize(), contentPadding = padding) {
            largeTitle?.let { item { LargeTitle(it) } }
            if (!AppSettings.saveSearchHistory || recents.isEmpty()) {
                item {
                    EmptyState(
                        Icons.Search,
                        tr("Search nhentai"),
                        tr("Search by title or use tags like artist:name, or enter a gallery number."),
                    )
                }
            } else {
                item {
                    SectionTitle(tr("Recent Searches")) {
                        TextButton(tr("Clear"), { AppSettings.clearRecentSearches() })
                    }
                }
                items(recents.toList(), key = { it }) { term ->
                    SwipeToDelete(onDelete = { AppSettings.removeRecentSearch(term) }) {
                        Row(
                            Modifier
                                .fillMaxWidth()
                                .background(AppTheme.colors.background)
                                .combinedClickable(
                                    onClick = { state.submit(term) },
                                    onLongClick = {
                                        overlays.actionSheet(term, null, listOf(
                                            DialogButton(deleteLabel, ButtonRole.Destructive) { AppSettings.removeRecentSearch(term) },
                                        ))
                                    },
                                )
                                .padding(horizontal = 20.dp, vertical = 14.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(12.dp),
                        ) {
                            AppIcon(Icons.Clock, null, tint = AppTheme.colors.secondaryLabel, size = 18.dp)
                            Txt(term, Modifier.weight(1f), maxLines = 1)
                        }
                    }
                }
            }
        }
    }
}

/** Search results for a query (search tab and tag searches). */
class SearchResults(val query: String, scope: kotlinx.coroutines.CoroutineScope) {
    val feed = GalleryFeed(scope) { page ->
        val full = listOfNotNull(query, AppSettings.searchLanguage.queryTerm).joinToString(" ")
        NHClient.galleries(full, AppSettings.searchSort, page)
    }
    private val grid = LazyStaggeredGridState()
    private var pulling by mutableStateOf(false)

    /** A gallery number shows that gallery first, above the results of searching for the number. */
    private val galleryId = query.trim().toIntOrNull()?.takeIf { it > 0 }
    private var match by mutableStateOf<GalleryItem?>(null)
    private var matchFailed by mutableStateOf(false)

    init {
        galleryId?.let { id ->
            scope.launch {
                match = runCatching { NHClient.gallery(id).asItem }.getOrNull()
                matchFailed = match == null
            }
        }
    }

    @Composable
    fun Content(padding: PaddingValues) {
        LaunchedEffect(Unit) {
            if (!feed.hasLoaded) feed.reload()
            snapshotFlow { AppSettings.searchLanguage to AppSettings.searchSort }.drop(1).collect { feed.reload() }
        }
        LaunchedEffect(feed.isLoading) { if (!feed.isLoading) pulling = false }
        PullToRefresh(pulling, { pulling = true; feed.reload() }, topInset = padding.calculateTopPadding()) {
            GalleryGrid(
                feed.items, grid, padding,
                onItemShown = { feed.loadMoreIfNeeded(it) },
                header = {
                    // These lines are there from the start (the gallery with a
                    // placeholder while it loads): a lazy grid keeps its first
                    // visible item in place, so lines added above it later
                    // would open the results scrolled down.
                    if (galleryId != null && !matchFailed) {
                        fullLine("matchTitle") { FeedTitle(tr("Gallery #%lld", galleryId), null) }
                        fullLine("match") {
                            val item = match
                            if (item != null) {
                                GalleryRow(item, Modifier.padding(horizontal = 4.dp))
                            } else {
                                Box(Modifier.fillMaxWidth().height(128.dp), contentAlignment = Alignment.Center) { ActivityIndicator() }
                            }
                        }
                    }
                    fullLine("total") {
                        val total = feed.total
                        Box(Modifier.fillMaxWidth().heightIn(min = 36.dp), contentAlignment = Alignment.CenterStart) {
                            if (total != null && feed.hasLoaded) {
                                Txt(
                                    tr("%lld results", total),
                                    Modifier.padding(horizontal = 4.dp, vertical = 8.dp),
                                    style = Type.subheadline,
                                    color = AppTheme.colors.secondaryLabel,
                                )
                            }
                        }
                    }
                },
                footer = { feedFooter(feed, L10n.string("No Results") to Icons.Search) },
            )
        }
    }
}

/** Results of a tag / artist search, pushed from a gallery. */
class SearchResultsScreen(private val query: String, private val title: String?) : Screen() {
    private val results = SearchResults(query, scope)

    @Composable
    override fun Content() {
        ScreenScaffold(
            title = title ?: query,
            trailing = {
                FeedMenus(AppSettings.searchLanguage, AppSettings.searchSort, { AppSettings.searchLanguage = it }, { AppSettings.searchSort = it })
            },
        ) { padding -> results.Content(padding) }
    }
}
