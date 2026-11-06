import SwiftUI
import UIKit

struct HomeView: View {
    @Environment(AppSettings.self) private var settings
    @State private var popular: [GalleryItem] = []
    @State private var feed = GalleryFeed { page in
        let settings = AppSettings.shared
        return try await NHClient.shared.galleries(
            query: settings.homeLanguage.queryTerm ?? "",
            sort: settings.homeSort,
            page: page
        )
    }

    var body: some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            // iPad: the search field sits in the toolbar next to the menus and
            // searches in place, over the feed.
            SearchHost(placement: .toolbar) { searching in
                feedView(showsMenus: !searching)
            }
        } else {
            feedView(showsMenus: true)
        }
    }

    private func feedView(showsMenus: Bool) -> some View {
        @Bindable var settings = settings
        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if !popular.isEmpty {
                    SectionTitle(title: "Popular Now")
                    PopularRow(items: popular)
                }
                SectionTitle(title: LocalizedStringKey(settings.homeSort.title),
                             subtitle: settings.homeLanguage.title)
                GalleryCollection(items: feed.items) { item in
                    Task { await feed.loadMoreIfNeeded(after: item) }
                }
                FeedPlaceholder(feed: feed)
                FeedFooter(feed: feed)
            }
        }
        .navigationTitle("Home")
        .toolbar {
            if showsMenus {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Picker("Language", selection: $settings.homeLanguage) {
                            ForEach(LanguageFilter.allCases) { Text($0.title).tag($0) }
                        }
                    } label: {
                        Label("Language", systemImage: "globe")
                    }
                    Menu {
                        Picker("Sort", selection: $settings.homeSort) {
                            ForEach(SearchSort.allCases) { Text($0.title).tag($0) }
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                }
            }
        }
        .refreshable { await reload() }
        .task {
            if !feed.hasLoaded { await reload() }
        }
        .onChange(of: settings.homeLanguage) { Task { await feed.reload() } }
        .onChange(of: settings.homeSort) { Task { await feed.reload() } }
    }

    private func reload() async {
        async let list: Void = feed.reload()
        let popular = (try? await NHClient.shared.popular()) ?? self.popular
        self.popular = popular
        await list
    }
}

/// Section heading in the style of the App Store / Music.
struct SectionTitle: View {
    let title: LocalizedStringKey
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.title2.bold())
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.top, 20)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Horizontally scrolling row of covers.
struct PopularRow: View {
    let items: [GalleryItem]

    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: 12) {
                ForEach(items) { item in
                    GalleryCard(item: item, style: .grid)
                        .frame(width: sizeClass == .regular ? 170 : 132)
                }
            }
            .scrollTargetLayout()
            .padding(.horizontal)
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned)
    }
}
