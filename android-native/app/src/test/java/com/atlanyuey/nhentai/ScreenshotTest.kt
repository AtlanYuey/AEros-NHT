package com.atlanyuey.nhentai

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Shader
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onRoot
import androidx.test.core.app.ApplicationProvider
import coil3.ImageLoader
import coil3.SingletonImageLoader
import coil3.asImage
import coil3.decode.DataSource
import coil3.intercept.Interceptor
import coil3.request.ImageResult
import coil3.request.SuccessResult
import com.atlanyuey.nhentai.core.AppSettings
import com.atlanyuey.nhentai.core.GalleryListStyle
import com.atlanyuey.nhentai.core.Net
import com.atlanyuey.nhentai.core.ThemeMode
import com.atlanyuey.nhentai.screens.GalleryScreen
import com.atlanyuey.nhentai.screens.ReaderScreen
import com.atlanyuey.nhentai.screens.ReaderSource
import com.atlanyuey.nhentai.ui.RootView
import com.atlanyuey.nhentai.ui.Tabs
import com.atlanyuey.nhentai.ui.theme.AppTheme
import com.github.takahirom.roborazzi.captureRoboImage
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.Protocol
import okhttp3.Response
import okhttp3.ResponseBody.Companion.toResponseBody
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import kotlin.math.abs

/** Renders the main screens with sample data (no network) to build/screens/. */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [36], qualifiers = "w393dp-h852dp-xxhdpi")
class ScreenshotTest {
    @get:Rule
    val compose = createComposeRule()

    @Before
    fun setUp() {
        if (Net.interceptors.isEmpty()) Net.interceptors.add(FakeApi)
        val context = ApplicationProvider.getApplicationContext<android.content.Context>()
        SingletonImageLoader.setUnsafe(ImageLoader.Builder(context).components { add(FakeImages) }.build())
        AppSettings.theme = ThemeMode.Light
        AppSettings.listStyle = GalleryListStyle.Waterfall
    }

    private fun shoot(
        name: String,
        tabs: Tabs = Tabs(),
        tab: Int = 0,
        settle: Long = 1500,
        overlays: com.atlanyuey.nhentai.ui.components.OverlayController = com.atlanyuey.nhentai.ui.components.OverlayController(),
    ) {
        compose.setContent { AppTheme { RootView(mutableStateOf(null), tabs, tab, overlays) } }
        compose.waitForIdle()
        Thread.sleep(300)
        compose.mainClock.advanceTimeBy(settle)
        compose.waitForIdle()
        compose.onRoot().captureRoboImage("build/screens/$name.png")
    }

    @Test fun home() = shoot("01_home")

    @Test fun homeDark() {
        AppSettings.theme = ThemeMode.Dark
        shoot("02_home_dark")
    }

    @Test fun homeCompact() {
        AppSettings.listStyle = GalleryListStyle.Compact
        shoot("03_home_compact")
    }

    @Test fun gallery() {
        val tabs = Tabs()
        tabs.home.push(GalleryScreen(500001, null))
        shoot("04_gallery", tabs)
    }

    @Test fun reader() {
        val tabs = Tabs()
        val source = ReaderSource(
            500001, "Sample Gallery", (0 until 24).map { com.atlanyuey.nhentai.screens.ReaderPage(it, "https://i.nhentai.net/galleries/9/${it + 1}.jpg", 0.7f) },
            "https://nhentai.net/g/500001/", com.atlanyuey.nhentai.core.GalleryItem(500001), 24,
        )
        tabs.home.push(ReaderScreen(source, 3))
        shoot("05_reader", tabs)
    }

    @Test fun more() = shoot("06_more", tab = 3)

    @Test fun search() = shoot("07_search", tab = 4)

    @Test fun history() = shoot("08_history", tab = 2)

    @Test fun appearance() {
        val tabs = Tabs()
        tabs.more.push(com.atlanyuey.nhentai.screens.AppearanceScreen())
        shoot("09_appearance", tabs, tab = 3)
    }

    @Test fun menu() {
        val overlays = com.atlanyuey.nhentai.ui.components.OverlayController()
        val density = 3f
        overlays.menu(
            androidx.compose.ui.geometry.Rect(333f * density, 6f * density, 377f * density, 50f * density),
            listOf(
                com.atlanyuey.nhentai.core.SearchSort.entries.map {
                    com.atlanyuey.nhentai.ui.components.MenuItem(it.title, checked = it == com.atlanyuey.nhentai.core.SearchSort.Recent) {}
                },
            ),
            title = "Sort",
        )
        shoot("11_menu", overlays = overlays)
    }

    @Test fun alert() {
        val overlays = com.atlanyuey.nhentai.ui.components.OverlayController()
        overlays.alert(
            "Open Gallery?", "The clipboard contains a link to gallery #500001.",
            listOf(
                com.atlanyuey.nhentai.ui.components.DialogButton("Cancel", com.atlanyuey.nhentai.ui.components.ButtonRole.Cancel),
                com.atlanyuey.nhentai.ui.components.DialogButton("Open", com.atlanyuey.nhentai.ui.components.ButtonRole.Preferred),
            ),
        )
        shoot("12_alert", overlays = overlays)
    }

    @Config(qualifiers = "+zh-rCN")
    @Test fun galleryChinese() {
        AppSettings.theme = ThemeMode.Dark
        val tabs = Tabs()
        tabs.home.push(GalleryScreen(500001, null))
        shoot("13_gallery_zh_dark", tabs)
    }

    @Test fun reading() {
        val tabs = Tabs()
        tabs.more.push(com.atlanyuey.nhentai.screens.ReadingScreen())
        shoot("10_reading", tabs, tab = 3)
    }
}

/** Colorful sample covers / pages, different for every URL. */
private object FakeImages : Interceptor {
    override suspend fun intercept(chain: Interceptor.Chain): ImageResult {
        val seed = abs(chain.request.data.toString().hashCode())
        val width = 360
        val height = 360 * (130 + seed % 50) / 100
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val hue = (seed % 360).toFloat()
        val a = android.graphics.Color.HSVToColor(floatArrayOf(hue, 0.55f, 0.95f))
        val b = android.graphics.Color.HSVToColor(floatArrayOf((hue + 60) % 360, 0.7f, 0.55f))
        val paint = Paint().apply { shader = LinearGradient(0f, 0f, width.toFloat(), height.toFloat(), a, b, Shader.TileMode.CLAMP) }
        canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), paint)
        val circle = Paint().apply { color = android.graphics.Color.argb(150, 255, 255, 255); isAntiAlias = true }
        canvas.drawCircle(width * 0.65f, height * 0.35f, width * 0.22f, circle)
        circle.color = android.graphics.Color.argb(120, 0, 0, 0)
        canvas.drawRect(width * 0.1f, height * 0.6f, width * 0.8f, height * 0.75f, circle)
        return SuccessResult(image = bitmap.asImage(), request = chain.request, dataSource = DataSource.MEMORY)
    }
}

/** Sample API responses. */
private object FakeApi : okhttp3.Interceptor {
    private val titles = listOf(
        "[Sample Circle (Artist)] Summer Vacation Story [English]",
        "(C104) [Moonlight Club] Night Walk",
        "[Studio Aoi] Rainy Day Café",
        "Daily Life in the City (Original) [Chinese]",
        "[Hoshizora] The Library at Midnight",
        "[Circle Kaze] Festival",
        "Weekend Trip",
        "[Akane] Letters",
        "[Sora Works] Seaside Town Chronicle Vol. 2 [Digital]",
        "Snow Mountain",
        "[Yoru] After School",
        "[Kumo] Garden",
    )

    private fun item(i: Int): String {
        val lang = listOf(6346, 29963, 12227)[i % 3]
        val height = listOf(500, 470, 540, 495, 520, 480)[i % 6]
        return """{"id":${500000 + i},"media_id":"${100 + i}","english_title":"${titles[i % titles.size]}","japanese_title":"サンプル $i",""" +
            """"thumbnail":"galleries/${100 + i}/thumb.jpg","thumbnail_width":350,"thumbnail_height":$height,""" +
            """"num_pages":${20 + i},"num_favorites":${1000 + i * 37},"tag_ids":[$lang,17249],"blacklisted":false}"""
    }

    private fun list(count: Int, offset: Int = 0) = (0 until count).joinToString(",") { item(it + offset) }

    private val detail = """{"id":500001,"media_id":"101","title":{"english":"[Sample Circle (Artist)] Summer Vacation Story [English]",""" +
        """"japanese":"[サンプルサークル (アーティスト)] 夏休みの物語 [英訳]","pretty":"Summer Vacation Story"},""" +
        """"cover":{"path":"galleries/101/cover.jpg","width":350,"height":500},"thumbnail":{"path":"galleries/101/thumb.jpg","width":350,"height":500},""" +
        """"upload_date":1762300000,"num_pages":24,"num_favorites":1234,"is_favorited":false,"tags":[""" +
        """{"id":33173,"type":"category","name":"doujinshi","url":"/category/doujinshi/","count":523000},""" +
        """{"id":12227,"type":"language","name":"english","url":"/language/english/","count":150000},""" +
        """{"id":17249,"type":"language","name":"translated","url":"/language/translated/","count":200000},""" +
        """{"id":1,"type":"tag","name":"summer","url":"/tag/summer/","count":2400},""" +
        """{"id":2,"type":"tag","name":"beach","url":"/tag/beach/","count":5100},""" +
        """{"id":3,"type":"tag","name":"comedy","url":"/tag/comedy/","count":12000},""" +
        """{"id":4,"type":"tag","name":"school uniform","url":"/tag/school-uniform/","count":61000},""" +
        """{"id":5,"type":"tag","name":"glasses","url":"/tag/glasses/","count":48000},""" +
        """{"id":6,"type":"parody","name":"original","url":"/parody/original/","count":300000},""" +
        """{"id":7,"type":"artist","name":"artist","url":"/artist/artist/","count":120},""" +
        """{"id":8,"type":"group","name":"sample circle","url":"/group/sample-circle/","count":80}],""" +
        """"pages":[${(1..24).joinToString(",") { """{"number":$it,"path":"galleries/101/$it.jpg","width":1280,"height":1810,"thumbnail":"galleries/101/${it}t.jpg"}""" }}],""" +
        """"related":[${list(6, 6)}]}"""

    private val comments = """{"result":[""" + (1..3).joinToString(",") {
        """{"id":$it,"poster":{"id":$it,"username":"reader$it","avatar_url":""},"post_date":1762300000,"body":"Great work! Comment number $it with some text to show how bubbles wrap across lines."}"""
    } + """],"num_pages":1}"""

    override fun intercept(chain: okhttp3.Interceptor.Chain): Response {
        val url = chain.request().url
        val path = url.encodedPath
        val body = when {
            path.endsWith("/galleries/popular") -> "[${list(8, 4)}]"
            path.contains("/comments") -> comments
            Regex("/galleries/\\d+$").containsMatchIn(path) -> detail
            path.endsWith("/galleries") || path.endsWith("/search") -> """{"result":[${list(12)}],"num_pages":5,"total":1234}"""
            path.endsWith("/user") -> """{"id":1,"username":"tester","avatar_url":""}"""
            else -> "[]"
        }
        return Response.Builder()
            .request(chain.request())
            .protocol(Protocol.HTTP_1_1)
            .code(200)
            .message("OK")
            .body(body.toResponseBody("application/json".toMediaType()))
            .build()
    }
}
