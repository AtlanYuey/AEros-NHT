package com.atlanyuey.nhentai.core

import android.content.Context
import android.content.SharedPreferences
import androidx.compose.runtime.mutableStateOf
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
enum class TabBarPosition(val raw: String, val title: String) {
    Automatic("automatic", "Automatic"),
    Leading("leading", "Left"),
    Center("center", "Center"),
    Trailing("trailing", "Right");

    companion object {
        fun of(raw: String?) = entries.firstOrNull { it.raw == raw } ?: Automatic
    }
}

/** Follows the hand in use: the side of the screen touched last. */
object HandTracker {
    enum class Side { Leading, Center, Trailing }

    var side by androidx.compose.runtime.mutableStateOf(Side.Trailing)
        private set

    /** A touch at [fraction] of the screen width (0 = left edge); touches near the middle keep the side. */
    fun record(fraction: Float) {
        side = when {
            fraction > 0.6f -> Side.Trailing
            fraction < 0.4f -> Side.Leading
            else -> return
        }
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

/**
 * How large gallery cards are: scales the preferred card width. Every step
 * changes the column count by at least one until a single column is left;
 * `Standard` keeps the automatic count.
 */
enum class CardSize(val raw: Int, val scale: Float, val title: String) {
    Small(0, 0.62f, "Small"),
    Smaller(1, 0.8f, "Smaller"),
    Standard(2, 1f, "Standard"),
    Larger(3, 1.3f, "Larger"),
    Large(4, 1.75f, "Large");

    fun columns(width: Float, preferred: Float, spacing: Float): Int {
        fun count(scale: Float) = max(1, ceil(width / (preferred * scale + spacing)).toInt())
        val standardCount = count(1f)
        if (this == Standard) return standardCount
        var columns = standardCount
        val step = if (raw < Standard.raw) -1 else 1
        var index = Standard.raw + step
        while (if (step < 0) index >= raw else index <= raw) {
            val scaled = count(of(index).scale)
            columns = if (step < 0) max(scaled, columns + 1) else max(1, min(scaled, columns - 1))
            index += step
        }
        return columns
    }

    companion object {
        fun of(raw: Int?) = entries.firstOrNull { it.raw == raw } ?: Standard
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
        cardSizePortrait = CardSize.of(p.intOrNull("cardSizePortrait"))
        cardSizeLandscape = CardSize.of(p.intOrNull("cardSizeLandscape"))
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
    var cardSizePortrait by Pref(CardSize.Standard) { save("cardSizePortrait", it.raw) }
    var cardSizeLandscape by Pref(CardSize.Standard) { save("cardSizeLandscape", it.raw) }
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
    var tabBarPosition by Pref(TabBarPosition.Automatic) { save("tabBarPosition", it.raw) }

    fun cardSize(landscape: Boolean) = if (landscape) cardSizeLandscape else cardSizePortrait

    /** Every setting, keyed as on iOS (used by export). */
    fun snapshot(): Map<String, Any> = mapOf(
        "theme" to theme.raw,
        "accent" to accent.raw,
        "listStyle" to listStyle.raw,
        "cardSizePortrait" to cardSizePortrait.raw,
        "cardSizeLandscape" to cardSizeLandscape.raw,
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
                "cardSizePortrait" -> number?.let { cardSizePortrait = CardSize.of(it.toInt()) }
                "cardSizeLandscape" -> number?.let { cardSizeLandscape = CardSize.of(it.toInt()) }
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
            }
        }
    }
}
