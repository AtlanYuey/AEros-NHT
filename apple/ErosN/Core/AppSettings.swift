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

/// Where the iPad tab bar sits at the bottom of the screen.
enum TabBarPosition: String, CaseIterable, Identifiable {
    /// Follows the side the screen is touched on most.
    case automatic, leading, center, trailing

    var id: String { rawValue }

    var title: String {
        switch self {
        case .automatic: String(localized: "Automatic")
        case .leading: String(localized: "Left")
        case .center: String(localized: "Center")
        case .trailing: String(localized: "Right")
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
    /// Set while values from iCloud are applied, so they are not sent back.
    @ObservationIgnored private var isApplyingSynced = false

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
    var tabBarPosition: TabBarPosition { didSet { save(tabBarPosition.rawValue, "tabBarPosition") } }
    var saveSearchHistory: Bool { didSet { save(saveSearchHistory, "saveSearchHistory") } }
    /// Recent search terms, newest first; synced with the settings.
    var recentSearches: [String] { didSet { save(recentSearches, "recentSearches") } }

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
        pageGap = d.object(forKey: "pageGap") as? Double ?? 6
        keepScreenOn = d.object(forKey: "keepScreenOn") as? Bool ?? true
        // Reading the clipboard shows the system paste prompt: opt in.
        detectClipboard = d.object(forKey: "detectClipboard") as? Bool ?? false
        tabBarPosition = TabBarPosition(rawValue: d.string(forKey: "tabBarPosition") ?? "") ?? .automatic
        saveSearchHistory = d.object(forKey: "saveSearchHistory") as? Bool ?? true
        recentSearches = d.stringArray(forKey: "recentSearches") ?? []
    }

    private func save(_ value: Any, _ key: String) {
        defaults.set(value, forKey: key)
        if !isApplyingSynced {
            SettingsSync.shared.settingChanged(key, value)
        }
    }

    /// Every setting, keyed as in UserDefaults (used by iCloud sync and
    /// export).
    func snapshot() -> [String: Any] {
        var values: [String: Any] = [:]
        values["theme"] = theme.rawValue
        values["accent"] = accent.rawValue
        values["listStyle"] = listStyle.rawValue
        values["cardSizePortrait"] = cardSizePortrait.rawValue
        values["cardSizeLandscape"] = cardSizeLandscape.rawValue
        values["blurCovers"] = blurCovers
        values["showTags"] = showTags
        values["translateTags"] = translateTags
        values["homeLanguage"] = homeLanguage.rawValue
        values["homeSort"] = homeSort.rawValue
        values["searchLanguage"] = searchLanguage.rawValue
        values["searchSort"] = searchSort.rawValue
        values["readMode"] = readMode.rawValue
        values["autoReadInterval"] = autoReadInterval
        values["preloadPages"] = preloadPages
        values["tapToTurnPages"] = tapToTurnPages
        values["animatePageTurns"] = animatePageTurns
        values["pageGap"] = pageGap
        values["keepScreenOn"] = keepScreenOn
        values["detectClipboard"] = detectClipboard
        values["tabBarPosition"] = tabBarPosition.rawValue
        values["saveSearchHistory"] = saveSearchHistory
        values["recentSearches"] = recentSearches
        return values
    }

    /// Applies settings from iCloud (`fromSync`, not sent back) or from an
    /// imported file (sent on to iCloud like any other change). Unknown keys
    /// and invalid values are ignored.
    func apply(_ values: [String: Any], fromSync: Bool) {
        isApplyingSynced = fromSync
        defer { isApplyingSynced = false }
        for (key, value) in values {
            apply(value, forKey: key)
        }
    }

    private func apply(_ value: Any, forKey key: String) {
        func set<T: Equatable>(_ path: ReferenceWritableKeyPath<AppSettings, T>, _ new: T?) {
            if let new, self[keyPath: path] != new {
                self[keyPath: path] = new
            }
        }
        let string = value as? String
        let number = value as? NSNumber
        switch key {
        case "theme": set(\.theme, string.flatMap(ThemeMode.init(rawValue:)))
        case "accent": set(\.accent, string.flatMap(AccentChoice.init(rawValue:)))
        case "listStyle": set(\.listStyle, string.flatMap(GalleryListStyle.init(rawValue:)))
        case "cardSizePortrait": set(\.cardSizePortrait, number.flatMap { CardSize(rawValue: $0.intValue) })
        case "cardSizeLandscape": set(\.cardSizeLandscape, number.flatMap { CardSize(rawValue: $0.intValue) })
        case "blurCovers": set(\.blurCovers, number?.boolValue)
        case "showTags": set(\.showTags, number?.boolValue)
        case "translateTags": set(\.translateTags, number?.boolValue)
        case "homeLanguage": set(\.homeLanguage, string.flatMap(LanguageFilter.init(rawValue:)))
        case "homeSort": set(\.homeSort, string.flatMap(SearchSort.init(rawValue:)))
        case "searchLanguage": set(\.searchLanguage, string.flatMap(LanguageFilter.init(rawValue:)))
        case "searchSort": set(\.searchSort, string.flatMap(SearchSort.init(rawValue:)))
        case "readMode": set(\.readMode, string.flatMap(ReadMode.init(rawValue:)))
        case "autoReadInterval": set(\.autoReadInterval, number.map { min(max($0.doubleValue, 1), 10) })
        case "preloadPages": set(\.preloadPages, number.map { min(max($0.intValue, 1), 10) })
        case "tapToTurnPages": set(\.tapToTurnPages, number?.boolValue)
        case "animatePageTurns": set(\.animatePageTurns, number?.boolValue)
        case "pageGap": set(\.pageGap, number.map { min(max($0.doubleValue, 2), 60) })
        case "keepScreenOn": set(\.keepScreenOn, number?.boolValue)
        case "detectClipboard": set(\.detectClipboard, number?.boolValue)
        case "tabBarPosition": set(\.tabBarPosition, string.flatMap(TabBarPosition.init(rawValue:)))
        case "saveSearchHistory": set(\.saveSearchHistory, number?.boolValue)
        case "recentSearches": set(\.recentSearches, (value as? [String]).map { Array($0.prefix(AppSettings.recentSearchLimit)) })
        default: break
        }
    }

    func cardSize(isLandscape: Bool) -> CardSize {
        isLandscape ? cardSizeLandscape : cardSizePortrait
    }

    // MARK: Search history

    static let recentSearchLimit = 20

    /// Puts [term] first in the search history (when history is on).
    func addRecentSearch(_ term: String) {
        guard saveSearchHistory else { return }
        var items = recentSearches.filter { $0 != term }
        items.insert(term, at: 0)
        recentSearches = Array(items.prefix(Self.recentSearchLimit))
    }

    func removeRecentSearch(_ term: String) {
        recentSearches = recentSearches.filter { $0 != term }
    }

    func removeRecentSearches(at offsets: IndexSet) {
        var items = recentSearches
        items.remove(atOffsets: offsets)
        recentSearches = items
    }

    func clearRecentSearches() {
        recentSearches = []
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
