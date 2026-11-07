import SwiftUI

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
    /// The search shows over the feed.
    @State private var searching = false
    /// The feed's header (sort, language, search) has scrolled under the
    /// navigation bar: its buttons show in the bar instead.
    @State private var docked = false
    /// Bottom of the feed's header in the feed's coordinates.
    @State private var headerBottom: CGFloat = .infinity

    private static let space = "homeFeed"

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if !popular.isEmpty {
                    SectionTitle(title: "Popular Now")
                    PopularRow(items: popular)
                }
                FeedHeader { startSearch() }
                    .onGeometryChange(for: CGFloat.self) {
                        $0.frame(in: .named(Self.space)).maxY
                    } action: { headerBottom = $0 }
                GalleryCollection(items: feed.items) { item in
                    Task { await feed.loadMoreIfNeeded(after: item) }
                }
                FeedPlaceholder(feed: feed)
                FeedFooter(feed: feed)
            }
            .coordinateSpace(.named(Self.space))
        }
        .onScrollGeometryChange(for: Bool.self) { geometry in
            // The bar's bottom edge, in the feed's coordinates, is past the header.
            geometry.contentOffset.y + geometry.contentInsets.top > headerBottom - 4
        } action: { _, under in
            withAnimation(.smooth(duration: 0.25)) { docked = under }
        }
        .hidesBarsOnScroll()
        .navigationTitle("Home")
        .toolbar {
            if docked, !searching {
                ToolbarItem(placement: .topBarLeading) {
                    SortMenu(compact: true)
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    LanguageMenu(compact: true)
                    Button {
                        startSearch()
                    } label: {
                        Label("Search", systemImage: "magnifyingglass")
                    }
                }
            }
        }
        .overlay {
            if searching {
                InlineSearch(isActive: $searching)
                    .transition(.opacity)
            }
        }
        .refreshable { await reload() }
        .task {
            if !feed.hasLoaded { await reload() }
        }
        .onChange(of: settings.homeLanguage) { Task { await feed.reload() } }
        .onChange(of: settings.homeSort) { Task { await feed.reload() } }
    }

    private func startSearch() {
        withAnimation(.smooth(duration: 0.25)) { searching = true }
    }

    private func reload() async {
        async let list: Void = feed.reload()
        let popular = (try? await NHClient.shared.popular()) ?? self.popular
        self.popular = popular
        await list
    }
}

/// The feed's header: the sort (a button that switches it), and on the
/// right the language and search buttons. Scrolled under the navigation
/// bar, the same buttons show in the bar.
private struct FeedHeader: View {
    let onSearch: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            SortMenu(compact: false)
            Spacer(minLength: 0)
            LanguageMenu(compact: false)
            CircleButton(systemImage: "magnifyingglass", label: "Search", tint: .primary, action: onSearch)
        }
        .padding(.horizontal)
        .padding(.top, 20)
        .padding(.bottom, 10)
    }
}

/// Switches the Home feed's sort: the section title, or a small button in
/// the navigation bar.
private struct SortMenu: View {
    let compact: Bool

    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Menu {
            Picker("Sort", selection: $settings.homeSort) {
                ForEach(SearchSort.allCases) { Text($0.title).tag($0) }
            }
        } label: {
            if compact {
                HStack(spacing: 4) {
                    Text(settings.homeSort.title)
                        .font(.subheadline.weight(.semibold))
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.bold))
                }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(settings.homeSort.title)
                            .font(.title2.bold())
                            .foregroundStyle(.primary)
                        Image(systemName: "chevron.down")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                    Text(settings.homeLanguage.title)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Sort"))
    }
}

/// The Home feed's language: a round button in the header, a bar button
/// when docked.
private struct LanguageMenu: View {
    let compact: Bool

    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Menu {
            Picker("Language", selection: $settings.homeLanguage) {
                ForEach(LanguageFilter.allCases) { Text($0.title).tag($0) }
            }
        } label: {
            if compact {
                Label("Language", systemImage: "globe")
            } else {
                Image(systemName: "globe")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
            }
        }
        .accessibilityLabel(Text("Language"))
        .modifier(OptionalCircleGlass(enabled: !compact))
    }
}

private struct OptionalCircleGlass: ViewModifier {
    let enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content.modifier(CircleGlassStyle())
        } else {
            content
        }
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
