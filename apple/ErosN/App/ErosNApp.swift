import SwiftData
import SwiftUI
import UIKit

@main
struct ErosNApp: App {
    @State private var settings = AppSettings.shared
    @State private var session = UserSession.shared
    @State private var downloads = DownloadManager.shared
    @State private var tagStore = TagStore.shared

    init() {
        ImageSetup.configure()
        SettingsSync.shared.start(isPad: UIDevice.current.userInterfaceIdiom == .pad)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
                .environment(session)
                .environment(downloads)
                .environment(tagStore)
                .tint(settings.accent.color)
                .preferredColorScheme(settings.theme.colorScheme)
                .modifier(SoftScrollEdges())
                .task { await session.reload() }
                .task { await tagStore.prepare() }
        }
        .modelContainer(for: HistoryEntry.self)
    }
}

enum AppTab: Hashable {
    case home, favorites, history, more, search
}

/// The system tab bar on iPhone; on iPad a floating glass tab bar at the
/// bottom that follows the hand in use (PadRootView).
struct RootView: View {
    @State private var selection: AppTab = .home
    @Environment(AppSettings.self) private var settings
    @State private var chrome = AppChrome.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var clipboardGallery: Int?
    @State private var openedFromClipboard: GalleryRoute?

    var body: some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                // iPad: tab bar at the bottom (see PadRootView).
                PadRootView(selection: $selection)
            } else {
                phoneTabs
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { checkClipboard() }
        }
        .alert("Open Gallery?", isPresented: Binding(
            get: { clipboardGallery != nil },
            set: { if !$0 { clipboardGallery = nil } }
        )) {
            Button("Open") {
                if let id = clipboardGallery {
                    openedFromClipboard = GalleryRoute(id: id)
                }
                clipboardGallery = nil
            }
            Button("Cancel", role: .cancel) { clipboardGallery = nil }
        } message: {
            if let id = clipboardGallery {
                Text("The clipboard contains a link to gallery #\(id).")
            }
        }
        .sheet(item: $openedFromClipboard) { route in
            NavigationStack {
                GalleryDetailView(route: route)
                    .galleryDestinations()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close", systemImage: "xmark") { openedFromClipboard = nil }
                        }
                    }
            }
        }
    }

    /// iPhone: the system tab bar (Liquid Glass, search tab at the side).
    private var phoneTabs: some View {
        tabView
            .overlay {
                // Exactly where the system search button is (56 pt, 20 pt
                // from the right and bottom edges of the screen): it stays
                // while the bars are hidden unless Hide Search Too is on.
                if settings.hideBarsOnScroll, chrome.barsHidden, !settings.hideSearchOnScroll, !chrome.hidesTabBar {
                    GeometryReader { geometry in
                        FloatingSearchButton(size: 56) {
                            withAnimation(.smooth(duration: 0.28)) { chrome.barsHidden = false }
                            if selection == .search {
                                chrome.searchRequest += 1
                            } else {
                                selection = .search
                            }
                        }
                        .position(
                            x: geometry.size.width - 20 - 28,
                            y: geometry.size.height + geometry.safeAreaInsets.bottom - 20 - 28
                        )
                    }
                }
            }
            .onChange(of: selection) { chrome.barsHidden = false }
    }

    private var tabView: some View {
        TabView(selection: $selection) {
            Tab("Home", systemImage: "house", value: AppTab.home) {
                NavigationStack {
                    HomeView().galleryDestinations()
                }
            }
            Tab("Favorites", systemImage: "heart", value: AppTab.favorites) {
                NavigationStack {
                    FavoritesView().galleryDestinations()
                }
            }
            Tab("History", systemImage: "clock", value: AppTab.history) {
                NavigationStack {
                    HistoryView().galleryDestinations()
                }
            }
            Tab("More", systemImage: "ellipsis.circle", value: AppTab.more) {
                NavigationStack {
                    MoreView().galleryDestinations()
                }
            }
            Tab(value: AppTab.search, role: .search) {
                NavigationStack {
                    SearchView().galleryDestinations()
                }
            }
        }
    }

    /// Offers to open a gallery link found on the clipboard (once per link).
    private func checkClipboard() {
        guard settings.detectClipboard, UIPasteboard.general.hasURLs || UIPasteboard.general.hasStrings else {
            return
        }
        let text = UIPasteboard.general.url?.absoluteString ?? UIPasteboard.general.string ?? ""
        guard text.contains("nhentai.net/g/"),
              let range = text.range(of: #"/g/(\d+)"#, options: .regularExpression)
        else { return }
        let digits = text[range].filter(\.isNumber)
        guard let id = Int(digits) else { return }
        let key = "lastClipboardGallery"
        guard UserDefaults.standard.integer(forKey: key) != id else { return }
        UserDefaults.standard.set(id, forKey: key)
        clipboardGallery = id
    }
}

extension GalleryRoute: Identifiable {}

/// iOS 26's soft, progressive scroll edge effect under bars, for every
/// scroll view in the app (instead of whatever the system default is).
struct SoftScrollEdges: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.scrollEdgeEffectStyle(.soft, for: .all)
        } else {
            content
        }
    }
}

