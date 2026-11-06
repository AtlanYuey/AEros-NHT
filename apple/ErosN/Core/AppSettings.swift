import Observation
import SwiftUI

enum ThemeMode: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: String(localized: "System")
        case .light: String(localized: "Light")
        case .dark: String(localized: "Dark")
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum AccentChoice: String, CaseIterable, Identifiable {
    case blue, indigo, purple, pink, red, orange, yellow, green, mint, teal, cyan, brown

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .blue: .blue
        case .indigo: .indigo
        case .purple: .purple
        case .pink: .pink
        case .red: .red
        case .orange: .orange
        case .yellow: .yellow
        case .green: .green
        case .mint: .mint
        case .teal: .teal
        case .cyan: .cyan
        case .brown: .brown
        }
    }
}

enum GalleryListStyle: String, CaseIterable, Identifiable {
    case waterfall, compact, grid, list

    var id: String { rawValue }

    var title: String {
        switch self {
        case .waterfall: String(localized: "Waterfall")
        case .grid: String(localized: "Grid")
        case .compact: String(localized: "Waterfall (Compact)")
        case .list: String(localized: "List")
        }
    }

    var systemImage: String {
        switch self {
        case .waterfall: "rectangle.3.group"
        case .grid: "square.grid.2x2"
        case .compact: "photo.on.rectangle"
        case .list: "list.bullet"
        }
    }

    /// Preferred card width before the card size setting is applied.
    var preferredCardWidth: CGFloat {
        switch self {
        case .grid: 150
        case .waterfall, .compact: 190
        case .list: 600
        }
    }
}

enum ReadMode: String, CaseIterable, Identifiable {
    case leftToRight, rightToLeft, verticalPaged
    /// Continuous vertical scroll (webtoon style).
    case vertical
    /// Continuous vertical scroll with a black gap between pages.
    case verticalGap

    /// Whether pages are turned one at a time.
    var isPaged: Bool { self != .vertical && self != .verticalGap }

    var id: String { rawValue }

    var title: String {
        switch self {
        case .leftToRight: String(localized: "Left to Right")
        case .rightToLeft: String(localized: "Right to Left")
        case .verticalPaged: String(localized: "Top to Bottom")
        case .vertical: String(localized: "Continuous (Webtoon)")
        case .verticalGap: String(localized: "Continuous with Gaps")
        }
    }

    var systemImage: String {
        switch self {
        case .leftToRight: "arrow.right.square"
        case .rightToLeft: "arrow.left.square"
        case .verticalPaged: "arrow.down.square"
        case .vertical: "scroll"
        case .verticalGap: "rectangle.grid.1x2"
        }
    }
}

/// App settings, persisted in UserDefaults.
@Observable
final class AppSettings {
    static let shared = AppSettings()

    @ObservationIgnored private let defaults = UserDefaults.standard

    var theme: ThemeMode { didSet { save(theme.rawValue, "theme") } }
    var accent: AccentChoice { didSet { save(accent.rawValue, "accent") } }
    var listStyle: GalleryListStyle { didSet { save(listStyle.rawValue, "listStyle") } }
    var cardSizePortrait: CardSize { didSet { save(cardSizePortrait.rawValue, "cardSizePortrait") } }
    var cardSizeLandscape: CardSize { didSet { save(cardSizeLandscape.rawValue, "cardSizeLandscape") } }
    var blurCovers: Bool { didSet { save(blurCovers, "blurCovers") } }
    var showTags: Bool { didSet { save(showTags, "showTags") } }
    var translateTags: Bool { didSet { save(translateTags, "translateTags") } }

    var homeLanguage: LanguageFilter { didSet { save(homeLanguage.rawValue, "homeLanguage") } }
    var homeSort: SearchSort { didSet { save(homeSort.rawValue, "homeSort") } }
    var searchLanguage: LanguageFilter { didSet { save(searchLanguage.rawValue, "searchLanguage") } }
    var searchSort: SearchSort { didSet { save(searchSort.rawValue, "searchSort") } }

    var readMode: ReadMode { didSet { save(readMode.rawValue, "readMode") } }
    var autoReadInterval: Double { didSet { save(autoReadInterval, "autoReadInterval") } }
    var preloadPages: Int { didSet { save(preloadPages, "preloadPages") } }
    var tapToTurnPages: Bool { didSet { save(tapToTurnPages, "tapToTurnPages") } }
    var animatePageTurns: Bool { didSet { save(animatePageTurns, "animatePageTurns") } }
    /// Gap between pages in the "Continuous with Gaps" mode, in points.
    var pageGap: Double { didSet { save(pageGap, "pageGap") } }
    var keepScreenOn: Bool { didSet { save(keepScreenOn, "keepScreenOn") } }
    var detectClipboard: Bool { didSet { save(detectClipboard, "detectClipboard") } }

    private init() {
        let d = UserDefaults.standard
        theme = ThemeMode(rawValue: d.string(forKey: "theme") ?? "") ?? .system
        accent = AccentChoice(rawValue: d.string(forKey: "accent") ?? "") ?? .blue
        listStyle = GalleryListStyle(rawValue: d.string(forKey: "listStyle") ?? "") ?? .waterfall
        cardSizePortrait = (d.object(forKey: "cardSizePortrait") as? Int).flatMap(CardSize.init(rawValue:)) ?? .standard
        cardSizeLandscape = (d.object(forKey: "cardSizeLandscape") as? Int).flatMap(CardSize.init(rawValue:)) ?? .standard
        blurCovers = d.bool(forKey: "blurCovers")
        showTags = d.object(forKey: "showTags") as? Bool ?? true
        translateTags = d.object(forKey: "translateTags") as? Bool
            ?? (Locale.preferredLanguages.first?.hasPrefix("zh") ?? false)
        homeLanguage = LanguageFilter(rawValue: d.string(forKey: "homeLanguage") ?? "") ?? .all
        homeSort = SearchSort(rawValue: d.string(forKey: "homeSort") ?? "") ?? .recent
        searchLanguage = LanguageFilter(rawValue: d.string(forKey: "searchLanguage") ?? "") ?? .all
        searchSort = SearchSort(rawValue: d.string(forKey: "searchSort") ?? "") ?? .popular
        readMode = ReadMode(rawValue: d.string(forKey: "readMode") ?? "") ?? .leftToRight
        autoReadInterval = d.object(forKey: "autoReadInterval") as? Double ?? 3
        preloadPages = d.object(forKey: "preloadPages") as? Int ?? 4
        tapToTurnPages = d.object(forKey: "tapToTurnPages") as? Bool ?? true
        animatePageTurns = d.object(forKey: "animatePageTurns") as? Bool ?? true
        pageGap = d.object(forKey: "pageGap") as? Double ?? 12
        keepScreenOn = d.object(forKey: "keepScreenOn") as? Bool ?? true
        // Reading the clipboard shows the system paste prompt: opt in.
        detectClipboard = d.object(forKey: "detectClipboard") as? Bool ?? false
    }

    private func save(_ value: Any, _ key: String) {
        defaults.set(value, forKey: key)
    }

    func cardSize(isLandscape: Bool) -> CardSize {
        isLandscape ? cardSizeLandscape : cardSizePortrait
    }
}

/// How large gallery cards are: scales the preferred card width. The
/// column count always follows the available width (rotation, iPad split
/// view, Stage Manager), and every step changes it by at least one column
/// until a single column is left. `standard` keeps the automatic count.
enum CardSize: Int, CaseIterable, Identifiable {
    case small = 0, smaller, standard, larger, large

    var id: Int { rawValue }

    var scale: CGFloat {
        switch self {
        case .small: 0.62
        case .smaller: 0.8
        case .standard: 1
        case .larger: 1.3
        case .large: 1.75
        }
    }

    var title: String {
        switch self {
        case .small: String(localized: "Small")
        case .smaller: String(localized: "Smaller")
        case .standard: String(localized: "Standard")
        case .larger: String(localized: "Larger")
        case .large: String(localized: "Large")
        }
    }

    func columns(width: CGFloat, preferred: CGFloat, spacing: CGFloat) -> Int {
        func count(_ scale: CGFloat) -> Int {
            max(1, Int((width / (preferred * scale + spacing)).rounded(.up)))
        }
        let standardCount = count(1)
        if self == .standard { return standardCount }
        var columns = standardCount
        let step = rawValue < CardSize.standard.rawValue ? -1 : 1
        var index = CardSize.standard.rawValue + step
        while step < 0 ? index >= rawValue : index <= rawValue {
            let scaled = count(CardSize(rawValue: index)!.scale)
            columns = step < 0 ? max(scaled, columns + 1) : max(1, min(scaled, columns - 1))
            index += step
        }
        return columns
    }
}
