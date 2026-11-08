package com.atlanyuey.nhentai.core

import android.content.Context
import android.content.SharedPreferences
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.builtins.serializer
import kotlin.math.ceil
import kotlin.math.max
import kotlin.math.min
import kotlin.properties.ReadWriteProperty
import kotlin.reflect.KProperty
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue

enum class ThemeMode(val raw: String, val title: String) {
    System("system", "System"), Light("light", "Light"), Dark("dark", "Dark");

    companion object {
        fun of(raw: String?) = entries.firstOrNull { it.raw == raw } ?: System
    }
}

enum class AccentChoice(val raw: String) {
    Blue("blue"), Indigo("indigo"), Purple("purple"), Pink("pink"), Red("red"), Orange("orange"),
    Yellow("yellow"), Green("green"), Mint("mint"), Teal("teal"), Cyan("cyan"), Brown("brown");

    companion object {
        fun of(raw: String?) = entries.firstOrNull { it.raw == raw } ?: Blue
    }
}

enum class GalleryListStyle(val raw: String, val title: String, val preferredCardWidth: Float) {
    Waterfall("waterfall", "Waterfall", 190f),
    Compact("compact", "Waterfall (Compact)", 190f),
    Grid("grid", "Grid", 150f),
    List("list", "List", 600f);

    companion object {
        fun of(raw: String?) = entries.firstOrNull { it.raw == raw } ?: Waterfall
    }
}

/** Where the tab bar sits on large screens. */
/** Where the tablet tab bar sits when it doesn't follow the hand. */
enum class TabBarPosition(val raw: String, val title: String) {
    Leading("leading", "Left"),
    Center("center", "Center"),
    Trailing("trailing", "Right");

    companion object {
        fun of(raw: String?) = entries.firstOrNull { it.raw == raw } ?: Center
    }
}

/**
 * How History and Downloads show their galleries: cards like Favorites (in
 * the list style), or a list with reading / download progress.
 */
enum class LibraryStyle(val raw: String, val title: String) {
    Cards("cards", "Cards"),
    List("list", "List");

    companion object {
        fun of(raw: String?) = entries.firstOrNull { it.raw == raw } ?: Cards
    }
}

/** How quickly the tablet tab bar follows the hand. */
enum class FollowSpeed(val raw: String, val title: String, val touches: Int, val durationMillis: Int) {
    Fast("fast", "Fast", 1, 300),
    Medium("medium", "Medium", 2, 450),
    Slow("slow", "Slow", 4, 650);

    companion object {
        fun of(raw: String?) = entries.firstOrNull { it.raw == raw } ?: Fast
    }
}

/**
 * Follows the hand in use: the side of the screen touched last ([record]'s
 * `touches` in a row on the other side move it). Touches near the middle
 * keep the side.
 */
object HandTracker {
    enum class Side { Leading, Center, Trailing }

    var side by androidx.compose.runtime.mutableStateOf(Side.Trailing)
        private set
    private var pending: Side? = null
    private var streak = 0

    /** A touch at [fraction] of the screen width (0 = left edge). */
    fun record(fraction: Float, touches: Int) {
        val next = when {
            fraction > 0.6f -> Side.Trailing
            fraction < 0.4f -> Side.Leading
            else -> return
        }
        if (next == side) {
            pending = null
            streak = 0
            return
        }
        if (pending == next) streak++ else {
            pending = next
            streak = 1
        }
        if (streak < touches) return
        pending = null
        streak = 0
        side = next
    }
}

enum class ReadMode(val raw: String, val title: String) {
    LeftToRight("leftToRight", "Left to Right"),
    RightToLeft("rightToLeft", "Right to Left"),
    VerticalPaged("verticalPaged", "Top to Bottom"),
    Vertical("vertical", "Continuous (Webtoon)"),
    VerticalGap("verticalGap", "Continuous with Gaps");

    /** Whether pages are turned one at a time. */
    val isPaged: Boolean get() = this != Vertical && this != VerticalGap

    companion object {
        fun of(raw: String?) = entries.firstOrNull { it.raw == raw } ?: LeftToRight
    }
}

enum class SearchSort(val raw: String, val title: String) {
    Recent("date", "Recent"),
    PopularToday("popular-today", "Popular Today"),
    PopularWeek("popular-week", "Popular This Week"),
    PopularMonth("popular-month", "Popular This Month"),
    Popular("popular", "All-Time Popular");

    companion object {
        fun of(raw: String?, default: SearchSort) = entries.firstOrNull { it.raw == raw } ?: default
    }
}

enum class LanguageFilter(val raw: String, val title: String) {
    All("", "All Languages"),
    Japanese("japanese", "Japanese"),
    Chinese("chinese", "Chinese"),
    English("english", "English"),
    Translated("translated", "Translated");

    /** Search syntax added to a query. */
    val queryTerm: String? get() = if (this == All) null else "language:$raw"

    companion object {
        fun of(raw: String?) = entries.firstOrNull { it.raw == raw } ?: All
    }
}

/** A setting kept in Compose state and saved to SharedPreferences. */
private class Pref<T>(initial: T, private val onSet: (T) -> Unit) : ReadWriteProperty<Any?, T> {
    private val state = mutableStateOf(initial)
    override fun getValue(thisRef: Any?, property: KProperty<*>): T = state.value
    override fun setValue(thisRef: Any?, property: KProperty<*>, value: T) {
        if (state.value == value) return
        state.value = value
        onSet(value)
    }
}

/** App settings; the keys and values match the iOS app (export / import). */
object AppSettings {
    private lateinit var prefs: SharedPreferences
    private var loading = false

    fun init(context: Context) {
        prefs = context.getSharedPreferences("settings", Context.MODE_PRIVATE)
        loading = true
        val p = prefs
        theme = ThemeMode.of(p.getString("theme", null))
        accent = AccentChoice.of(p.getString("accent", null))
        listStyle = GalleryListStyle.of(p.getString("listStyle", null))
        phoneColumnsPortrait = portraitColumns(p.intOrNull("phoneColumnsPortrait")) ?: 2
        phoneColumnsLandscape = landscapeColumns(p.intOrNull("phoneColumnsLandscape")) ?: 4
        padColumnsPortrait = portraitColumns(p.intOrNull("padColumnsPortrait")) ?: 3
        padColumnsLandscape = landscapeColumns(p.intOrNull("padColumnsLandscape")) ?: 5
        blurCovers = p.getBoolean("blurCovers", false)
        showTags = p.getBoolean("showTags", true)
        translateTags = if (p.contains("translateTags")) p.getBoolean("translateTags", false)
        else java.util.Locale.getDefault().language == "zh"
        homeLanguage = LanguageFilter.of(p.getString("homeLanguage", null))
        homeSort = SearchSort.of(p.getString("homeSort", null), SearchSort.Recent)
        searchLanguage = LanguageFilter.of(p.getString("searchLanguage", null))
        searchSort = SearchSort.of(p.getString("searchSort", null), SearchSort.Popular)
        readMode = ReadMode.of(p.getString("readMode", null))
        autoReadInterval = p.getFloat("autoReadInterval", 3f).toDouble()
        preloadPages = p.getInt("preloadPages", 4)
        tapToTurnPages = p.getBoolean("tapToTurnPages", true)
        animatePageTurns = p.getBoolean("animatePageTurns", true)
        pageGap = p.getFloat("pageGap", 6f).toDouble()
        keepScreenOn = p.getBoolean("keepScreenOn", true)
        detectClipboard = p.getBoolean("detectClipboard", false)
        tabBarPosition = TabBarPosition.of(p.getString("tabBarPosition", null))
        followHand = p.getBoolean("followHand", false)
        followSpeed = FollowSpeed.of(p.getString("followSpeed", null))
        saveSearchHistory = p.getBoolean("saveSearchHistory", true)
        hideBarsOnScroll = p.getBoolean("hideBarsOnScroll", true)
        readerControlsDelay = p.getFloat("readerControlsDelay", 3f).toDouble().coerceIn(3.0, 10.0)
        libraryStyle = LibraryStyle.of(p.getString("libraryStyle", null))
        recentSearches.clear()
        p.getString("recentSearches", null)?.let { text ->
            runCatching { recentSearches.addAll(json.decodeFromString(ListSerializer(String.serializer()), text)) }
        }
        loading = false
    }

    private fun SharedPreferences.intOrNull(key: String) = if (contains(key)) getInt(key, 0) else null

    private fun save(key: String, value: Any) {
        if (!::prefs.isInitialized || loading) return
        prefs.edit().apply {
            when (value) {
                is String -> putString(key, value)
                is Int -> putInt(key, value)
                is Boolean -> putBoolean(key, value)
                is Double -> putFloat(key, value.toFloat())
                is Float -> putFloat(key, value)
            }
        }.apply()
    }

    var theme by Pref(ThemeMode.System) { save("theme", it.raw) }
    var accent by Pref(AccentChoice.Blue) { save("accent", it.raw) }
    var listStyle by Pref(GalleryListStyle.Waterfall) { save("listStyle", it.raw) }
    /**
     * Columns of cards in portrait and landscape, a pair for phones and one
     * for tablets (the same keys as the iOS app's iPhone / iPad settings).
     */
    var phoneColumnsPortrait by Pref(2) { save("phoneColumnsPortrait", it) }
    var phoneColumnsLandscape by Pref(4) { save("phoneColumnsLandscape", it) }
    var padColumnsPortrait by Pref(3) { save("padColumnsPortrait", it) }
    var padColumnsLandscape by Pref(5) { save("padColumnsLandscape", it) }

    val PORTRAIT_COLUMNS = 1..6
    val LANDSCAPE_COLUMNS = 1..10

    private fun portraitColumns(value: Int?) = value?.coerceIn(PORTRAIT_COLUMNS)
    private fun landscapeColumns(value: Int?) = value?.coerceIn(LANDSCAPE_COLUMNS)

    /** Columns of cards on a phone or a [tablet] in the orientation. */
    fun columns(tablet: Boolean, landscape: Boolean) = when {
        tablet && landscape -> padColumnsLandscape
        tablet -> padColumnsPortrait
        landscape -> phoneColumnsLandscape
        else -> phoneColumnsPortrait
    }
    var blurCovers by Pref(false) { save("blurCovers", it) }
    var showTags by Pref(true) { save("showTags", it) }
    var translateTags by Pref(false) { save("translateTags", it) }

    var homeLanguage by Pref(LanguageFilter.All) { save("homeLanguage", it.raw) }
    var homeSort by Pref(SearchSort.Recent) { save("homeSort", it.raw) }
    var searchLanguage by Pref(LanguageFilter.All) { save("searchLanguage", it.raw) }
    var searchSort by Pref(SearchSort.Popular) { save("searchSort", it.raw) }

    var readMode by Pref(ReadMode.LeftToRight) { save("readMode", it.raw) }
    var autoReadInterval by Pref(3.0) { save("autoReadInterval", it) }
    var preloadPages by Pref(4) { save("preloadPages", it) }
    var tapToTurnPages by Pref(true) { save("tapToTurnPages", it) }
    var animatePageTurns by Pref(true) { save("animatePageTurns", it) }
    /** Gap between pages in the "Continuous with Gaps" mode, in dp. */
    var pageGap by Pref(6.0) { save("pageGap", it) }
    var keepScreenOn by Pref(true) { save("keepScreenOn", it) }
    var detectClipboard by Pref(false) { save("detectClipboard", it) }
    var tabBarPosition by Pref(TabBarPosition.Center) { save("tabBarPosition", it.raw) }
    /** Tablets: the tab bar moves to the side of the hand in use. */
    var followHand by Pref(false) { save("followHand", it) }
    var followSpeed by Pref(FollowSpeed.Fast) { save("followSpeed", it.raw) }
    var saveSearchHistory by Pref(true) { save("saveSearchHistory", it) }
    /** Scrolling a list down slides the tab bar away. */
    var hideBarsOnScroll by Pref(true) { save("hideBarsOnScroll", it) }
    /** Seconds without a touch before the reader's controls hide (3 at least). */
    var readerControlsDelay by Pref(3.0) { save("readerControlsDelay", it) }
    var libraryStyle by Pref(LibraryStyle.Cards) { save("libraryStyle", it.raw) }

    /** Recent search terms, newest first. */
    val recentSearches = mutableStateListOf<String>()
    private val json = kotlinx.serialization.json.Json { ignoreUnknownKeys = true }

    /** Puts [term] first in the search history (when history is on). */
    fun addRecentSearch(term: String) {
        if (!saveSearchHistory) return
        recentSearches.remove(term)
        recentSearches.add(0, term)
        while (recentSearches.size > RECENT_SEARCH_LIMIT) recentSearches.removeAt(recentSearches.lastIndex)
        saveRecentSearches()
    }

    fun removeRecentSearch(term: String) {
        recentSearches.remove(term)
        saveRecentSearches()
    }

    fun clearRecentSearches() {
        recentSearches.clear()
        saveRecentSearches()
    }

    private fun setRecentSearches(items: List<String>) {
        recentSearches.clear()
        recentSearches.addAll(items.take(RECENT_SEARCH_LIMIT))
        saveRecentSearches()
    }

    private fun saveRecentSearches() {
        if (!::prefs.isInitialized || loading) return
        prefs.edit().putString("recentSearches", json.encodeToString(ListSerializer(String.serializer()), recentSearches.toList())).apply()
    }

    private const val RECENT_SEARCH_LIMIT = 20


    /** Every setting, keyed as on iOS (used by export). */
    fun snapshot(): Map<String, Any> = mapOf(
        "theme" to theme.raw,
        "accent" to accent.raw,
        "listStyle" to listStyle.raw,
        "phoneColumnsPortrait" to phoneColumnsPortrait,
        "phoneColumnsLandscape" to phoneColumnsLandscape,
        "padColumnsPortrait" to padColumnsPortrait,
        "padColumnsLandscape" to padColumnsLandscape,
        "blurCovers" to blurCovers,
        "showTags" to showTags,
        "translateTags" to translateTags,
        "homeLanguage" to homeLanguage.raw,
        "homeSort" to homeSort.raw,
        "searchLanguage" to searchLanguage.raw,
        "searchSort" to searchSort.raw,
        "readMode" to readMode.raw,
        "autoReadInterval" to autoReadInterval,
        "preloadPages" to preloadPages,
        "tapToTurnPages" to tapToTurnPages,
        "animatePageTurns" to animatePageTurns,
        "pageGap" to pageGap,
        "keepScreenOn" to keepScreenOn,
        "detectClipboard" to detectClipboard,
        "tabBarPosition" to tabBarPosition.raw,
        "followHand" to followHand,
        "followSpeed" to followSpeed.raw,
        "saveSearchHistory" to saveSearchHistory,
        "hideBarsOnScroll" to hideBarsOnScroll,
        "readerControlsDelay" to readerControlsDelay,
        "libraryStyle" to libraryStyle.raw,
        "recentSearches" to recentSearches.toList(),
    )

    /** Applies imported settings; unknown keys and invalid values are ignored. */
    fun apply(values: Map<String, Any?>) {
        for ((key, value) in values) {
            val string = value as? String
            val number = value as? Number
            val bool = value as? Boolean
            when (key) {
                "theme" -> string?.let { theme = ThemeMode.of(it) }
                "accent" -> string?.let { accent = AccentChoice.of(it) }
                "listStyle" -> string?.let { listStyle = GalleryListStyle.of(it) }
                "phoneColumnsPortrait" -> number?.let { phoneColumnsPortrait = it.toInt().coerceIn(PORTRAIT_COLUMNS) }
                "phoneColumnsLandscape" -> number?.let { phoneColumnsLandscape = it.toInt().coerceIn(LANDSCAPE_COLUMNS) }
                "padColumnsPortrait" -> number?.let { padColumnsPortrait = it.toInt().coerceIn(PORTRAIT_COLUMNS) }
                "padColumnsLandscape" -> number?.let { padColumnsLandscape = it.toInt().coerceIn(LANDSCAPE_COLUMNS) }
                "blurCovers" -> bool?.let { blurCovers = it }
                "showTags" -> bool?.let { showTags = it }
                "translateTags" -> bool?.let { translateTags = it }
                "homeLanguage" -> string?.let { homeLanguage = LanguageFilter.of(it) }
                "homeSort" -> string?.let { homeSort = SearchSort.of(it, homeSort) }
                "searchLanguage" -> string?.let { searchLanguage = LanguageFilter.of(it) }
                "searchSort" -> string?.let { searchSort = SearchSort.of(it, searchSort) }
                "readMode" -> string?.let { readMode = ReadMode.of(it) }
                "autoReadInterval" -> number?.let { autoReadInterval = it.toDouble().coerceIn(1.0, 10.0) }
                "preloadPages" -> number?.let { preloadPages = it.toInt().coerceIn(1, 10) }
                "tapToTurnPages" -> bool?.let { tapToTurnPages = it }
                "animatePageTurns" -> bool?.let { animatePageTurns = it }
                "pageGap" -> number?.let { pageGap = it.toDouble().coerceIn(2.0, 60.0) }
                "keepScreenOn" -> bool?.let { keepScreenOn = it }
                "detectClipboard" -> bool?.let { detectClipboard = it }
                "tabBarPosition" -> string?.let { tabBarPosition = TabBarPosition.of(it) }
                "followHand" -> bool?.let { followHand = it }
                "followSpeed" -> string?.let { followSpeed = FollowSpeed.of(it) }
                "saveSearchHistory" -> bool?.let { saveSearchHistory = it }
                "hideBarsOnScroll" -> bool?.let { hideBarsOnScroll = it }
                "readerControlsDelay" -> number?.let { readerControlsDelay = it.toDouble().coerceIn(3.0, 10.0) }
                "libraryStyle" -> string?.let { libraryStyle = LibraryStyle.of(it) }
                "recentSearches" -> (value as? List<*>)?.let { list -> setRecentSearches(list.filterIsInstance<String>()) }
            }
        }
    }
}
