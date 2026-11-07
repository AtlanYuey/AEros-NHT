// Generated from Ionicons (MIT License, Copyright (c) 2015-present Ionic, https://ionic.io/ionicons).
// Do not edit by hand: regenerate with convert.py.
package com.atlanyuey.nhentai.ui.theme

import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.vector.PathParser
import androidx.compose.ui.unit.dp

/** Icons in an iOS-like style (Ionicons), 512 x 512 viewport. */
object Icons {
    private class P(val d: String, val fill: Boolean, val stroke: Float, val cap: StrokeCap, val join: StrokeJoin)

    private fun p(d: String, fill: Boolean, stroke: Float, cap: StrokeCap, join: StrokeJoin) =
        P(d, fill, stroke, cap, join)

    private fun icon(name: String, vararg paths: P): ImageVector {
        val builder = ImageVector.Builder(
            name = name, defaultWidth = 24.dp, defaultHeight = 24.dp,
            viewportWidth = 512f, viewportHeight = 512f,
        )
        for (path in paths) {
            builder.addPath(
                pathData = PathParser().parsePathString(path.d).toNodes(),
                fill = if (path.fill) SolidColor(Color.Black) else null,
                stroke = if (path.stroke > 0f) SolidColor(Color.Black) else null,
                strokeLineWidth = path.stroke,
                strokeLineCap = path.cap,
                strokeLineJoin = path.join,
            )
        }
        return builder.build()
    }

    val Home: ImageVector by lazy {
        icon(
            "Home",
        p("M80 212v236a16 16 0 0 0 16 16h96V328a24 24 0 0 1 24-24h80a24 24 0 0 1 24 24v136h96a16 16 0 0 0 16-16V212", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round),
        p("M480 256 266.89 52c-5-5.28-16.69-5.34-21.78 0L32 256M400 179V64h-48v69", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        )
    }

    val Heart: ImageVector by lazy {
        icon(
            "Heart",
        p("M352.92 80C288 80 256 144 256 144s-32-64-96.92-64c-52.76 0-94.54 44.14-95.08 96.81-1.1 109.33 86.73 187.08 183 252.42a16 16 0 0 0 18 0c96.26-65.34 184.09-143.09 183-252.42-.54-52.67-42.32-96.81-95.08-96.81", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        )
    }

    val HeartFill: ImageVector by lazy {
        icon(
            "HeartFill",
        p("M256 448a32 32 0 0 1-18-5.57c-78.59-53.35-112.62-89.93-131.39-112.8-40-48.75-59.15-98.8-58.61-153C48.63 114.52 98.46 64 159.08 64c44.08 0 74.61 24.83 92.39 45.51a6 6 0 0 0 9.06 0C278.31 88.81 308.84 64 352.92 64c60.62 0 110.45 50.52 111.08 112.64.54 54.21-18.63 104.26-58.61 153-18.77 22.87-52.8 59.45-131.39 112.8a32 32 0 0 1-18 5.56", fill = true, stroke = 0f, cap = StrokeCap.Butt, join = StrokeJoin.Miter)
        )
    }

    val Clock: ImageVector by lazy {
        icon(
            "Clock",
        p("M256 64C150 64 64 150 64 256s86 192 192 192 192-86 192-192S362 64 256 64Z", fill = false, stroke = 32f, cap = StrokeCap.Butt, join = StrokeJoin.Miter),
        p("M256 128v144h96", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        )
    }

    /** The Me tab: a person in a circle, outlined like the other tab icons. */
    val PersonCircleOutline: ImageVector by lazy {
        icon(
            "PersonCircleOutline",
        p("M448 256c0-106-86-192-192-192S64 150 64 256s86 192 192 192 192-86 192-192Z", fill = false, stroke = 32f, cap = StrokeCap.Butt, join = StrokeJoin.Miter),
        p("M256 140a64 64 0 1 0 0 128a64 64 0 1 0 0-128Z", fill = false, stroke = 32f, cap = StrokeCap.Butt, join = StrokeJoin.Miter),
        p("M128 382c26-38 74-62 128-62s102 24 128 62", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        )
    }

    val Search: ImageVector by lazy {
        icon(
            "Search",
        p("M456.69 421.39 362.6 327.3a173.8 173.8 0 0 0 34.84-104.58C397.44 126.38 319.06 48 222.72 48S48 126.38 48 222.72s78.38 174.72 174.72 174.72A173.8 173.8 0 0 0 327.3 362.6l94.09 94.09a25 25 0 0 0 35.3-35.3M97.92 222.72a124.8 124.8 0 1 1 124.8 124.8 124.95 124.95 0 0 1-124.8-124.8", fill = true, stroke = 0f, cap = StrokeCap.Butt, join = StrokeJoin.Miter)
        )
    }

    val Share: ImageVector by lazy {
        icon(
            "Share",
        p("M336 192h40a40 40 0 0 1 40 40v192a40 40 0 0 1-40 40H136a40 40 0 0 1-40-40V232a40 40 0 0 1 40-40h40M336 128l-80-80-80 80M256 321V48", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        )
    }

    val Close: ImageVector by lazy {
        icon(
            "Close",
        p("m289.94 256 95-95A24 24 0 0 0 351 127l-95 95-95-95a24 24 0 0 0-34 34l95 95-95 95a24 24 0 1 0 34 34l95-95 95 95a24 24 0 0 0 34-34Z", fill = true, stroke = 0f, cap = StrokeCap.Butt, join = StrokeJoin.Miter)
        )
    }

    val Check: ImageVector by lazy {
        icon(
            "Check",
        p("M416 128 192 384l-96-96", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        )
    }

    val ChevronBack: ImageVector by lazy {
        icon(
            "ChevronBack",
        p("M328 112 184 256l144 144", fill = false, stroke = 48f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        )
    }

    val ChevronForward: ImageVector by lazy {
        icon(
            "ChevronForward",
        p("m184 112 144 144-144 144", fill = false, stroke = 48f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        )
    }

    val ChevronDown: ImageVector by lazy {
        icon(
            "ChevronDown",
        p("m112 184 144 144 144-144", fill = false, stroke = 48f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        )
    }

    val ChevronExpand: ImageVector by lazy {
        icon(
            "ChevronExpand",
        p("m136 208 120-104 120 104M136 304l120 104 120-104", fill = false, stroke = 48f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        )
    }

    val Book: ImageVector by lazy {
        icon(
            "Book",
        p("M202.24 74C166.11 56.75 115.61 48.3 48 48a31.36 31.36 0 0 0-17.92 5.33A32 32 0 0 0 16 79.9V366c0 19.34 13.76 33.93 32 33.93 71.07 0 142.36 6.64 185.06 47a4.11 4.11 0 0 0 6.94-3V106.82a15.9 15.9 0 0 0-5.46-12A143 143 0 0 0 202.24 74M481.92 53.3A31.33 31.33 0 0 0 464 48c-67.61.3-118.11 8.71-154.24 26a143.3 143.3 0 0 0-32.31 20.78 15.93 15.93 0 0 0-5.45 12v337.13a3.93 3.93 0 0 0 6.68 2.81c25.67-25.5 70.72-46.82 185.36-46.81a32 32 0 0 0 32-32v-288a32 32 0 0 0-14.12-26.61", fill = true, stroke = 0f, cap = StrokeCap.Butt, join = StrokeJoin.Miter)
        )
    }

    val BookOutline: ImageVector by lazy {
        icon(
            "BookOutline",
        p("M256 160c16-63.16 76.43-95.41 208-96a15.94 15.94 0 0 1 16 16v288a16 16 0 0 1-16 16c-128 0-177.45 25.81-208 64-30.37-38-80-64-208-64-9.88 0-16-8.05-16-17.93V80a15.94 15.94 0 0 1 16-16c131.57.59 192 32.84 208 96M256 160v288", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        )
    }

    val Play: ImageVector by lazy {
        icon(
            "Play",
        p("M133 440a35.37 35.37 0 0 1-17.5-4.67c-12-6.8-19.46-20-19.46-34.33V111c0-14.37 7.46-27.53 19.46-34.33a35.13 35.13 0 0 1 35.77.45l247.85 148.36a36 36 0 0 1 0 61l-247.89 148.4A35.5 35.5 0 0 1 133 440", fill = true, stroke = 0f, cap = StrokeCap.Butt, join = StrokeJoin.Miter)
        )
    }

    val Pause: ImageVector by lazy {
        icon(
            "Pause",
        p("M208 432h-48a16 16 0 0 1-16-16V96a16 16 0 0 1 16-16h48a16 16 0 0 1 16 16v320a16 16 0 0 1-16 16M352 432h-48a16 16 0 0 1-16-16V96a16 16 0 0 1 16-16h48a16 16 0 0 1 16 16v320a16 16 0 0 1-16 16", fill = true, stroke = 0f, cap = StrokeCap.Butt, join = StrokeJoin.Miter)
        )
    }

    val Stop: ImageVector by lazy {
        icon(
            "Stop",
        p("M392 432H120a40 40 0 0 1-40-40V120a40 40 0 0 1 40-40h272a40 40 0 0 1 40 40v272a40 40 0 0 1-40 40", fill = true, stroke = 0f, cap = StrokeCap.Butt, join = StrokeJoin.Miter)
        )
    }

    val ArrowDown: ImageVector by lazy {
        icon(
            "ArrowDown",
        p("m112 268 144 144 144-144M256 392V100", fill = false, stroke = 48f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        )
    }

    val ArrowUp: ImageVector by lazy {
        icon(
            "ArrowUp",
        p("m112 244 144-144 144 144M256 120v292", fill = false, stroke = 48f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        )
    }

    val ArrowForward: ImageVector by lazy {
        icon(
            "ArrowForward",
        p("m268 112 144 144-144 144M392 256H100", fill = false, stroke = 48f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        )
    }

    val Refresh: ImageVector by lazy {
        icon(
            "Refresh",
        p("M320 146s24.36-12-64-12a160 160 0 1 0 160 160", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Miter),
        p("m256 58 80 80-80 80", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        )
    }

    val CheckCircle: ImageVector by lazy {
        icon(
            "CheckCircle",
        p("M256 48C141.31 48 48 141.31 48 256s93.31 208 208 208 208-93.31 208-208S370.69 48 256 48m108.25 138.29-134.4 160a16 16 0 0 1-12 5.71h-.27a16 16 0 0 1-11.89-5.3l-57.6-64a16 16 0 1 1 23.78-21.4l45.29 50.32 122.59-145.91a16 16 0 0 1 24.5 20.58", fill = true, stroke = 0f, cap = StrokeCap.Butt, join = StrokeJoin.Miter)
        )
    }

    val Trash: ImageVector by lazy {
        icon(
            "Trash",
        p("m112 112 20 320c.95 18.49 14.4 32 32 32h184c17.67 0 30.87-13.51 32-32l20-320", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round),
        p("M80 112h352", fill = true, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Miter),
        p("M192 112V72h0a23.93 23.93 0 0 1 24-24h80a23.93 23.93 0 0 1 24 24h0v40M256 176v224M184 176l8 224M328 176l-8 224", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        )
    }

    val Gear: ImageVector by lazy {
        icon(
            "Gear",
        p("M208,256a48,48 0 1,0 96,0a48,48 0 1,0 -96,0Z", fill = true, stroke = 0f, cap = StrokeCap.Butt, join = StrokeJoin.Miter),
        p("m470.39 300-.47-.38-31.56-24.75a16.11 16.11 0 0 1-6.1-13.33v-11.56a16 16 0 0 1 6.11-13.22L469.92 212l.47-.38a26.68 26.68 0 0 0 5.9-34.06l-42.71-73.9a1.6 1.6 0 0 1-.13-.22A26.86 26.86 0 0 0 401 92.14l-.35.13-37.1 14.93a15.94 15.94 0 0 1-14.47-1.29q-4.92-3.1-10-5.86a15.94 15.94 0 0 1-8.19-11.82l-5.59-39.59-.12-.72A27.22 27.22 0 0 0 298.76 26h-85.52a26.92 26.92 0 0 0-26.45 22.39l-.09.56-5.57 39.67a16 16 0 0 1-8.13 11.82 175 175 0 0 0-10 5.82 15.92 15.92 0 0 1-14.43 1.27l-37.13-15-.35-.14a26.87 26.87 0 0 0-32.48 11.34l-.13.22-42.77 73.95a26.71 26.71 0 0 0 5.9 34.1l.47.38 31.56 24.75a16.11 16.11 0 0 1 6.1 13.33v11.56a16 16 0 0 1-6.11 13.22L42.08 300l-.47.38a26.68 26.68 0 0 0-5.9 34.06l42.71 73.9a1.6 1.6 0 0 1 .13.22 26.86 26.86 0 0 0 32.45 11.3l.35-.13 37.07-14.93a15.94 15.94 0 0 1 14.47 1.29q4.92 3.11 10 5.86a15.94 15.94 0 0 1 8.19 11.82l5.56 39.59.12.72A27.22 27.22 0 0 0 213.24 486h85.52a26.92 26.92 0 0 0 26.45-22.39l.09-.56 5.57-39.67a16 16 0 0 1 8.18-11.82c3.42-1.84 6.76-3.79 10-5.82a15.92 15.92 0 0 1 14.43-1.27l37.13 14.95.35.14a26.85 26.85 0 0 0 32.48-11.34 3 3 0 0 1 .13-.22l42.71-73.89a26.7 26.7 0 0 0-5.89-34.11m-134.48-40.24a80 80 0 1 1-83.66-83.67 80.21 80.21 0 0 1 83.66 83.67", fill = true, stroke = 0f, cap = StrokeCap.Butt, join = StrokeJoin.Miter)
        )
    }

    val Text: ImageVector by lazy {
        icon(
            "Text",
        p("m292.6 407.78-120-320a22 22 0 0 0-41.2 0l-120 320a22 22 0 0 0 41.2 15.44l36.16-96.42a2 2 0 0 1 1.87-1.3h122.74a2 2 0 0 1 1.87 1.3l36.16 96.42a22 22 0 0 0 41.2-15.44m-185.84-129 43.37-115.65a2 2 0 0 1 3.74 0l43.37 115.67a2 2 0 0 1-1.87 2.7h-86.74a2 2 0 0 1-1.87-2.7ZM400.77 169.5c-41.72-.3-79.08 23.87-95 61.4a22 22 0 0 0 40.5 17.2c8.88-20.89 29.77-34.44 53.32-34.6 32.32-.22 58.41 26.5 58.41 58.85a1.5 1.5 0 0 1-1.45 1.5c-21.92.61-47.92 2.07-71.12 4.8-54.75 6.44-87.43 36.29-87.43 79.85 0 23.19 8.76 44 24.67 58.68C337.6 430.93 358 438.5 380 438.5c31 0 57.69-8 77.94-23.22h.06a22 22 0 1 0 44 .19v-143c0-56.18-45-102.56-101.23-102.97M380 394.5c-17.53 0-38-9.43-38-36 0-10.67 3.83-18.14 12.43-24.23 8.37-5.93 21.2-10.16 36.14-11.92 21.12-2.49 44.82-3.86 65.14-4.47a2 2 0 0 1 2 2.1C455 370.1 429.46 394.5 380 394.5", fill = true, stroke = 0f, cap = StrokeCap.Butt, join = StrokeJoin.Miter)
        )
    }

    val Globe: ImageVector by lazy {
        icon(
            "Globe",
        p("M256 48C141.13 48 48 141.13 48 256s93.13 208 208 208 208-93.13 208-208S370.87 48 256 48Z", fill = false, stroke = 32f, cap = StrokeCap.Butt, join = StrokeJoin.Miter),
        p("M256 48c-58.07 0-112.67 93.13-112.67 208S197.93 464 256 464s112.67-93.13 112.67-208S314.07 48 256 48Z", fill = false, stroke = 32f, cap = StrokeCap.Butt, join = StrokeJoin.Miter),
        p("M117.33 117.33c38.24 27.15 86.38 43.34 138.67 43.34s100.43-16.19 138.67-43.34M394.67 394.67c-38.24-27.15-86.38-43.34-138.67-43.34s-100.43 16.19-138.67 43.34", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round),
        p("M256 48v416M464 256H48", fill = false, stroke = 32f, cap = StrokeCap.Butt, join = StrokeJoin.Miter)
        )
    }

    val Info: ImageVector by lazy {
        icon(
            "Info",
        p("M256 56C145.72 56 56 145.72 56 256s89.72 200 200 200 200-89.72 200-200S366.28 56 256 56m0 82a26 26 0 1 1-26 26 26 26 0 0 1 26-26m48 226h-88a16 16 0 0 1 0-32h28v-88h-16a16 16 0 0 1 0-32h32a16 16 0 0 1 16 16v104h28a16 16 0 0 1 0 32", fill = true, stroke = 0f, cap = StrokeCap.Butt, join = StrokeJoin.Miter)
        )
    }

    val Cloud: ImageVector by lazy {
        icon(
            "Cloud",
        p("M396 432H136c-36.44 0-70.36-12.57-95.51-35.41C14.38 372.88 0 340 0 304c0-36.58 13.39-68.12 38.72-91.22 18.11-16.53 42.22-28.25 69.18-33.87a16 16 0 0 0 11.37-9.15 156.24 156.24 0 0 1 42.05-56C187.76 91.69 220.5 80 256 80a153.57 153.57 0 0 1 107.14 42.9c24.73 23.81 41.5 55.28 49.18 92a16 16 0 0 0 12.12 12.39C470 237.42 512 270.43 512 328c0 33.39-12.24 60.78-35.41 79.23C456.23 423.43 428.37 432 396 432", fill = true, stroke = 0f, cap = StrokeCap.Butt, join = StrokeJoin.Miter)
        )
    }

    val CloudUpload: ImageVector by lazy {
        icon(
            "CloudUpload",
        p("M320 367.79h76c55 0 100-29.21 100-83.6s-53-81.47-96-83.6c-8.89-85.06-71-136.8-144-136.8-69 0-113.44 45.79-128 91.2-60 5.7-112 43.88-112 106.4s54 106.4 120 106.4h56", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round),
        p("m320 255.79-64-64-64 64M256 448.21V207.79", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        )
    }

    val CloudDownload: ImageVector by lazy {
        icon(
            "CloudDownload",
        p("M320 336h76c55 0 100-21.21 100-75.6s-53-73.47-96-75.6C391.11 99.74 329 48 256 48c-69 0-113.44 45.79-128 91.2-60 5.7-112 35.88-112 98.4S70 336 136 336h56M192 400.1l64 63.9 64-63.9M256 224v224.03", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        )
    }

    val Download: ImageVector by lazy {
        icon(
            "Download",
        p("M376 160H272v153.37l52.69-52.68a16 16 0 0 1 22.62 22.62l-80 80a16 16 0 0 1-22.62 0l-80-80a16 16 0 0 1 22.62-22.62L240 313.37V160H136a56.06 56.06 0 0 0-56 56v208a56.06 56.06 0 0 0 56 56h240a56.06 56.06 0 0 0 56-56V216a56.06 56.06 0 0 0-56-56M272 48a16 16 0 0 0-32 0v112h32Z", fill = true, stroke = 0f, cap = StrokeCap.Butt, join = StrokeJoin.Miter)
        )
    }

    val DownloadCircle: ImageVector by lazy {
        icon(
            "DownloadCircle",
        p("M256 464c114.87 0 208-93.13 208-208S370.87 48 256 48 48 141.13 48 256s93.13 208 208 208m-91.36-212.65a16 16 0 0 1 22.63-.09L240 303.58V170a16 16 0 0 1 32 0v133.58l52.73-52.32A16 16 0 1 1 347.27 274l-80 79.39a16 16 0 0 1-22.54 0l-80-79.39a16 16 0 0 1-.09-22.65", fill = true, stroke = 0f, cap = StrokeCap.Butt, join = StrokeJoin.Miter)
        )
    }

    val PersonCircle: ImageVector by lazy {
        icon(
            "PersonCircle",
        p("M256 48C141.31 48 48 141.31 48 256s93.31 208 208 208 208-93.31 208-208S370.69 48 256 48m-50.22 116.82C218.45 151.39 236.28 144 256 144s37.39 7.44 50.11 20.94c12.89 13.68 19.16 32.06 17.68 51.82C320.83 256 290.43 288 256 288s-64.89-32-67.79-71.25c-1.47-19.92 4.79-38.36 17.57-51.93M256 432a175.5 175.5 0 0 1-126-53.22 122.9 122.9 0 0 1 35.14-33.44C190.63 329 222.89 320 256 320s65.37 9 90.83 25.34A122.9 122.9 0 0 1 382 378.78 175.45 175.45 0 0 1 256 432", fill = true, stroke = 0f, cap = StrokeCap.Butt, join = StrokeJoin.Miter)
        )
    }

    val Person: ImageVector by lazy {
        icon(
            "Person",
        p("M344 144c-3.92 52.87-44 96-88 96s-84.15-43.12-88-96c-4-55 35-96 88-96s92 42 88 96", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round),
        p("M256 304c-87 0-175.3 48-191.64 138.6C62.39 453.52 68.57 464 80 464h352c11.44 0 17.62-10.48 15.65-21.4C431.3 352 343 304 256 304Z", fill = false, stroke = 32f, cap = StrokeCap.Butt, join = StrokeJoin.Miter)
        )
    }

    val Photo: ImageVector by lazy {
        icon(
            "Photo",
        p("M96,80h320a48,48 0 0,1 48,48v256a48,48 0 0,1 -48,48h-320a48,48 0 0,1 -48,-48v-256a48,48 0 0,1 48,-48Z", fill = false, stroke = 32f, cap = StrokeCap.Butt, join = StrokeJoin.Round),
        p("M304,176a32,32 0 1,0 64,0a32,32 0 1,0 -64,0Z", fill = false, stroke = 32f, cap = StrokeCap.Butt, join = StrokeJoin.Miter),
        p("m304 335.79-90.66-90.49a32 32 0 0 0-43.87-1.3L48 352M224 432l123.34-123.34a32 32 0 0 1 43.11-2L464 368", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        )
    }

    val Offline: ImageVector by lazy {
        icon(
            "Offline",
        p("M93.72 183.25C49.49 198.05 16 233.1 16 288c0 66 54 112 120 112h184.37M467.82 377.74C485.24 363.3 496 341.61 496 312c0-59.82-53-85.76-96-88-8.89-89.54-71-144-144-144-26.16 0-48.79 6.93-67.6 18.14", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round),
        p("M448 448 64 64", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Miter)
        )
    }

    val Sliders: ImageVector by lazy {
        icon(
            "Sliders",
        p("M368 128h80M64 128h240M368 384h80M64 384h240M208 256h240M64 256h80", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round),
        p("M304,128a32,32 0 1,0 64,0a32,32 0 1,0 -64,0Z", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round),
        p("M144,256a32,32 0 1,0 64,0a32,32 0 1,0 -64,0Z", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round),
        p("M304,384a32,32 0 1,0 64,0a32,32 0 1,0 -64,0Z", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        )
    }

    val Ellipsis: ImageVector by lazy {
        icon(
            "Ellipsis",
        p("M208,256a48,48 0 1,0 96,0a48,48 0 1,0 -96,0Z", fill = true, stroke = 0f, cap = StrokeCap.Butt, join = StrokeJoin.Miter),
        p("M368,256a48,48 0 1,0 96,0a48,48 0 1,0 -96,0Z", fill = true, stroke = 0f, cap = StrokeCap.Butt, join = StrokeJoin.Miter),
        p("M48,256a48,48 0 1,0 96,0a48,48 0 1,0 -96,0Z", fill = true, stroke = 0f, cap = StrokeCap.Butt, join = StrokeJoin.Miter)
        )
    }

    val Filter: ImageVector by lazy {
        icon(
            "Filter",
        p("m35.4 87.12 168.65 196.44A16.07 16.07 0 0 1 208 294v119.32a7.93 7.93 0 0 0 5.39 7.59l80.15 26.67A7.94 7.94 0 0 0 304 440V294a16.07 16.07 0 0 1 4-10.44L476.6 87.12A14 14 0 0 0 466 64H46.05A14 14 0 0 0 35.4 87.12", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        )
    }

    val Sort: ImageVector by lazy {
        icon(
            "Sort",
        p("M464 208 352 96 240 208M352 113.13V416M48 304l112 112 112-112M160 398V96", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        )
    }

    val Safari: ImageVector by lazy {
        icon(
            "Safari",
        p("M448 256c0-106-86-192-192-192S64 150 64 256s86 192 192 192 192-86 192-192Z", fill = false, stroke = 32f, cap = StrokeCap.Butt, join = StrokeJoin.Miter),
        p("m350.67 150.93-117.2 46.88a64 64 0 0 0-35.66 35.66l-46.88 117.2a8 8 0 0 0 10.4 10.4l117.2-46.88a64 64 0 0 0 35.66-35.66l46.88-117.2a8 8 0 0 0-10.4-10.4M256 280a24 24 0 1 1 24-24 24 24 0 0 1-24 24", fill = true, stroke = 0f, cap = StrokeCap.Butt, join = StrokeJoin.Miter)
        )
    }

    val Copy: ImageVector by lazy {
        icon(
            "Copy",
        p("M185,128h222a57,57 0 0,1 57,57v222a57,57 0 0,1 -57,57h-222a57,57 0 0,1 -57,-57v-222a57,57 0 0,1 57,-57Z", fill = false, stroke = 32f, cap = StrokeCap.Butt, join = StrokeJoin.Round),
        p("m383.5 128 .5-24a56.16 56.16 0 0 0-56-56H112a64.19 64.19 0 0 0-64 64v216a56.16 56.16 0 0 0 56 56h24", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        )
    }

    val Link: ImageVector by lazy {
        icon(
            "Link",
        p("M208 352h-64a96 96 0 0 1 0-192h64M304 160h64a96 96 0 0 1 0 192h-64M163.29 256h187.42", fill = false, stroke = 36f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        )
    }

    val Grid: ImageVector by lazy {
        icon(
            "Grid",
        p("M68,48h136a20,20 0 0,1 20,20v136a20,20 0 0,1 -20,20h-136a20,20 0 0,1 -20,-20v-136a20,20 0 0,1 20,-20Z", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round),
        p("M308,48h136a20,20 0 0,1 20,20v136a20,20 0 0,1 -20,20h-136a20,20 0 0,1 -20,-20v-136a20,20 0 0,1 20,-20Z", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round),
        p("M68,288h136a20,20 0 0,1 20,20v136a20,20 0 0,1 -20,20h-136a20,20 0 0,1 -20,-20v-136a20,20 0 0,1 20,-20Z", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round),
        p("M308,288h136a20,20 0 0,1 20,20v136a20,20 0 0,1 -20,20h-136a20,20 0 0,1 -20,-20v-136a20,20 0 0,1 20,-20Z", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        )
    }

    val ListBullet: ImageVector by lazy {
        icon(
            "ListBullet",
        p("M160 144h288M160 256h288M160 368h288", fill = false, stroke = 48f, cap = StrokeCap.Round, join = StrokeJoin.Round),
        p("M64,144a16,16 0 1,0 32,0a16,16 0 1,0 -32,0Z", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round),
        p("M64,256a16,16 0 1,0 32,0a16,16 0 1,0 -32,0Z", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round),
        p("M64,368a16,16 0 1,0 32,0a16,16 0 1,0 -32,0Z", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        )
    }

    val Albums: ImageVector by lazy {
        icon(
            "Albums",
        p("M92.87,176h326.26a28.87,28.87 0 0,1 28.87,28.87v198.26a28.87,28.87 0 0,1 -28.87,28.87h-326.26a28.87,28.87 0 0,1 -28.87,-28.87v-198.26a28.87,28.87 0 0,1 28.87,-28.87Z", fill = false, stroke = 32f, cap = StrokeCap.Butt, join = StrokeJoin.Round),
        p("M144 80h224M112 128h288", fill = true, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Miter)
        )
    }

    val Apps: ImageVector by lazy {
        icon(
            "Apps",
        p("M104,64h0a40,40 0 0,1 40,40v0a40,40 0 0,1 -40,40h0a40,40 0 0,1 -40,-40v0a40,40 0 0,1 40,-40Z", fill = false, stroke = 32f, cap = StrokeCap.Butt, join = StrokeJoin.Miter),
        p("M256,64h0a40,40 0 0,1 40,40v0a40,40 0 0,1 -40,40h0a40,40 0 0,1 -40,-40v0a40,40 0 0,1 40,-40Z", fill = false, stroke = 32f, cap = StrokeCap.Butt, join = StrokeJoin.Miter),
        p("M408,64h0a40,40 0 0,1 40,40v0a40,40 0 0,1 -40,40h0a40,40 0 0,1 -40,-40v0a40,40 0 0,1 40,-40Z", fill = false, stroke = 32f, cap = StrokeCap.Butt, join = StrokeJoin.Miter),
        p("M104,216h0a40,40 0 0,1 40,40v0a40,40 0 0,1 -40,40h0a40,40 0 0,1 -40,-40v0a40,40 0 0,1 40,-40Z", fill = false, stroke = 32f, cap = StrokeCap.Butt, join = StrokeJoin.Miter),
        p("M256,216h0a40,40 0 0,1 40,40v0a40,40 0 0,1 -40,40h0a40,40 0 0,1 -40,-40v0a40,40 0 0,1 40,-40Z", fill = false, stroke = 32f, cap = StrokeCap.Butt, join = StrokeJoin.Miter),
        p("M408,216h0a40,40 0 0,1 40,40v0a40,40 0 0,1 -40,40h0a40,40 0 0,1 -40,-40v0a40,40 0 0,1 40,-40Z", fill = false, stroke = 32f, cap = StrokeCap.Butt, join = StrokeJoin.Miter),
        p("M104,368h0a40,40 0 0,1 40,40v0a40,40 0 0,1 -40,40h0a40,40 0 0,1 -40,-40v0a40,40 0 0,1 40,-40Z", fill = false, stroke = 32f, cap = StrokeCap.Butt, join = StrokeJoin.Miter),
        p("M256,368h0a40,40 0 0,1 40,40v0a40,40 0 0,1 -40,40h0a40,40 0 0,1 -40,-40v0a40,40 0 0,1 40,-40Z", fill = false, stroke = 32f, cap = StrokeCap.Butt, join = StrokeJoin.Miter),
        p("M408,368h0a40,40 0 0,1 40,40v0a40,40 0 0,1 -40,40h0a40,40 0 0,1 -40,-40v0a40,40 0 0,1 40,-40Z", fill = false, stroke = 32f, cap = StrokeCap.Butt, join = StrokeJoin.Miter)
        )
    }

    val Layers: ImageVector by lazy {
        icon(
            "Layers",
        p("m434.8 137.65-149.36-68.1c-16.19-7.4-42.69-7.4-58.88 0L77.3 137.65c-17.6 8-17.6 21.09 0 29.09l148 67.5c16.89 7.7 44.69 7.7 61.58 0l148-67.5c17.52-8 17.52-21.1-.08-29.09M160 308.52l-82.7 37.11c-17.6 8-17.6 21.1 0 29.1l148 67.5c16.89 7.69 44.69 7.69 61.58 0l148-67.5c17.6-8 17.6-21.1 0-29.1l-79.94-38.47", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round),
        p("m160 204.48-82.8 37.16c-17.6 8-17.6 21.1 0 29.1l148 67.49c16.89 7.7 44.69 7.7 61.58 0l148-67.49c17.7-8 17.7-21.1.1-29.1L352 204.48", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        )
    }

    val EyeOff: ImageVector by lazy {
        icon(
            "EyeOff",
        p("M432 448a15.92 15.92 0 0 1-11.31-4.69l-352-352a16 16 0 0 1 22.62-22.62l352 352A16 16 0 0 1 432 448M255.66 384c-41.49 0-81.5-12.28-118.92-36.5-34.07-22-64.74-53.51-88.7-91v-.08c19.94-28.57 41.78-52.73 65.24-72.21a2 2 0 0 0 .14-2.94L93.5 161.38a2 2 0 0 0-2.71-.12c-24.92 21-48.05 46.76-69.08 76.92a31.92 31.92 0 0 0-.64 35.54c26.41 41.33 60.4 76.14 98.28 100.65C162 402 207.9 416 255.66 416a239.1 239.1 0 0 0 75.8-12.58 2 2 0 0 0 .77-3.31l-21.58-21.58a4 4 0 0 0-3.83-1 204.8 204.8 0 0 1-51.16 6.47M490.84 238.6c-26.46-40.92-60.79-75.68-99.27-100.53C349 110.55 302 96 255.66 96a227.3 227.3 0 0 0-74.89 12.83 2 2 0 0 0-.75 3.31l21.55 21.55a4 4 0 0 0 3.88 1 192.8 192.8 0 0 1 50.21-6.69c40.69 0 80.58 12.43 118.55 37 34.71 22.4 65.74 53.88 89.76 91a.13.13 0 0 1 0 .16 310.7 310.7 0 0 1-64.12 72.73 2 2 0 0 0-.15 2.95l19.9 19.89a2 2 0 0 0 2.7.13 343.5 343.5 0 0 0 68.64-78.48 32.2 32.2 0 0 0-.1-34.78", fill = true, stroke = 0f, cap = StrokeCap.Butt, join = StrokeJoin.Miter),
        p("M256 160a96 96 0 0 0-21.37 2.4 2 2 0 0 0-1 3.38l112.59 112.56a2 2 0 0 0 3.38-1A96 96 0 0 0 256 160M165.78 233.66a2 2 0 0 0-3.38 1 96 96 0 0 0 115 115 2 2 0 0 0 1-3.38Z", fill = true, stroke = 0f, cap = StrokeCap.Butt, join = StrokeJoin.Miter)
        )
    }

    val Tag: ImageVector by lazy {
        icon(
            "Tag",
        p("M435.25 48h-122.9a14.46 14.46 0 0 0-10.2 4.2L56.45 297.9a28.85 28.85 0 0 0 0 40.7l117 117a28.85 28.85 0 0 0 40.7 0L459.75 210a14.46 14.46 0 0 0 4.2-10.2v-123a28.66 28.66 0 0 0-28.7-28.8", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round),
        p("M384 160a32 32 0 1 1 32-32 32 32 0 0 1-32 32", fill = true, stroke = 0f, cap = StrokeCap.Butt, join = StrokeJoin.Miter)
        )
    }

    val Comment: ImageVector by lazy {
        icon(
            "Comment",
        p("M87.49 380c1.19-4.38-1.44-10.47-3.95-14.86a45 45 0 0 0-2.54-3.8 199.8 199.8 0 0 1-33-110C47.65 139.09 140.73 48 255.83 48 356.21 48 440 117.54 459.58 209.85a199 199 0 0 1 4.42 41.64c0 112.41-89.49 204.93-204.59 204.93-18.3 0-43-4.6-56.47-8.37s-26.92-8.77-30.39-10.11a31.1 31.1 0 0 0-11.12-2.07 30.7 30.7 0 0 0-12.09 2.43l-67.83 24.48a16 16 0 0 1-4.67 1.22 9.6 9.6 0 0 1-9.57-9.74 16 16 0 0 1 .6-3.29Z", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Miter)
        )
    }

    val Send: ImageVector by lazy {
        icon(
            "Send",
        p("m476.59 227.05-.16-.07L49.35 49.84A23.56 23.56 0 0 0 27.14 52 24.65 24.65 0 0 0 16 72.59v113.29a24 24 0 0 0 19.52 23.57l232.93 43.07a4 4 0 0 1 0 7.86L35.53 303.45A24 24 0 0 0 16 327v113.31A23.57 23.57 0 0 0 26.59 460a23.94 23.94 0 0 0 13.22 4 24.55 24.55 0 0 0 9.52-1.93L476.4 285.94l.19-.09a32 32 0 0 0 0-58.8", fill = true, stroke = 0f, cap = StrokeCap.Butt, join = StrokeJoin.Miter)
        )
    }

    val Sun: ImageVector by lazy {
        icon(
            "Sun",
        p("M256 118a22 22 0 0 1-22-22V48a22 22 0 0 1 44 0v48a22 22 0 0 1-22 22M256 486a22 22 0 0 1-22-22v-48a22 22 0 0 1 44 0v48a22 22 0 0 1-22 22M369.14 164.86a22 22 0 0 1-15.56-37.55l33.94-33.94a22 22 0 0 1 31.11 31.11l-33.94 33.94a21.93 21.93 0 0 1-15.55 6.44M108.92 425.08a22 22 0 0 1-15.55-37.56l33.94-33.94a22 22 0 1 1 31.11 31.11l-33.94 33.94a21.94 21.94 0 0 1-15.56 6.45M464 278h-48a22 22 0 0 1 0-44h48a22 22 0 0 1 0 44M96 278H48a22 22 0 0 1 0-44h48a22 22 0 0 1 0 44M403.08 425.08a21.94 21.94 0 0 1-15.56-6.45l-33.94-33.94a22 22 0 0 1 31.11-31.11l33.94 33.94a22 22 0 0 1-15.55 37.56M142.86 164.86a21.9 21.9 0 0 1-15.55-6.44l-33.94-33.94a22 22 0 0 1 31.11-31.11l33.94 33.94a22 22 0 0 1-15.56 37.55M256 358a102 102 0 1 1 102-102 102.12 102.12 0 0 1-102 102", fill = true, stroke = 0f, cap = StrokeCap.Butt, join = StrokeJoin.Miter)
        )
    }

    val Moon: ImageVector by lazy {
        icon(
            "Moon",
        p("M264 480A232 232 0 0 1 32 248c0-94 54-178.28 137.61-214.67a16 16 0 0 1 21.06 21.06C181.07 76.43 176 104.66 176 136c0 110.28 89.72 200 200 200 31.34 0 59.57-5.07 81.61-14.67a16 16 0 0 1 21.06 21.06C442.28 426 358 480 264 480", fill = true, stroke = 0f, cap = StrokeCap.Butt, join = StrokeJoin.Miter)
        )
    }

    val Contrast: ImageVector by lazy {
        icon(
            "Contrast",
        p("M48,256a208,208 0 1,0 416,0a208,208 0 1,0 -416,0Z", fill = false, stroke = 32f, cap = StrokeCap.Butt, join = StrokeJoin.Round),
        p("M256 464c-114.88 0-208-93.12-208-208S141.12 48 256 48Z", fill = true, stroke = 0f, cap = StrokeCap.Butt, join = StrokeJoin.Miter)
        )
    }

    val Plus: ImageVector by lazy {
        icon(
            "Plus",
        p("M256 112v288M400 256H112", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        )
    }

    val Minus: ImageVector by lazy {
        icon(
            "Minus",
        p("M400 256H112", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        )
    }

    val CloseCircle: ImageVector by lazy {
        icon(
            "CloseCircle",
        p("M256 48C141.31 48 48 141.31 48 256s93.31 208 208 208 208-93.31 208-208S370.69 48 256 48m75.31 260.69a16 16 0 1 1-22.62 22.62L256 278.63l-52.69 52.68a16 16 0 0 1-22.62-22.62L233.37 256l-52.68-52.69a16 16 0 0 1 22.62-22.62L256 233.37l52.69-52.68a16 16 0 0 1 22.62 22.62L278.63 256Z", fill = true, stroke = 0f, cap = StrokeCap.Butt, join = StrokeJoin.Miter)
        )
    }

    val Palette: ImageVector by lazy {
        icon(
            "Palette",
        p("M430.11 347.9c-6.6-6.1-16.3-7.6-24.6-9-11.5-1.9-15.9-4-22.6-10-14.3-12.7-14.3-31.1 0-43.8l30.3-26.9c46.4-41 46.4-108.2 0-149.2-34.2-30.1-80.1-45-127.8-45-55.7 0-113.9 20.3-158.8 60.1-83.5 73.8-83.5 194.7 0 268.5 41.5 36.7 97.5 55 152.9 55.4h1.7c55.4 0 110-17.9 148.8-52.4 14.4-12.7 11.99-36.6.1-47.7Z", fill = false, stroke = 32f, cap = StrokeCap.Butt, join = StrokeJoin.Miter),
        p("M112,208a32,32 0 1,0 64,0a32,32 0 1,0 -64,0Z", fill = true, stroke = 0f, cap = StrokeCap.Butt, join = StrokeJoin.Miter),
        p("M120,311a32,32 0 1,0 64,0a32,32 0 1,0 -64,0Z", fill = true, stroke = 0f, cap = StrokeCap.Butt, join = StrokeJoin.Miter),
        p("M192,144a32,32 0 1,0 64,0a32,32 0 1,0 -64,0Z", fill = true, stroke = 0f, cap = StrokeCap.Butt, join = StrokeJoin.Miter),
        p("M208,367a48,48 0 1,0 96,0a48,48 0 1,0 -96,0Z", fill = true, stroke = 0f, cap = StrokeCap.Butt, join = StrokeJoin.Miter),
        p("M296,144a32,32 0 1,0 64,0a32,32 0 1,0 -64,0Z", fill = true, stroke = 0f, cap = StrokeCap.Butt, join = StrokeJoin.Miter)
        )
    }

    val Language: ImageVector by lazy {
        icon(
            "Language",
        p("m478.33 433.6-90-218a22 22 0 0 0-40.67 0l-90 218a22 22 0 1 0 40.67 16.79L316.66 406h102.67l18.33 44.39A22 22 0 0 0 458 464a22 22 0 0 0 20.32-30.4ZM334.83 362 368 281.65 401.17 362ZM267.84 342.92a22 22 0 0 0-4.89-30.7c-.2-.15-15-11.13-36.49-34.73 39.65-53.68 62.11-114.75 71.27-143.49H330a22 22 0 0 0 0-44H214V70a22 22 0 0 0-44 0v20H54a22 22 0 0 0 0 44h197.25c-9.52 26.95-27.05 69.5-53.79 108.36-31.41-41.68-43.08-68.65-43.17-68.87a22 22 0 0 0-40.58 17c.58 1.38 14.55 34.23 52.86 83.93.92 1.19 1.83 2.35 2.74 3.51-39.24 44.35-77.74 71.86-93.85 80.74a22 22 0 1 0 21.07 38.63c2.16-1.18 48.6-26.89 101.63-85.59 22.52 24.08 38 35.44 38.93 36.1a22 22 0 0 0 30.75-4.9Z", fill = true, stroke = 0f, cap = StrokeCap.Butt, join = StrokeJoin.Miter)
        )
    }

    val LogOut: ImageVector by lazy {
        icon(
            "LogOut",
        p("M304 336v40a40 40 0 0 1-40 40H104a40 40 0 0 1-40-40V136a40 40 0 0 1 40-40h152c22.09 0 48 17.91 48 40v40M368 336l80-80-80-80M176 256h256", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        )
    }

    val Document: ImageVector by lazy {
        icon(
            "Document",
        p("M416 221.25V416a48 48 0 0 1-48 48H144a48 48 0 0 1-48-48V96a48 48 0 0 1 48-48h98.75a32 32 0 0 1 22.62 9.37l141.26 141.26a32 32 0 0 1 9.37 22.62Z", fill = false, stroke = 32f, cap = StrokeCap.Butt, join = StrokeJoin.Round),
        p("M256 56v120a32 32 0 0 0 32 32h120M176 288h160M176 368h160", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        )
    }

    val GitHub: ImageVector by lazy {
        icon(
            "GitHub",
        p("M256 32C132.3 32 32 134.9 32 261.7c0 101.5 64.2 187.5 153.2 217.9a17.6 17.6 0 0 0 3.8.4c8.3 0 11.5-6.1 11.5-11.4 0-5.5-.2-19.9-.3-39.1a102.4 102.4 0 0 1-22.6 2.7c-43.1 0-52.9-33.5-52.9-33.5-10.2-26.5-24.9-33.6-24.9-33.6-19.5-13.7-.1-14.1 1.4-14.1h.1c22.5 2 34.3 23.8 34.3 23.8 11.2 19.6 26.2 25.1 39.6 25.1a63 63 0 0 0 25.6-6c2-14.8 7.8-24.9 14.2-30.7-49.7-5.8-102-25.5-102-113.5 0-25.1 8.7-45.6 23-61.6-2.3-5.8-10-29.2 2.2-60.8a18.6 18.6 0 0 1 5-.5c8.1 0 26.4 3.1 56.6 24.1a208.2 208.2 0 0 1 112.2 0c30.2-21 48.5-24.1 56.6-24.1a18.6 18.6 0 0 1 5 .5c12.2 31.6 4.5 55 2.2 60.8 14.3 16.1 23 36.6 23 61.6 0 88.2-52.4 107.6-102.3 113.3 8 7.1 15.2 21.1 15.2 42.5 0 30.7-.3 55.5-.3 63 0 5.4 3.1 11.5 11.4 11.5a19.4 19.4 0 0 0 4-.4C415.9 449.2 480 363.1 480 261.7 480 134.9 379.7 32 256 32", fill = true, stroke = 0f, cap = StrokeCap.Butt, join = StrokeJoin.Miter)
        )
    }

    val Code: ImageVector by lazy {
        icon(
            "Code",
        p("M160 389a20.9 20.9 0 0 1-13.82-5.2l-128-112a21 21 0 0 1 0-31.6l128-112a21 21 0 0 1 27.66 31.61L63.89 256l109.94 96.19A21 21 0 0 1 160 389M352 389a21 21 0 0 1-13.84-36.81L448.11 256l-109.94-96.19a21 21 0 0 1 27.66-31.61l128 112a21 21 0 0 1 0 31.6l-128 112A20.9 20.9 0 0 1 352 389M208 437a21 21 0 0 1-20.12-27l96-320a21 21 0 1 1 40.23 12l-96 320A21 21 0 0 1 208 437", fill = true, stroke = 0f, cap = StrokeCap.Butt, join = StrokeJoin.Miter)
        )
    }

    val Portrait: ImageVector by lazy {
        icon(
            "Portrait",
        p("M176,16h160a48,48 0 0,1 48,48v384a48,48 0 0,1 -48,48h-160a48,48 0 0,1 -48,-48v-384a48,48 0 0,1 48,-48Z", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round),
        p("M176 16h24a8 8 0 0 1 8 8h0a16 16 0 0 0 16 16h64a16 16 0 0 0 16-16h0a8 8 0 0 1 8-8h24", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        )
    }

    val Landscape: ImageVector by lazy {
        icon(
            "Landscape",
        p("M176,16h160a48,48 0 0,1 48,48v384a48,48 0 0,1 -48,48h-160a48,48 0 0,1 -48,-48v-384a48,48 0 0,1 48,-48Z", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round),
        p("M16 336v-24a8 8 0 0 1 8-8h0a16 16 0 0 0 16-16v-64a16 16 0 0 0-16-16h0a8 8 0 0 1-8-8v-24", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        )
    }

    val LeftToRight: ImageVector by lazy {
        icon(
            "LeftToRight",
        p("M262.62 336 342 256l-79.38-80M330.97 256H170", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round),
        p("M256 448c106 0 192-86 192-192S362 64 256 64 64 150 64 256s86 192 192 192Z", fill = false, stroke = 32f, cap = StrokeCap.Butt, join = StrokeJoin.Miter)
        )
    }

    val RightToLeft: ImageVector by lazy {
        icon(
            "RightToLeft",
        p("M249.38 336 170 256l79.38-80M181.03 256H342", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round),
        p("M448 256c0-106-86-192-192-192S64 150 64 256s86 192 192 192 192-86 192-192Z", fill = false, stroke = 32f, cap = StrokeCap.Butt, join = StrokeJoin.Miter)
        )
    }

    val TopToBottom: ImageVector by lazy {
        icon(
            "TopToBottom",
        p("M176 262.62 256 342l80-79.38M256 330.97V170", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round),
        p("M256 64C150 64 64 150 64 256s86 192 192 192 192-86 192-192S362 64 256 64Z", fill = false, stroke = 32f, cap = StrokeCap.Butt, join = StrokeJoin.Miter)
        )
    }

    val Continuous: ImageVector by lazy {
        icon(
            "Continuous",
        p("M368 415.86V72a24.07 24.07 0 0 0-24-24H72a24.07 24.07 0 0 0-24 24v352a40.12 40.12 0 0 0 40 40h328", fill = false, stroke = 32f, cap = StrokeCap.Butt, join = StrokeJoin.Round),
        p("M416 464a48 48 0 0 1-48-48V128h72a24 24 0 0 1 24 24v264a48 48 0 0 1-48 48Z", fill = false, stroke = 32f, cap = StrokeCap.Butt, join = StrokeJoin.Round),
        p("M240 128h64M240 192h64M112 256h192M112 320h192M112 384h192", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round),
        p("M176 208h-64a16 16 0 0 1-16-16v-64a16 16 0 0 1 16-16h64a16 16 0 0 1 16 16v64a16 16 0 0 1-16 16", fill = true, stroke = 0f, cap = StrokeCap.Butt, join = StrokeJoin.Miter)
        )
    }

    val ContinuousGaps: ImageVector by lazy {
        icon(
            "ContinuousGaps",
        p("M96 304h320M96 208h320M96 112h320M96 400h320", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        )
    }

    val Timer: ImageVector by lazy {
        icon(
            "Timer",
        p("M112.91 128A191.85 191.85 0 0 0 64 254c-1.18 106.35 85.65 193.8 192 194 106.2.2 192-85.83 192-192 0-104.54-83.55-189.61-187.5-192a4.36 4.36 0 0 0-4.5 4.37V152", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round),
        p("m233.38 278.63-79-113a8.13 8.13 0 0 1 11.32-11.32l113 79a32.5 32.5 0 0 1-37.25 53.26 33.2 33.2 0 0 1-8.07-7.94", fill = true, stroke = 0f, cap = StrokeCap.Butt, join = StrokeJoin.Miter)
        )
    }

    val Speed: ImageVector by lazy {
        icon(
            "Speed",
        p("m326.1 231.9-47.5 75.5a31 31 0 0 1-7 7 30.11 30.11 0 0 1-35-49l75.5-47.5a10.23 10.23 0 0 1 11.7 0 10.06 10.06 0 0 1 2.3 14", fill = true, stroke = 0f, cap = StrokeCap.Butt, join = StrokeJoin.Miter),
        p("M256 64C132.3 64 32 164.2 32 287.9a223.18 223.18 0 0 0 56.3 148.5c1.1 1.2 2.1 2.4 3.2 3.5a25.19 25.19 0 0 0 37.1-.1 173.13 173.13 0 0 1 254.8 0 25.19 25.19 0 0 0 37.1.1l3.2-3.5A223.18 223.18 0 0 0 480 287.9C480 164.2 379.7 64 256 64", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round),
        p("M256 128v32M416 288h-32M128 288H96M165.49 197.49l-22.63-22.63M346.51 197.49l22.63-22.63", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Miter)
        )
    }

    val Hourglass: ImageVector by lazy {
        icon(
            "Hourglass",
        p("M145.61 464h220.78c19.8 0 35.55-16.29 33.42-35.06C386.06 308 304 310 304 256s83.11-51 95.8-172.94c2-18.78-13.61-35.06-33.41-35.06H145.61c-19.8 0-35.37 16.28-33.41 35.06C124.89 205 208 201 208 256s-82.06 52-95.8 172.94c-2.14 18.77 13.61 35.06 33.41 35.06", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round),
        p("M343.3 432H169.13c-15.6 0-20-18-9.06-29.16C186.55 376 240 356.78 240 326V224c0-19.85-38-35-61.51-67.2-3.88-5.31-3.49-12.8 6.37-12.8h142.73c8.41 0 10.23 7.43 6.4 12.75C310.82 189 272 204.05 272 224v102c0 30.53 55.71 47 80.4 76.87 9.95 12.04 6.47 29.13-9.1 29.13", fill = true, stroke = 0f, cap = StrokeCap.Butt, join = StrokeJoin.Miter)
        )
    }

    val Warning: ImageVector by lazy {
        icon(
            "Warning",
        p("M85.57 446.25h340.86a32 32 0 0 0 28.17-47.17L284.18 82.58c-12.09-22.44-44.27-22.44-56.36 0L57.4 399.08a32 32 0 0 0 28.17 47.17", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round),
        p("m250.26 195.39 5.74 122 5.73-121.95a5.74 5.74 0 0 0-5.79-6h0a5.74 5.74 0 0 0-5.68 5.95", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round),
        p("M256 397.25a20 20 0 1 1 20-20 20 20 0 0 1-20 20", fill = true, stroke = 0f, cap = StrokeCap.Butt, join = StrokeJoin.Miter)
        )
    }

    val Exit: ImageVector by lazy {
        icon(
            "Exit",
        p("M320 176v-40a40 40 0 0 0-40-40H88a40 40 0 0 0-40 40v240a40 40 0 0 0 40 40h192a40 40 0 0 0 40-40v-40M384 176l80 80-80 80M191 256h273", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        )
    }

    val Folder: ImageVector by lazy {
        icon(
            "Folder",
        p("M64 192v-72a40 40 0 0 1 40-40h75.89a40 40 0 0 1 22.19 6.72l27.84 18.56a40 40 0 0 0 22.19 6.72H408a40 40 0 0 1 40 40v40", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round),
        p("M479.9 226.55 463.68 392a40 40 0 0 1-39.93 40H88.25a40 40 0 0 1-39.93-40L32.1 226.55A32 32 0 0 1 64 192h384.1a32 32 0 0 1 31.8 34.55", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        )
    }

    val Save: ImageVector by lazy {
        icon(
            "Save",
        p("M380.93 57.37A32 32 0 0 0 358.3 48H94.22A46.21 46.21 0 0 0 48 94.22v323.56A46.21 46.21 0 0 0 94.22 464h323.56A46.36 46.36 0 0 0 464 417.78V153.7a32 32 0 0 0-9.37-22.63ZM256 416a64 64 0 1 1 64-64 63.92 63.92 0 0 1-64 64m48-224H112a16 16 0 0 1-16-16v-64a16 16 0 0 1 16-16h192a16 16 0 0 1 16 16v64a16 16 0 0 1-16 16", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        )
    }

    val SwapHorizontal: ImageVector by lazy {
        icon(
            "SwapHorizontal",
        p("m304 48 112 112-112 112M398.87 160H96M208 464 96 352l112-112M114 352h302", fill = false, stroke = 32f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        )
    }
}
