import SwiftData
import SwiftUI

@MainActor
@Observable
final class GalleryModel {
    let id: Int
    var preview: GalleryItem?
    private(set) var detail: GalleryDetail?
    private(set) var error: String?
    private(set) var comments: [GalleryComment] = []
    var isFavorited = false
    var numFavorites = 0
    var isTogglingFavorite = false

    init(route: GalleryRoute) {
        id = route.id
        preview = route.preview
    }

    func load() async {
        error = nil
        do {
            let detail = try await NHClient.shared.gallery(id)
            self.detail = detail
            isFavorited = detail.isFavorited ?? false
            numFavorites = detail.numFavorites
        } catch {
            if detail == nil { self.error = error.localizedDescription }
        }
        comments = (try? await NHClient.shared.comments(id)) ?? comments
    }

    func toggleFavorite() async {
        guard !isTogglingFavorite else { return }
        isTogglingFavorite = true
        defer { isTogglingFavorite = false }
        let target = !isFavorited
        isFavorited = target
        do {
            let result = try await NHClient.shared.setFavorite(id, target)
            isFavorited = result.favorited ?? target
            numFavorites = result.numFavorites ?? numFavorites
        } catch {
            isFavorited = !target
            self.error = error.localizedDescription
        }
    }
}

struct GalleryDetailView: View {
    @State private var model: GalleryModel
    @State private var reader: ReaderRequest?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(UserSession.self) private var session

    init(route: GalleryRoute) {
        _model = State(initialValue: GalleryModel(route: route))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                if let detail = model.detail {
                    actions(detail)
                    InfoStrip(detail: detail, favorites: model.numFavorites)
                    TagsSection(detail: detail)
                    PreviewSection(detail: detail) { page in open(detail, at: page) }
                    if !detail.related.isEmpty {
                        SectionTitle(title: "More Like This")
                        PopularRow(items: detail.related)
                    }
                    CommentsPreview(detail: detail, comments: model.comments)
                } else if let error = model.error {
                    ContentUnavailableView {
                        Label("Couldn't Load", systemImage: "wifi.exclamationmark")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Try Again") { Task { await model.load() } }
                            .buttonStyle(.borderedProminent)
                    }
                    .padding(.top, 40)
                } else {
                    ProgressView()
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                }
            }
            .padding(.bottom, 32)
        }
        .navigationTitle(model.detail.map { "#\($0.id)" } ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if let detail = model.detail {
                    if session.isLoggedIn {
                        Button {
                            Task { await model.toggleFavorite() }
                        } label: {
                            Label(model.isFavorited ? "Unfavorite" as LocalizedStringKey : "Favorite",
                                  systemImage: model.isFavorited ? "heart.fill" : "heart")
                        }
                        .disabled(model.isTogglingFavorite)
                    }
                    ShareLink(item: detail.url, subject: Text(detail.displayTitle)) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
        .task {
            if model.detail == nil {
                await model.load()
                if let detail = model.detail {
                    modelContext.recordHistory(detail)
                }
            }
        }
        .refreshable { await model.load() }
        .fullScreenCover(item: $reader) { request in
            ReaderView(gallery: request.gallery, startPage: request.page)
        }
    }

    // MARK: Header

    private var header: some View {
        let item = model.preview ?? model.detail?.asItem
        return Group {
            if sizeClass == .regular {
                HStack(alignment: .top, spacing: 24) {
                    cover(item).frame(width: 220)
                    titles.frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                HStack(alignment: .top, spacing: 16) {
                    cover(item).frame(width: 128)
                    titles.frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    @ViewBuilder
    private func cover(_ item: GalleryItem?) -> some View {
        if let item {
            CoverView(item: item, cornerRadius: 14, targetWidth: 500)
                .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
        } else {
            RoundedRectangle(cornerRadius: 14).fill(.quaternary).aspectRatio(0.7, contentMode: .fit)
        }
    }

    private var titles: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(model.detail?.displayTitle ?? model.preview?.title ?? "")
                .font(.title3.weight(.semibold))
                .textSelection(.enabled)
            if let subtitle = model.detail?.subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
            if let detail = model.detail {
                let artists = detail.tags(in: .artist).map(\.name)
                if !artists.isEmpty {
                    Text(artists.joined(separator: ", "))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.tint)
                }
            }
        }
    }

    private func actions(_ detail: GalleryDetail) -> some View {
        let lastPage = modelContext.lastReadPage(detail.id) ?? 0
        return HStack(spacing: 12) {
            Button {
                open(detail, at: lastPage)
            } label: {
                Label(lastPage > 0 ? ("Resume · \(lastPage + 1)" as LocalizedStringKey) : "Read",
                      systemImage: lastPage > 0 ? "play.fill" : "book.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .modifier(ProminentButtonStyle())
            if lastPage > 0 {
                Button {
                    open(detail, at: 0)
                } label: {
                    Label("From Start", systemImage: "backward.end.fill")
                        .labelStyle(.iconOnly)
                        .padding(.vertical, 6)
                }
                .modifier(SecondaryButtonStyle())
            }
        }
        .padding(.horizontal)
        .padding(.top, 20)
    }

    private func open(_ detail: GalleryDetail, at page: Int) {
        reader = ReaderRequest(gallery: detail, page: min(max(0, page), max(0, detail.pages.count - 1)))
    }
}

struct ReaderRequest: Identifiable {
    let gallery: GalleryDetail
    let page: Int
    var id: Int { gallery.id }
}

/// `.glassProminent` on iOS 26, `.borderedProminent` before.
struct ProminentButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.buttonStyle(.glassProminent).controlSize(.large)
        } else {
            content.buttonStyle(.borderedProminent).controlSize(.large)
        }
    }
}

/// `.glass` on iOS 26, `.bordered` before.
struct SecondaryButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.buttonStyle(.glass).controlSize(.large)
        } else {
            content.buttonStyle(.bordered).controlSize(.large)
        }
    }
}

// MARK: - Info

private struct InfoStrip: View {
    let detail: GalleryDetail
    let favorites: Int

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                item("Pages", "\(detail.numPages)", "doc.on.doc")
                Divider().frame(height: 32)
                item("Favorites", favorites.formatted(.number.notation(.compactName)), "heart")
                if let language = detail.tags(in: .language).first(where: { $0.name != "translated" }) {
                    Divider().frame(height: 32)
                    item("Language", language.name.capitalized, "character.bubble")
                }
                if let date = detail.uploaded {
                    Divider().frame(height: 32)
                    item("Uploaded", date.formatted(date: .abbreviated, time: .omitted), "calendar")
                }
                Divider().frame(height: 32)
                item("ID", "\(detail.id)", "number")
            }
            .padding(.horizontal, 4)
        }
        .scrollIndicators(.hidden)
        .padding(.top, 20)
    }

    private func item(_ title: LocalizedStringKey, _ value: String, _ icon: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text(value)
                .font(.headline)
                .lineLimit(1)
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 96)
        .padding(.horizontal, 8)
    }
}

// MARK: - Tags

private struct TagsSection: View {
    let detail: GalleryDetail

    var body: some View {
        let groups = TagGroup.allCases.filter { !detail.tags(in: $0).isEmpty }
        if !groups.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(groups) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(group.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        FlowLayout(spacing: 8, lineSpacing: 8) {
                            ForEach(detail.tags(in: group)) { tag in
                                NavigationLink(value: SearchRoute(query: tag.query, title: tag.name)) {
                                    TagChip(tag: tag)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 24)
        }
    }
}

struct TagChip: View {
    let tag: GalleryTag

    var body: some View {
        HStack(spacing: 5) {
            Text(tag.name)
                .font(.subheadline)
            if let count = tag.count, count > 0 {
                Text(count.formatted(.number.notation(.compactName)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.fill.tertiary, in: Capsule())
        .contentShape(Capsule())
    }
}

// MARK: - Pages preview

private struct PreviewSection: View {
    let detail: GalleryDetail
    let open: (Int) -> Void

    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        let limit = sizeClass == .regular ? 18 : 9
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                SectionTitle(title: "Pages")
                Spacer()
                if detail.pages.count > limit {
                    NavigationLink {
                        PagesView(detail: detail, open: open)
                    } label: {
                        Text("See All")
                    }
                    .padding(.trailing)
                }
            }
            PageGrid(pages: Array(detail.pages.prefix(limit)), open: open)
                .padding(.horizontal)
        }
        .padding(.top, 8)
    }
}

struct PageGrid: View {
    let pages: [GalleryPage]
    let open: (Int) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 96, maximum: 160), spacing: 10, alignment: .top)],
                  spacing: 14) {
            ForEach(pages) { page in
                Button {
                    open(page.number - 1)
                } label: {
                    VStack(spacing: 4) {
                        Color.clear
                            .aspectRatio(0.7, contentMode: .fit)
                            .overlay {
                                RemoteImage(url: page.thumbURL, contentMode: .fit, targetWidth: 240)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        Text("\(page.number)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct PagesView: View {
    let detail: GalleryDetail
    let open: (Int) -> Void

    var body: some View {
        ScrollView {
            PageGrid(pages: detail.pages, open: open)
                .padding()
        }
        .navigationTitle("Pages")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Comments

private struct CommentsPreview: View {
    let detail: GalleryDetail
    let comments: [GalleryComment]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                SectionTitle(title: "Comments")
                Spacer()
                NavigationLink {
                    CommentsView(galleryID: detail.id, initial: comments)
                } label: {
                    Text(comments.isEmpty ? "Write" : ("See All (\(comments.count))" as LocalizedStringKey))
                }
                .padding(.trailing)
            }
            if comments.isEmpty {
                Text("No comments yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                ScrollView(.horizontal) {
                    LazyHStack(alignment: .top, spacing: 12) {
                        ForEach(comments.prefix(10)) { comment in
                            CommentBubble(comment: comment, lineLimit: 5)
                                .frame(width: 280, alignment: .leading)
                                .padding(14)
                                .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                    }
                    .scrollTargetLayout()
                    .padding(.horizontal)
                }
                .scrollIndicators(.hidden)
                .scrollTargetBehavior(.viewAligned)
            }
        }
        .padding(.top, 8)
    }
}
