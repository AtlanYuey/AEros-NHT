import Observation
import SwiftUI
import UIKit

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
}

/// Where the iPad tab bar sits at the bottom of the screen.
/// Where the iPad tab bar sits when it doesn't follow the hand.
enum TabBarPosition: String, CaseIterable, Identifiable {
    case leading, center, trailing

    var id: String { rawValue }

    var title: String {
        switch self {
        case .leading: String(localized: "Left")
        case .center: String(localized: "Center")
        case .trailing: String(localized: "Right")
        }
    }
}

/// How History and Downloads show their galleries: cards like Favorites
/// (in the list style), or a list with reading / download progress.
enum LibraryStyle: String, CaseIterable, Identifiable {
    case cards, list

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cards: String(localized: "Cards")
        case .list: String(localized: "List")
        }
    }
}

/// How quickly the iPad tab bar follows the hand.
enum FollowSpeed: String, CaseIterable, Identifiable {
    case fast, medium, slow

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fast: String(localized: "Fast")
        case .medium: String(localized: "Medium")
        case .slow: String(localized: "Slow")
        }
    }

    /// Touches in a row on the other side before the bar moves there.
    var touches: Int {
        switch self {
        case .fast: 1
        case .medium: 2
        case .slow: 4
        }
    }

    /// How long the bar takes to slide across.
    var duration: Double {
        switch self {
        case .fast: 0.3
        case .medium: 0.45
        case .slow: 0.65
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
    /// Columns of cards in portrait and landscape, a pair for iPhones and
    /// one for iPads: each kind of device uses its own, also when synced.
    var phoneColumnsPortrait: Int { didSet { save(phoneColumnsPortrait, "phoneColumnsPortrait") } }
    var phoneColumnsLandscape: Int { didSet { save(phoneColumnsLandscape, "phoneColumnsLandscape") } }
    var padColumnsPortrait: Int { didSet { save(padColumnsPortrait, "padColumnsPortrait") } }
    var padColumnsLandscape: Int { didSet { save(padColumnsLandscape, "padColumnsLandscape") } }
    /// Whether the column counts sync over iCloud (stored on this device only).
    var syncColumns: Bool {
        didSet {
            defaults.set(syncColumns, forKey: "syncColumns")
            // Turned on here: this device's counts become the synced ones.
            if syncColumns, !oldValue { SettingsSync.shared.pushColumns() }
        }
    }
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
    /// iPad: the tab bar moves to the side of the hand in use.
    var followHand: Bool { didSet { save(followHand, "followHand") } }
    var followSpeed: FollowSpeed { didSet { save(followSpeed.rawValue, "followSpeed") } }
    var saveSearchHistory: Bool { didSet { save(saveSearchHistory, "saveSearchHistory") } }
    /// Scrolling a list down slides the tab bar away.
    var hideBarsOnScroll: Bool { didSet { save(hideBarsOnScroll, "hideBarsOnScroll") } }
    /// Seconds without a touch before the reader's controls hide (3 at least).
    var readerControlsDelay: Double { didSet { save(readerControlsDelay, "readerControlsDelay") } }
    var libraryStyle: LibraryStyle { didSet { save(libraryStyle.rawValue, "libraryStyle") } }
    /// Recent search terms, newest first; synced with the settings.
    var recentSearches: [String] { didSet { save(recentSearches, "recentSearches") } }

    private init() {
        let d = UserDefaults.standard
        theme = ThemeMode(rawValue: d.string(forKey: "theme") ?? "") ?? .system
        accent = AccentChoice(rawValue: d.string(forKey: "accent") ?? "") ?? .blue
        listStyle = GalleryListStyle(rawValue: d.string(forKey: "listStyle") ?? "") ?? .waterfall
        phoneColumnsPortrait = Self.columns(d.object(forKey: "phoneColumnsPortrait"), landscape: false) ?? 2
        phoneColumnsLandscape = Self.columns(d.object(forKey: "phoneColumnsLandscape"), landscape: true) ?? 4
        padColumnsPortrait = Self.columns(d.object(forKey: "padColumnsPortrait"), landscape: false) ?? 3
        padColumnsLandscape = Self.columns(d.object(forKey: "padColumnsLandscape"), landscape: true) ?? 5
        syncColumns = d.object(forKey: "syncColumns") as? Bool ?? true
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
        tabBarPosition = TabBarPosition(rawValue: d.string(forKey: "tabBarPosition") ?? "") ?? .center
        followHand = d.object(forKey: "followHand") as? Bool ?? false
        followSpeed = FollowSpeed(rawValue: d.string(forKey: "followSpeed") ?? "") ?? .fast
        saveSearchHistory = d.object(forKey: "saveSearchHistory") as? Bool ?? true
        hideBarsOnScroll = d.object(forKey: "hideBarsOnScroll") as? Bool ?? true
        readerControlsDelay = min(max(d.object(forKey: "readerControlsDelay") as? Double ?? 3, 3), 10)
        libraryStyle = LibraryStyle(rawValue: d.string(forKey: "libraryStyle") ?? "") ?? .cards
        recentSearches = d.stringArray(forKey: "recentSearches") ?? []
    }

    private func save(_ value: Any, _ key: String) {
        defaults.set(value, forKey: key)
        if !isApplyingSynced, syncColumns || !Self.columnKeys.contains(key) {
            SettingsSync.shared.settingChanged(key, value)
        }
    }

    static let columnKeys: Set<String> = ["phoneColumnsPortrait", "phoneColumnsLandscape",
                                          "padColumnsPortrait", "padColumnsLandscape"]
    static let portraitColumns = 1...6
    static let landscapeColumns = 1...10

    private static func columns(_ value: Any?, landscape: Bool) -> Int? {
        guard let number = value as? Int else { return nil }
        let range = landscape ? landscapeColumns : portraitColumns
        return min(max(number, range.lowerBound), range.upperBound)
    }

    /// The settings iCloud sync shares: all of them, but the column counts
    /// only while Sync Columns is on.
    func syncedSnapshot() -> [String: Any] {
        snapshot().filter { syncColumns || !Self.columnKeys.contains($0.key) }
    }

    /// Every setting, keyed as in UserDefaults (used by iCloud sync and
    /// export).
    func snapshot() -> [String: Any] {
        var values: [String: Any] = [:]
        values["theme"] = theme.rawValue
        values["accent"] = accent.rawValue
        values["listStyle"] = listStyle.rawValue
        values["phoneColumnsPortrait"] = phoneColumnsPortrait
        values["phoneColumnsLandscape"] = phoneColumnsLandscape
        values["padColumnsPortrait"] = padColumnsPortrait
        values["padColumnsLandscape"] = padColumnsLandscape
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
        values["followHand"] = followHand
        values["followSpeed"] = followSpeed.rawValue
        values["saveSearchHistory"] = saveSearchHistory
        values["hideBarsOnScroll"] = hideBarsOnScroll
        values["readerControlsDelay"] = readerControlsDelay
        values["libraryStyle"] = libraryStyle.rawValue
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
            // Column counts from iCloud only while they are synced.
            if fromSync, !syncColumns, Self.columnKeys.contains(key) { continue }
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
        case "phoneColumnsPortrait": set(\.phoneColumnsPortrait, Self.columns(number?.intValue, landscape: false))
        case "phoneColumnsLandscape": set(\.phoneColumnsLandscape, Self.columns(number?.intValue, landscape: true))
        case "padColumnsPortrait": set(\.padColumnsPortrait, Self.columns(number?.intValue, landscape: false))
        case "padColumnsLandscape": set(\.padColumnsLandscape, Self.columns(number?.intValue, landscape: true))
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
        case "followHand": set(\.followHand, number?.boolValue)
        case "followSpeed": set(\.followSpeed, string.flatMap(FollowSpeed.init(rawValue:)))
        case "saveSearchHistory": set(\.saveSearchHistory, number?.boolValue)
        case "hideBarsOnScroll": set(\.hideBarsOnScroll, number?.boolValue)
        case "readerControlsDelay": set(\.readerControlsDelay, number.map { min(max($0.doubleValue, 3), 10) })
        case "libraryStyle": set(\.libraryStyle, string.flatMap(LibraryStyle.init(rawValue:)))
        case "recentSearches": set(\.recentSearches, (value as? [String]).map { Array($0.prefix(AppSettings.recentSearchLimit)) })
        default: break
        }
    }

    /// Columns of cards on this device in the orientation.
    func columns(isLandscape: Bool) -> Int {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return isLandscape ? padColumnsLandscape : padColumnsPortrait
        }
        return isLandscape ? phoneColumnsLandscape : phoneColumnsPortrait
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

