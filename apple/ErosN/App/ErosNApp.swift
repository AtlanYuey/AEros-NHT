import SwiftData
import SwiftUI
import UIKit

@main
struct ErosNApp: App {
    @State private var settings = AppSettings.shared
    @State private var session = UserSession.shared

    init() {
        ImageSetup.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
                .environment(session)
                .tint(settings.accent.color)
                .preferredColorScheme(settings.theme.colorScheme)
                .task { await session.reload() }
        }
        .modelContainer(for: HistoryEntry.self)
    }
}

enum AppTab: Hashable {
    case home, favorites, history, more, search
}

/// Tabs on iPhone; on iPad the same tabs adapt into a sidebar
/// (`sidebarAdaptable`). Search is the system search tab.
struct RootView: View {
    @State private var selection: AppTab = .home
    @Environment(AppSettings.self) private var settings
    @Environment(\.scenePhase) private var scenePhase
    @State private var clipboardGallery: Int?
    @State private var openedFromClipboard: GalleryRoute?

    var body: some View {
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
        .tabViewStyle(.sidebarAdaptable)
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
