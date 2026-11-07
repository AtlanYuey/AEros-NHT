import SwiftUI

/// In-place search on the Home page: a search field at the top with tag
/// suggestions, recent searches and results, shown over the feed (which
/// keeps its scroll position). Cancel goes back to the feed.
struct InlineSearch: View {
    @Binding var isActive: Bool

    @Environment(AppSettings.self) private var settings
    @State private var text = ""
    @State private var query = ""
    @State private var suggestions: [TagSuggestion] = []
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            field
            content
        }
        .background(.background)
        .onChange(of: text) { _, new in
            if new.isEmpty { query = "" }
        }
        .task(id: text) { await loadSuggestions() }
        .task {
            // The keyboard comes up as soon as the search opens.
            try? await Task.sleep(for: .milliseconds(80))
            focused = true
        }
    }

    private var field: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Titles, tags, artists, IDs", text: $text)
                    .focused($focused)
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onSubmit { submit(text) }
                if !text.isEmpty {
                    Button {
                        text = ""
                        focused = true
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("Clear"))
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 40)
            .background(.fill.tertiary, in: Capsule())
            Button("Cancel") { close() }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    @ViewBuilder private var content: some View {
        if focused, !suggestions.isEmpty {
            suggestionList
        } else if query.isEmpty {
            recentList
        } else {
            SearchResults(query: query)
                .id(query)
        }
    }

    private var suggestionList: some View {
        List(suggestions) { tag in
            Button {
                text = completion(for: tag)
                suggestions = []
            } label: {
                Label {
                    HStack {
                        Text(tag.name)
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(tag.type.capitalized)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "tag")
                }
            }
        }
        .listStyle(.plain)
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
        .scrollDismissesKeyboard(.immediately)
    }

    private func close() {
        focused = false
        withAnimation(.smooth(duration: 0.25)) { isActive = false }
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
        suggestions = []
        focused = false
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
        .hidesBarsOnScroll()
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
