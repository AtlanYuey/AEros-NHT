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
/// position; the closure is told whether the search is showing.
struct SearchHost<Idle: View>: View {
    private let placement: SearchFieldPlacement
    private let idle: ((Bool) -> Idle)?

    @State private var text = ""
    @State private var query = ""
    @State private var isPresented = false
    @State private var suggestions: [TagSuggestion] = []
    @State private var recents = RecentSearches()

    init(placement: SearchFieldPlacement = .automatic, @ViewBuilder idle: @escaping (_ searching: Bool) -> Idle) {
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
    }

    @ViewBuilder private var content: some View {
        if let idle {
            idle(searching)
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
            SearchResults(query: query)
                .id(query)
        }
    }

    private var recentList: some View {
        List {
            if recents.items.isEmpty {
                ContentUnavailableView(
                    "Search nhentai",
                    systemImage: "magnifyingglass",
                    description: Text("Search by title or use tags like artist:name, or enter a gallery number.")
                )
                .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(recents.items, id: \.self) { item in
                        Button {
                            text = item
                            submit(item)
                        } label: {
                            Label(item, systemImage: "clock.arrow.circlepath")
                                .foregroundStyle(.primary)
                        }
                    }
                    .onDelete { recents.remove(at: $0) }
                } header: {
                    HStack {
                        Text("Recent Searches")
                        Spacer()
                        Button("Clear") { recents.clear() }
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
        recents.add(trimmed)
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

struct SearchResults: View {
    let query: String

    @Environment(AppSettings.self) private var settings
    @State private var feed: GalleryFeed
    @State private var openGallery: GalleryRoute?

    init(query: String) {
        self.query = query
        _feed = State(initialValue: GalleryFeed { page in
            let settings = AppSettings.shared
            let full = [query, settings.searchLanguage.queryTerm].compactMap { $0 }.joined(separator: " ")
            return try await NHClient.shared.galleries(query: full, sort: settings.searchSort, page: page)
        })
    }

    var body: some View {
        @Bindable var settings = settings
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
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
                FeedPlaceholder(feed: feed, emptyTitle: "No Results", emptyImage: "magnifyingglass")
                FeedFooter(feed: feed)
            }
        }
        .refreshable { await feed.reload() }
        .task {
            if let id = Int(query.trimmingCharacters(in: .whitespaces)), id > 0 {
                openGallery = GalleryRoute(id: id)
            }
            if !feed.hasLoaded { await feed.reload() }
        }
        .navigationDestination(item: $openGallery) { route in
            GalleryDetailView(route: route)
        }
        .toolbar {
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
        .onChange(of: settings.searchLanguage) { Task { await feed.reload() } }
        .onChange(of: settings.searchSort) { Task { await feed.reload() } }
    }
}

/// Recent search terms (UserDefaults).
@Observable
final class RecentSearches {
    private(set) var items: [String]
    private let key = "recentSearches"

    init() {
        items = UserDefaults.standard.stringArray(forKey: "recentSearches") ?? []
    }

    func add(_ term: String) {
        items.removeAll { $0 == term }
        items.insert(term, at: 0)
        items = Array(items.prefix(20))
        save()
    }

    func remove(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        save()
    }

    func clear() {
        items = []
        save()
    }

    private func save() {
        UserDefaults.standard.set(items, forKey: key)
    }
}
