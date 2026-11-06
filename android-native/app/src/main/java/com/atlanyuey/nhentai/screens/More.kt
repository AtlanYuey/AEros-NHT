package com.atlanyuey.nhentai.screens

import android.annotation.SuppressLint
import android.content.Intent
import android.net.Uri
import android.text.format.DateUtils
import android.text.format.Formatter
import android.webkit.CookieManager
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import coil3.SingletonImageLoader
import com.atlanyuey.nhentai.BuildConfig
import com.atlanyuey.nhentai.R
import com.atlanyuey.nhentai.core.AccentChoice
import com.atlanyuey.nhentai.core.AppLanguage
import com.atlanyuey.nhentai.core.AppSettings
import com.atlanyuey.nhentai.core.CardSize
import com.atlanyuey.nhentai.core.DownloadRecord
import com.atlanyuey.nhentai.core.Downloads
import com.atlanyuey.nhentai.core.GalleryListStyle
import com.atlanyuey.nhentai.core.L10n
import com.atlanyuey.nhentai.core.LanguageFilter
import com.atlanyuey.nhentai.core.NHHost
import com.atlanyuey.nhentai.core.Net
import com.atlanyuey.nhentai.core.SearchSort
import com.atlanyuey.nhentai.core.Session
import com.atlanyuey.nhentai.core.TagStore
import com.atlanyuey.nhentai.core.ThemeMode
import com.atlanyuey.nhentai.core.tr
import com.atlanyuey.nhentai.ui.components.ActivityIndicator
import com.atlanyuey.nhentai.ui.components.AppIcon
import com.atlanyuey.nhentai.ui.components.ButtonRole
import com.atlanyuey.nhentai.ui.components.ButtonRow
import com.atlanyuey.nhentai.ui.components.CoverView
import com.atlanyuey.nhentai.ui.components.DialogButton
import com.atlanyuey.nhentai.ui.components.EmptyState
import com.atlanyuey.nhentai.ui.components.FooterText
import com.atlanyuey.nhentai.ui.components.GlassSlider
import com.atlanyuey.nhentai.ui.components.GroupedListScreen
import com.atlanyuey.nhentai.ui.components.LargeTitle
import com.atlanyuey.nhentai.ui.components.ListRow
import com.atlanyuey.nhentai.ui.components.LocalNavigator
import com.atlanyuey.nhentai.ui.components.LocalOverlays
import com.atlanyuey.nhentai.ui.components.MenuItem
import com.atlanyuey.nhentai.ui.components.PickerRow
import com.atlanyuey.nhentai.ui.components.RemoteImage
import com.atlanyuey.nhentai.ui.components.Screen
import com.atlanyuey.nhentai.ui.components.ScreenScaffold
import com.atlanyuey.nhentai.ui.components.SegmentedControl
import com.atlanyuey.nhentai.ui.components.SettingsIcon
import com.atlanyuey.nhentai.ui.components.ToggleRow
import com.atlanyuey.nhentai.ui.components.Txt
import com.atlanyuey.nhentai.ui.components.anchor
import com.atlanyuey.nhentai.ui.components.rememberAnchor
import com.atlanyuey.nhentai.ui.components.section
import com.atlanyuey.nhentai.ui.theme.AppTheme
import com.atlanyuey.nhentai.ui.theme.Icons
import com.atlanyuey.nhentai.ui.theme.Type
import com.atlanyuey.nhentai.ui.theme.color
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.longOrNull
import java.text.DateFormat
import java.util.Date
import java.util.Locale

private val SettingsBlue = Color(0xFF007AFF)

// MARK: - More

class MoreScreen : Screen() {
    private val list = LazyListState()

    @Composable
    override fun Content() {
        val navigator = LocalNavigator.current
        GroupedListScreen(tr("More"), list, largeTitle = true) {
            section {
                if (Session.isLoggedIn) {
                    ListRow(
                        Session.user?.username ?: tr("Logged In"),
                        subtitle = tr("nhentai account"),
                        leading = { Avatar(Session.user?.avatar, 56) },
                        chevron = true,
                        last = true,
                        minHeight = 76.dp,
                        onClick = { navigator.push(AccountScreen()) },
                    )
                } else {
                    ListRow(
                        tr("Log In"),
                        subtitle = tr("Sync favorites and post comments"),
                        leading = { Avatar(null, 56) },
                        chevron = true,
                        last = true,
                        minHeight = 76.dp,
                        onClick = { navigator.push(LoginScreen()) },
                    )
                }
            }
            section {
                val active = Downloads.records.count { it.state == DownloadRecord.DOWNLOADING }
                ListRow(
                    tr("Downloads"),
                    leading = { SettingsIcon(Icons.DownloadCircle, Color(0xFF34C759)) },
                    value = if (active > 0) "$active" else null,
                    chevron = true, last = true,
                    onClick = { navigator.push(DownloadsScreen()) },
                )
            }
            section {
                SettingsNav(tr("Appearance"), Icons.Palette, SettingsBlue) { AppearanceScreen() }
                SettingsNav(tr("Reading"), Icons.Book, Color(0xFFFF9500)) { ReadingScreen() }
                SettingsNav(tr("General"), Icons.Gear, Color(0xFF8E8E93)) { GeneralScreen() }
                SettingsNav(tr("Settings Backup"), Icons.CloudUpload, Color(0xFF32ADE6), last = true) { BackupScreen() }
            }
            section {
                SettingsNav(tr("Language"), Icons.Globe, Color(0xFF30B0C7)) { LanguageScreen() }
                SettingsNav(tr("About"), Icons.Info, Color(0xFF5856D6), last = true) { AboutScreen() }
            }
        }
    }
}

@Composable
private fun SettingsNav(title: String, icon: ImageVector, color: Color, last: Boolean = false, screen: () -> Screen) {
    val navigator = LocalNavigator.current
    ListRow(title, leading = { SettingsIcon(icon, color) }, chevron = true, last = last, onClick = { navigator.push(screen()) })
}

@Composable
fun Avatar(url: String?, size: Int) {
    Box(Modifier.size(size.dp).clip(CircleShape).background(AppTheme.colors.quaternaryFill), contentAlignment = Alignment.Center) {
        if (url != null) {
            RemoteImage(url, Modifier.fillMaxSize(), targetWidth = (size * 2).dp)
        } else {
            AppIcon(Icons.PersonCircle, null, tint = AppTheme.colors.secondaryLabel, size = size.dp)
        }
    }
}

// MARK: - Account

class AccountScreen : Screen() {
    @Composable
    override fun Content() {
        val navigator = LocalNavigator.current
        val overlays = LocalOverlays.current
        val context = LocalContext.current
        val logoutTitle = tr("Log out of nhentai?")
        val logout = tr("Log Out")
        LaunchedEffect(Unit) { Session.reload() }
        GroupedListScreen(tr("Account")) {
            item {
                Column(Modifier.fillMaxWidth().padding(top = 12.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Avatar(Session.user?.avatar, 96)
                    Txt(Session.user?.username ?: tr("Logged In"), style = Type.title2)
                    Txt(tr("nhentai account"), style = Type.subheadline, color = AppTheme.colors.secondaryLabel)
                }
            }
            Session.user?.let { user ->
                section {
                    ListRow(tr("User ID"), value = "${user.id}")
                    ListRow(tr("Profile"), value = "nhentai.net", chevron = true, last = true, onClick = {
                        context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("${NHHost.SITE}/users/${user.id}/")))
                    })
                }
            }
            section {
                ButtonRow(logout, {
                    overlays.actionSheet(logoutTitle, null, listOf(DialogButton(logout, ButtonRole.Destructive) {
                        Session.logout()
                        navigator.pop()
                    }))
                }, destructive = true, last = true)
            }
        }
    }
}

// MARK: - Login

/**
 * Signs in on nhentai.net in a web view (the site handles its challenge and
 * proof of work); the API tokens are read from the cookies it sets.
 */
class LoginScreen : Screen() {
    private var loading by mutableStateOf(true)
    private var done = false

    @SuppressLint("SetJavaScriptEnabled")
    @Composable
    override fun Content() {
        val navigator = LocalNavigator.current
        ScreenScaffold(
            title = tr("Log In"),
            trailing = { if (loading) ActivityIndicator() },
        ) { padding ->
            AndroidView(
                modifier = Modifier.fillMaxSize().padding(top = padding.calculateTopPadding()),
                factory = { context ->
                    WebView(context).apply {
                        settings.javaScriptEnabled = true
                        settings.domStorageEnabled = true
                        CookieManager.getInstance().setAcceptCookie(true)
                        CookieManager.getInstance().setAcceptThirdPartyCookies(this, true)
                        webViewClient = object : WebViewClient() {
                            override fun onPageStarted(view: WebView?, url: String?, favicon: android.graphics.Bitmap?) {
                                loading = true
                                check()
                            }

                            override fun onPageFinished(view: WebView?, url: String?) {
                                loading = false
                                check()
                            }

                            private fun check() {
                                if (done) return
                                val cookies = CookieManager.getInstance().getCookie(NHHost.SITE) ?: return
                                val map = cookies.split(";").mapNotNull {
                                    val parts = it.trim().split("=", limit = 2)
                                    if (parts.size == 2) parts[0] to Uri.decode(parts[1]) else null
                                }.toMap()
                                val access = map["access_token"]?.takeIf { it.isNotEmpty() } ?: return
                                done = true
                                scope.launch {
                                    Session.login(access, map["refresh_token"])
                                    navigator.pop()
                                }
                            }
                        }
                        loadUrl("${NHHost.SITE}/login/")
                    }
                },
            )
        }
    }
}

// MARK: - Downloads

class DownloadsScreen : Screen() {
    @OptIn(ExperimentalFoundationApi::class)
    @Composable
    override fun Content() {
        val navigator = LocalNavigator.current
        val overlays = LocalOverlays.current
        val context = LocalContext.current
        var usage by remember { mutableStateOf(0L) }
        val records = Downloads.records
        LaunchedEffect(records.size) { usage = withContext(Dispatchers.IO) { Downloads.diskUsage() } }
        val openLabel = tr("Open Gallery Page")
        val deleteLabel = tr("Delete")
        ScreenScaffold(
            title = tr("Downloads"),
            trailing = {
                if (usage > 0) Txt(Formatter.formatShortFileSize(context, usage), style = Type.caption1, color = AppTheme.colors.secondaryLabel)
            },
        ) { padding ->
            LazyColumn(Modifier.fillMaxSize(), contentPadding = padding) {
                if (records.isEmpty()) {
                    item {
                        EmptyState(Icons.DownloadCircle, tr("No Downloads"), tr("Download a gallery from its page to read it offline."))
                    }
                }
                items(records.toList(), key = { it.id }) { record ->
                    val anchor = rememberAnchor()
                    SwipeToDelete(onDelete = { Downloads.delete(record.id) }) {
                        Row(
                            Modifier
                                .fillMaxWidth()
                                .background(AppTheme.colors.background)
                                .anchor(anchor)
                                .combinedClickable(
                                    onClick = { navigator.push(ReaderScreen(ReaderSource.from(record), 0)) },
                                    onLongClick = {
                                        overlays.menu(anchor.bounds, listOf(listOf(
                                            MenuItem(openLabel, Icons.Info) { navigator.push(GalleryScreen(record.id, record.item)) },
                                            MenuItem(deleteLabel, Icons.Trash, destructive = true) { Downloads.delete(record.id) },
                                        )))
                                    },
                                )
                                .padding(horizontal = 16.dp, vertical = 8.dp),
                            horizontalArrangement = Arrangement.spacedBy(14.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            CoverView(record.item, Modifier.width(72.dp), aspectRatio = 0.72f, cornerRadius = 10.dp, targetWidth = 200.dp)
                            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                                Txt(record.item.prettyTitle, style = Type.subheadline.copy(fontWeight = FontWeight.SemiBold), maxLines = 2)
                                if (record.state == DownloadRecord.FINISHED) {
                                    Txt(tr("%lld pages", record.pages.size), style = Type.footnote, color = AppTheme.colors.secondaryLabel)
                                } else {
                                    ProgressBar(record.progress)
                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        Txt("${record.completed} / ${record.pages.size}", Modifier.weight(1f), style = Type.footnote, color = AppTheme.colors.secondaryLabel)
                                        val (label, action) = when (record.state) {
                                            DownloadRecord.DOWNLOADING, DownloadRecord.QUEUED -> tr("Pause") to { Downloads.pause(record.id) }
                                            DownloadRecord.PAUSED -> tr("Resume") to { Downloads.resume(record.id) }
                                            else -> tr("Retry") to { Downloads.resume(record.id) }
                                        }
                                        com.atlanyuey.nhentai.ui.components.TextButton(label, action)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun ProgressBar(progress: Float) {
    Box(Modifier.fillMaxWidth().padding(vertical = 2.dp).clip(RoundedCornerShape(2.dp)).background(AppTheme.colors.tertiaryFill)) {
        Box(
            Modifier
                .fillMaxWidth(progress.coerceIn(0f, 1f))
                .padding(vertical = 2.dp)
                .background(AppTheme.tint),
        )
    }
}

// MARK: - Appearance

class AppearanceScreen : Screen() {
    @Composable
    override fun Content() {
        val navigator = LocalNavigator.current
        val large = LocalConfiguration.current.smallestScreenWidthDp >= 600
        GroupedListScreen(tr("Appearance")) {
            section(header = "Theme") {
                Box(Modifier.padding(16.dp)) {
                    SegmentedControl(ThemeMode.entries, AppSettings.theme, { tr(it.title) }, { AppSettings.theme = it }, Modifier.fillMaxWidth())
                }
                AccentPicker()
            }
            section(header = "Gallery List", footer = { FooterText(tr("Card size applies to the grid and waterfall styles.")) }) {
                PickerRow(tr("List Style"), GalleryListStyle.entries, AppSettings.listStyle, { tr(it.title) }, { AppSettings.listStyle = it })
                val portrait = AppSettings.cardSizePortrait
                val landscape = AppSettings.cardSizeLandscape
                ListRow(
                    tr("Card Size"),
                    value = if (portrait == landscape) tr(portrait.title) else "${tr(portrait.title)} / ${tr(landscape.title)}",
                    chevron = true,
                    onClick = { navigator.push(CardSizeScreen()) },
                )
                ToggleRow(tr("Blur Covers"), AppSettings.blurCovers, { AppSettings.blurCovers = it }, last = true)
            }
            section(footer = { FooterText(tr("Scrolling down a list hides the bars at the top and bottom, and scrolling up shows them again. With Hide Search Too off, a round search button stays.")) }) {
                val hideBars = AppSettings.hideBarsOnScroll
                ToggleRow(tr("Hide Bars When Scrolling"), hideBars, { AppSettings.hideBarsOnScroll = it }, last = !hideBars)
                if (hideBars) {
                    ToggleRow(tr("Hide Search Too"), AppSettings.hideSearchOnScroll, { AppSettings.hideSearchOnScroll = it }, last = true)
                }
            }
            if (large) {
                section(footer = { FooterText(tr("The tab bar moves to the side of the screen you touch: Fast at the first touch, Medium after two touches on that side, Slow after four.")) }) {
                    ToggleRow(tr("Tab Bar Follows Your Hand"), AppSettings.followHand, { AppSettings.followHand = it })
                    if (AppSettings.followHand) {
                        PickerRow(
                            tr("Follow Speed"),
                            com.atlanyuey.nhentai.core.FollowSpeed.entries,
                            AppSettings.followSpeed,
                            { tr(it.title) },
                            { AppSettings.followSpeed = it },
                            last = true,
                        )
                    } else {
                        PickerRow(
                            tr("Tab Bar Position"),
                            com.atlanyuey.nhentai.core.TabBarPosition.entries,
                            AppSettings.tabBarPosition,
                            { tr(it.title) },
                            { AppSettings.tabBarPosition = it },
                            last = true,
                        )
                    }
                }
            }
            section(
                header = "Tags",
                footer = {
                    FooterText(tr("%lld tags, %lld translations (EhTagTranslation). Updated automatically every week.", TagStore.tagCount, TagStore.translationCount))
                },
            ) {
                ToggleRow(tr("Show Tags on Cards"), AppSettings.showTags, { AppSettings.showTags = it })
                ToggleRow(tr("Translate Tags to Chinese"), AppSettings.translateTags, { AppSettings.translateTags = it })
                ListRow(
                    tr("Update Tag Database"),
                    titleColor = if (TagStore.isUpdating) AppTheme.colors.tertiaryLabel else AppTheme.tint,
                    last = true,
                    onClick = if (TagStore.isUpdating) null else ({ scope.launch { TagStore.update() } }),
                ) {
                    if (TagStore.isUpdating) {
                        ActivityIndicator()
                    } else {
                        TagStore.lastUpdated?.let {
                            Txt(
                                DateUtils.getRelativeTimeSpanString(it, System.currentTimeMillis(), DateUtils.MINUTE_IN_MILLIS).toString(),
                                color = AppTheme.colors.secondaryLabel,
                            )
                        }
                    }
                }
            }
        }
    }

    @Composable
    private fun AccentPicker() {
        val dark = AppTheme.isDark
        Row(
            Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()).padding(horizontal = 16.dp, vertical = 12.dp),
            horizontalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            AccentChoice.entries.forEach { choice ->
                val color = choice.color(dark)
                val selected = choice == AppSettings.accent
                Box(
                    Modifier
                        .size(36.dp)
                        .border(2.dp, if (selected) color else Color.Transparent, CircleShape)
                        .padding(3.dp)
                        .clip(CircleShape)
                        .background(color)
                        .clickable { AppSettings.accent = choice },
                    contentAlignment = Alignment.Center,
                ) {
                    if (selected) AppIcon(Icons.Check, null, tint = Color.White, size = 14.dp)
                }
            }
        }
    }
}

class CardSizeScreen : Screen() {
    @Composable
    override fun Content() {
        GroupedListScreen(tr("Card Size")) {
            section(header = "Portrait") { CardSizeEditor(false) }
            section(
                header = "Landscape · follows split view",
                footer = {
                    FooterText(tr("Columns are calculated from the width of the pane: rotating, Split View and Stage Manager add or remove columns automatically. “Standard” matches the automatic column count."))
                },
            ) { CardSizeEditor(true) }
        }
    }

    @Composable
    private fun CardSizeEditor(landscape: Boolean) {
        val configuration = LocalConfiguration.current
        val size = if (landscape) AppSettings.cardSizeLandscape else AppSettings.cardSizePortrait
        val short = minOf(configuration.screenWidthDp, configuration.screenHeightDp)
        val long = maxOf(configuration.screenWidthDp, configuration.screenHeightDp)
        val width = (if (landscape) long else short) - 32f
        val style = AppSettings.listStyle
        val columns = size.columns(width, style.preferredCardWidth, 12f)
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            GlassSlider(size.raw.toFloat(), { value ->
                val next = CardSize.of(Math.round(value))
                if (landscape) AppSettings.cardSizeLandscape = next else AppSettings.cardSizePortrait = next
            }, 0f..4f)
            Txt(tr(size.title), Modifier.fillMaxWidth(), style = Type.subheadline.copy(fontWeight = FontWeight.SemiBold), color = AppTheme.tint, align = TextAlign.Center)
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(18.dp)) {
                MiniScreen(columns, landscape, style != GalleryListStyle.Grid)
                Column {
                    Txt("$columns", style = Type.largeTitle)
                    Txt(tr("columns"), style = Type.subheadline, color = AppTheme.colors.secondaryLabel)
                }
            }
        }
    }

    @Composable
    private fun MiniScreen(columns: Int, landscape: Boolean, waterfall: Boolean) {
        val colors = AppTheme.colors
        val tint = AppTheme.tint
        Canvas(Modifier.size(if (landscape) 170.dp else 78.dp, if (landscape) 82.dp else 160.dp)) {
            drawRoundRect(colors.background, cornerRadius = CornerRadius(10.dp.toPx()))
            drawRoundRect(colors.separator, cornerRadius = CornerRadius(10.dp.toPx()), style = Stroke(1.dp.toPx()))
            val pad = 5.dp.toPx()
            val gap = 3.dp.toPx()
            val n = maxOf(1, columns)
            val width = (size.width - pad * 2 - gap * (n - 1)) / n
            val ratios = floatArrayOf(1.4f, 1.15f, 1.55f, 1.25f, 1.05f, 1.45f)
            for (column in 0 until n) {
                var y = pad + 6.dp.toPx()
                var index = column
                while (y < size.height - pad) {
                    val height = width * if (waterfall) ratios[index % ratios.size] else 1.33f
                    val visible = minOf(height, size.height - pad - y)
                    drawRoundRect(
                        tint.copy(alpha = 0.25f + 0.1f * (index % 3)),
                        topLeft = Offset(pad + column * (width + gap), y),
                        size = Size(width, visible),
                        cornerRadius = CornerRadius(2.dp.toPx()),
                    )
                    y += height + gap
                    index += n
                }
            }
        }
    }
}

// MARK: - Reading / General

class ReadingScreen : Screen() {
    @Composable
    override fun Content() {
        GroupedListScreen(tr("Reading")) { readingSettings() }
    }
}

class GeneralScreen : Screen() {
    @Composable
    override fun Content() {
        val context = LocalContext.current
        val overlays = LocalOverlays.current
        var cache by remember { mutableStateOf<Long?>(null) }
        val refresh: suspend () -> Unit = {
            cache = withContext(Dispatchers.IO) { SingletonImageLoader.get(context).diskCache?.size ?: 0L }
        }
        LaunchedEffect(Unit) { refresh() }
        val clearTitle = tr("Clear the image cache?")
        val clearLabel = tr("Clear Image Cache")
        GroupedListScreen(tr("General")) {
            section(header = "Home") {
                PickerRow(tr("Language"), LanguageFilter.entries, AppSettings.homeLanguage, { tr(it.title) }, { AppSettings.homeLanguage = it })
                PickerRow(tr("Sort"), SearchSort.entries, AppSettings.homeSort, { tr(it.title) }, { AppSettings.homeSort = it }, last = true)
            }
            section(
                header = "Search",
                footer = { FooterText(tr("Recent searches show when you start a search. When this is off, new searches aren't saved and the list is hidden.")) },
            ) {
                PickerRow(tr("Language"), LanguageFilter.entries, AppSettings.searchLanguage, { tr(it.title) }, { AppSettings.searchLanguage = it })
                PickerRow(tr("Sort"), SearchSort.entries, AppSettings.searchSort, { tr(it.title) }, { AppSettings.searchSort = it })
                ToggleRow(tr("Save Search History"), AppSettings.saveSearchHistory, { AppSettings.saveSearchHistory = it }, last = true)
            }
            section(footer = { FooterText(tr("When you return to the app, offer to open an nhentai link found on the clipboard.")) }) {
                ToggleRow(tr("Detect Gallery Links"), AppSettings.detectClipboard, { AppSettings.detectClipboard = it }, last = true)
            }
            section(header = "Storage") {
                ListRow(tr("Image Cache"), value = cache?.let { Formatter.formatShortFileSize(context, it) }) {
                    if (cache == null) ActivityIndicator()
                }
                ButtonRow(clearLabel, {
                    overlays.actionSheet(clearTitle, null, listOf(DialogButton(clearLabel, ButtonRole.Destructive) {
                        val loader = SingletonImageLoader.get(context)
                        loader.memoryCache?.clear()
                        loader.diskCache?.clear()
                        scope.launch { refresh() }
                    }))
                }, destructive = true, last = true)
            }
        }
    }
}

// MARK: - Backup (export / import, the same file as the iOS app)

class BackupScreen : Screen() {
    @Composable
    override fun Content() {
        val context = LocalContext.current
        val overlays = LocalOverlays.current
        val importTitle = tr("Import Settings")
        val imported = tr("The settings were imported.")
        val exporter = rememberLauncherForActivityResult(ActivityResultContracts.CreateDocument("application/json")) { uri ->
            if (uri != null) {
                runCatching {
                    context.contentResolver.openOutputStream(uri)?.use { out ->
                        out.write(settingsJson().toByteArray())
                    }
                }
            }
        }
        val importer = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
            if (uri != null) {
                val result = runCatching {
                    val text = context.contentResolver.openInputStream(uri)?.use { it.readBytes().decodeToString() } ?: ""
                    val o = Net.json.parseToJsonElement(text) as JsonObject
                    AppSettings.apply(
                        o.mapValues { (_, v) ->
                            when (v) {
                                is JsonPrimitive -> v.booleanOrNull ?: v.longOrNull ?: v.doubleOrNull ?: v.content
                                is kotlinx.serialization.json.JsonArray -> v.mapNotNull { (it as? JsonPrimitive)?.content }
                                else -> null
                            }
                        },
                    )
                }
                overlays.alert(importTitle, if (result.isSuccess) imported else result.exceptionOrNull()?.localizedMessage)
            }
        }
        val fileName = L10n.string("AEros-NHT Settings") + ".json"
        GroupedListScreen(tr("Settings Backup")) {
            section(footer = {
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    FooterText(tr("Save the settings as a file and import it on another device. The file also works with the iOS app."))
                    FooterText(tr("Android's own backup also keeps these settings."))
                }
            }) {
                ListRow(tr("Export Settings"), leading = { AppIcon(Icons.Share, null, tint = AppTheme.tint) }, onClick = { exporter.launch(fileName) })
                ListRow(tr("Import Settings"), leading = { AppIcon(Icons.Folder, null, tint = AppTheme.tint) }, last = true, onClick = {
                    importer.launch(arrayOf("application/json", "text/plain", "*/*"))
                })
            }
        }
    }

    private fun settingsJson(): String {
        val o = kotlinx.serialization.json.buildJsonObject {
            AppSettings.snapshot().toSortedMap().forEach { (key, value) ->
                when (value) {
                    is Boolean -> put(key, JsonPrimitive(value))
                    is Number -> put(key, JsonPrimitive(value))
                    is List<*> -> put(key, kotlinx.serialization.json.JsonArray(value.map { JsonPrimitive(it.toString()) }))
                    else -> put(key, JsonPrimitive(value.toString()))
                }
            }
        }
        return kotlinx.serialization.json.Json { prettyPrint = true }.encodeToString(JsonObject.serializer(), o)
    }
}

// MARK: - Language

class LanguageScreen : Screen() {
    @Composable
    override fun Content() {
        val context = LocalContext.current
        var selection by remember { mutableStateOf(AppLanguage.selected(context)) }
        val current = Locale.getDefault()
        fun choose(code: String) {
            if (code == selection) return
            selection = code
            AppLanguage.select(context, code)
            if (android.os.Build.VERSION.SDK_INT < 33) (context as? android.app.Activity)?.recreate()
        }
        GroupedListScreen(tr("Language")) {
            section {
                val system = AppLanguage.systemLocale()
                LanguageRow(tr("System Language"), system.getDisplayName(current), selection == "", last = true) { choose("") }
            }
            section(footer = { FooterText(tr("The language can also be chosen for this app in the Settings app.")) }) {
                AppLanguage.all.forEachIndexed { index, option ->
                    val subtitle = Locale.forLanguageTag(option.code).getDisplayName(current)
                    LanguageRow(option.name, subtitle, selection == option.code, last = index == AppLanguage.all.lastIndex) { choose(option.code) }
                }
            }
        }
    }

    @Composable
    private fun LanguageRow(title: String, subtitle: String?, selected: Boolean, last: Boolean, onClick: () -> Unit) {
        ListRow(title, subtitle = subtitle?.takeIf { it != title }, last = last, onClick = onClick) {
            if (selected) AppIcon(Icons.Check, null, tint = AppTheme.tint, size = 18.dp)
        }
    }
}

// MARK: - About

class AboutScreen : Screen() {
    @Composable
    override fun Content() {
        val context = LocalContext.current
        val navigator = LocalNavigator.current
        fun open(url: String) = context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
        GroupedListScreen(tr("About")) {
            item {
                Column(Modifier.fillMaxWidth().padding(top = 16.dp, bottom = 4.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    AboutIcon()
                    Txt("AEros-NHT", style = Type.title2)
                    Txt(tr("Version %@", "${BuildConfig.VERSION_NAME} (${BuildConfig.VERSION_CODE})"), style = Type.subheadline, color = AppTheme.colors.secondaryLabel)
                    Txt(tr("A modified version of eros_n by honjow."), style = Type.footnote, color = AppTheme.colors.secondaryLabel, align = TextAlign.Center)
                }
            }
            section {
                ListRow(tr("Source Code"), value = "GitHub", chevron = true, onClick = { open("https://github.com/AtlanYuey/eros_n") })
                ListRow(tr("Original Project"), value = "honjow/eros_n", chevron = true, onClick = { open("https://github.com/honjow/eros_n") })
                ListRow(tr("Website"), value = "nhentai.net", chevron = true, last = true, onClick = { open(NHHost.SITE) })
            }
            section {
                ListRow(tr("Open Source Licenses"), chevron = true, last = true, onClick = { navigator.push(LicensesScreen()) })
            }
        }
    }
}

private class License(val name: String, val author: String, val license: String, val text: Int?, val url: String)

private val licenses = listOf(
    License("eros_n", "honjow", "Apache License 2.0", R.raw.apache_2_0, "https://github.com/honjow/eros_n"),
    License("Backdrop (AndroidLiquidGlass)", "Kyant", "Apache License 2.0", R.raw.apache_2_0, "https://github.com/Kyant0/AndroidLiquidGlass"),
    License("Telephoto", "Saket Narayan", "Apache License 2.0", R.raw.apache_2_0, "https://github.com/saket/telephoto"),
    License("Coil", "Coil Contributors", "Apache License 2.0", R.raw.apache_2_0, "https://github.com/coil-kt/coil"),
    License("OkHttp", "Square, Inc.", "Apache License 2.0", R.raw.apache_2_0, "https://github.com/square/okhttp"),
    License("Jetpack Compose, AndroidX, Kotlin", "Google, JetBrains", "Apache License 2.0", R.raw.apache_2_0, "https://developer.android.com/jetpack"),
    License("Ionicons", "Ionic", "MIT License", R.raw.ionicons, "https://github.com/ionic-team/ionicons"),
    License("Inter", "The Inter Project Authors", "SIL Open Font License 1.1", R.raw.inter_ofl, "https://github.com/rsms/inter"),
    License("nhentai_tags_fetcher", "honjow", "MIT License", R.raw.nhentai_tags_fetcher, "https://github.com/honjow/nhentai_tags_fetcher"),
    License("EhTagTranslation Database", "EhTagTranslation", "CC BY-NC-SA 3.0", null, "https://github.com/EhTagTranslation/Database"),
)

class LicensesScreen : Screen() {
    @Composable
    override fun Content() {
        val navigator = LocalNavigator.current
        val context = LocalContext.current
        GroupedListScreen(tr("Open Source Licenses")) {
            section(footer = {
                FooterText(tr("Tag translations come from the EhTagTranslation database, licensed under CC BY-NC-SA 3.0 (attribution, non-commercial, share alike). They are downloaded when the app updates its tags."))
            }) {
                licenses.forEachIndexed { index, license ->
                    ListRow(
                        license.name,
                        subtitle = "${license.author} · ${license.license}",
                        chevron = true,
                        last = index == licenses.lastIndex,
                        onClick = {
                            val text = license.text
                            if (text != null) navigator.push(LicenseTextScreen(license.name, text))
                            else context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(license.url)))
                        },
                    )
                }
            }
        }
    }
}

class LicenseTextScreen(private val title: String, private val resource: Int) : Screen() {
    @Composable
    override fun Content() {
        val context = LocalContext.current
        val text = remember { context.resources.openRawResource(resource).use { it.readBytes().decodeToString() } }
        ScreenScaffold(title = title) { padding ->
            SelectionContainer {
                Txt(
                    text,
                    Modifier
                        .fillMaxSize()
                        .verticalScroll(rememberScrollState())
                        .padding(PaddingValues(start = 16.dp, end = 16.dp, top = padding.calculateTopPadding() + 8.dp, bottom = padding.calculateBottomPadding() + 16.dp)),
                    style = Type.footnote.copy(fontFamily = FontFamily.Monospace),
                )
            }
        }
    }
}
