import SwiftUI

/// The system Search tab: search field with tag suggestions, recent
/// searches, and results.
struct SearchView: View {
    var body: some View {
        SearchHost()
            .navigationTitle("Search")
    }
}

/// Search field with tag suggestions, recent searches and results. Given
/// [idle] content (the iPad Home page), that content shows until the search
/// field is used, and the search shows over it, so it keeps its scroll
/// position; the closure is told whether results are showing (its toolbar
/// menus then change the search's language and sort, so the toolbar keeps
/// the same items and the search field keeps the keyboard).
struct SearchHost<Idle: View>: View {
    private let placement: SearchFieldPlacement
    private let idle: ((Bool) -> Idle)?

    @Environment(AppSettings.self) private var settings
    @State private var text = ""
    @State private var query = ""
    @State private var isPresented = false
    @State private var suggestions: [TagSuggestion] = []

    init(placement: SearchFieldPlacement = .automatic, @ViewBuilder idle: @escaping (_ showingResults: Bool) -> Idle) {
        self.placement = placement
        self.idle = idle
    }

    private var searching: Bool { isPresented || !query.isEmpty }

    var body: some View {
        content
            .searchable(text: $text, isPresented: $isPresented, placement: placement, prompt: "Titles, tags, artists, IDs")
            .searchSuggestions {
                ForEach(suggestions) { tag in
                    Label {
                        HStack {
                            Text(tag.name)
                            Spacer()
                            Text(tag.type.capitalized)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "tag")
                    }
                    .searchCompletion(completion(for: tag))
                }
            }
            .onSubmit(of: .search) { submit(text) }
            .onChange(of: text) { _, new in
                if new.isEmpty { query = "" }
            }
            .task(id: text) { await loadSuggestions() }
            .task {
                // The search tab opens with the keyboard up.
                guard idle == nil, query.isEmpty, !isPresented else { return }
                try? await Task.sleep(for: .milliseconds(150))
                isPresented = true
            }
    }

    @ViewBuilder private var content: some View {
        if let idle {
            idle(!query.isEmpty)
                .overlay {
                    if searching {
                        searchContent
                            .background(.background)
                    }
                }
        } else {
            searchContent
        }
    }

    @ViewBuilder private var searchContent: some View {
        if query.isEmpty {
            recentList
        } else {
            SearchResults(query: query, showsMenus: idle == nil)
                .id(query)
        }
    }

    private var recentList: some View {
        List {
            if !settings.saveSearchHistory || settings.recentSearches.isEmpty {
                ContentUnavailableView(
                    "Search nhentai",
                    systemImage: "magnifyingglass",
                    description: Text("Search by title or use tags like artist:name, or enter a gallery number.")
                )
                .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(settings.recentSearches, id: \.self) { item in
                        Button {
                            text = item
                            submit(item)
                        } label: {
                            Label(item, systemImage: "clock.arrow.circlepath")
                                .foregroundStyle(.primary)
                        }
                        .contextMenu {
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                settings.removeRecentSearch(item)
                            }
                        }
                    }
                    .onDelete { settings.removeRecentSearches(at: $0) }
                } header: {
                    HStack {
                        Text("Recent Searches")
                        Spacer()
                        Button("Clear") { settings.clearRecentSearches() }
                            .font(.subheadline)
                    }
                }
            }
        }
    }

    /// Replaces the word being typed with the tag.
    private func completion(for tag: TagSuggestion) -> String {
        var parts = text.split(separator: " ", omittingEmptySubsequences: false).map(String.init)
        if !parts.isEmpty { parts.removeLast() }
        parts.append(tag.query)
        return parts.joined(separator: " ") + " "
    }

    private func submit(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        settings.addRecentSearch(trimmed)
        query = trimmed
    }

    private func loadSuggestions() async {
        let word = text.split(separator: " ").last.map(String.init) ?? ""
        guard word.count >= 2, !word.contains(":"), !text.hasSuffix(" ") else {
            suggestions = []
            return
        }
        try? await Task.sleep(for: .milliseconds(250))
        guard !Task.isCancelled else { return }
        suggestions = (try? await NHClient.shared.suggestTags(word)) ?? []
    }
}

extension SearchHost where Idle == EmptyView {
    init(placement: SearchFieldPlacement = .automatic) {
        self.placement = placement
        self.idle = nil
    }
}

/// Search results for a query (also pushed from tags).
struct SearchResultsView: View {
    let route: SearchRoute

    var body: some View {
        SearchResults(query: route.query)
            .navigationTitle(route.title ?? route.query)
            .navigationBarTitleDisplayMode(.inline)
    }
}

/// Results for a query. A gallery number shows that gallery first, above
/// the results of searching for the number.
struct SearchResults: View {
    let query: String
    /// Language and sort menus in the toolbar (the iPad Home page has its own).
    let showsMenus: Bool

    @Environment(AppSettings.self) private var settings
    @State private var feed: GalleryFeed
    @State private var match: GalleryItem?

    init(query: String, showsMenus: Bool = true) {
        self.query = query
        self.showsMenus = showsMenus
        _feed = State(initialValue: GalleryFeed { page in
            let settings = AppSettings.shared
            let full = [query, settings.searchLanguage.queryTerm].compactMap { $0 }.joined(separator: " ")
            return try await NHClient.shared.galleries(query: full, sort: settings.searchSort, page: page)
        })
    }

    private var galleryID: Int? {
        Int(query.trimmingCharacters(in: .whitespaces)).flatMap { $0 > 0 ? $0 : nil }
    }

    var body: some View {
        @Bindable var settings = settings
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if let match {
                    SectionTitle(title: "Gallery #\(match.id)")
                    GalleryRow(item: match)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
                if let total = feed.total, feed.hasLoaded {
                    Text("\(total) results")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                }
                GalleryCollection(items: feed.items) { item in
                    Task { await feed.loadMoreIfNeeded(after: item) }
                }
                if match == nil {
                    FeedPlaceholder(feed: feed, emptyTitle: "No Results", emptyImage: "magnifyingglass")
                }
                FeedFooter(feed: feed)
            }
        }
        .refreshable { await feed.reload() }
        .task {
            if !feed.hasLoaded { await feed.reload() }
        }
        .task {
            if let id = galleryID, match == nil {
                match = try? await NHClient.shared.gallery(id).asItem
            }
        }
        .toolbar {
            if showsMenus {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Picker("Language", selection: $settings.searchLanguage) {
                            ForEach(LanguageFilter.allCases) { Text($0.title).tag($0) }
                        }
                    } label: {
                        Label("Language", systemImage: "globe")
                    }
                    Menu {
                        Picker("Sort", selection: $settings.searchSort) {
                            ForEach(SearchSort.allCases) { Text($0.title).tag($0) }
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                }
            }
        }
        .onChange(of: settings.searchLanguage) { Task { await feed.reload() } }
        .onChange(of: settings.searchSort) { Task { await feed.reload() } }
    }
}
