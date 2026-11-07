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

/// The tabs with a floating glass tab bar at the bottom (PadRootView).
struct RootView: View {
    @State private var selection: AppTab = .home
    @Environment(AppSettings.self) private var settings
    @Environment(\.scenePhase) private var scenePhase
    @State private var clipboardGallery: Int?
    @State private var openedFromClipboard: GalleryRoute?

    var body: some View {
        // Search is on the Home page, so neither has a search tab.
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                // iPad: the floating glass tab bar at the bottom (PadRootView).
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

    /// iPhone: the system tab bar. With Hide Tab Bar When Scrolling on,
    /// iOS 26 shrinks it to a small button while a list scrolls down.
    private var phoneTabs: some View {
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
            Tab("Me", systemImage: "person.crop.circle", value: AppTab.more) {
                NavigationStack {
                    MoreView().galleryDestinations()
                }
            }
        }
        .modifier(TabBarMinimize(enabled: settings.hideBarsOnScroll))
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

/// iOS 26: the system tab bar shrinks to a small button while a list
/// scrolls down (the system handles it, so lists don't move).
private struct TabBarMinimize: ViewModifier {
    let enabled: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.tabBarMinimizeBehavior(enabled ? .onScrollDown : .never)
        } else {
            content
        }
    }
}

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

