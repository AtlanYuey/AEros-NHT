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
    var actionError: String?

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
            actionError = error.localizedDescription
        }
    }
}

struct GalleryDetailView: View {
    @State private var model: GalleryModel
    @State private var showLogin = false
    @State private var confirmDeleteDownload = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(UserSession.self) private var session
    @Environment(DownloadManager.self) private var downloads

    init(route: GalleryRoute) {
        _model = State(initialValue: GalleryModel(route: route))
    }

    private var item: GalleryItem? { model.preview ?? model.detail?.asItem }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                if let detail = model.detail {
                    actions(detail)
                    InfoStrip(detail: detail, favorites: model.numFavorites)
                    TagsSection(detail: detail)
                    PreviewSection(detail: detail)
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
        .background(alignment: .top) {
            Backdrop(url: item?.thumbURL)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let detail = model.detail {
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
        .sheet(isPresented: $showLogin) { LoginView() }
        .alert("Couldn't Update", isPresented: Binding(
            get: { model.actionError != nil },
            set: { if !$0 { model.actionError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(model.actionError ?? "")
        }
        .confirmationDialog("Delete the downloaded pages?", isPresented: $confirmDeleteDownload,
                            titleVisibility: .visible) {
            Button("Delete Download", role: .destructive) { downloads.delete(model.id) }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .bottom, spacing: 18) {
            Group {
                if let item {
                    CoverView(item: item, cornerRadius: 14, targetWidth: 500)
                } else {
                    RoundedRectangle(cornerRadius: 14).fill(.quaternary).aspectRatio(0.7, contentMode: .fit)
                }
            }
            .frame(width: sizeClass == .regular ? 200 : 132)
            .shadow(color: .black.opacity(0.25), radius: 14, y: 8)

            VStack(alignment: .leading, spacing: 8) {
                Text(model.detail?.displayTitle ?? model.preview?.title ?? "")
                    .font(sizeClass == .regular ? .title2.weight(.semibold) : .title3.weight(.semibold))
                    .textSelection(.enabled)
                if let subtitle = model.detail?.subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .textSelection(.enabled)
                }
                if let detail = model.detail {
                    let artists = detail.tags(in: .artist) + detail.tags(in: .group)
                    if let first = artists.first {
                        NavigationLink(value: SearchRoute(query: first.query, title: first.name)) {
                            Text(artists.map(\.name).joined(separator: ", "))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.tint)
                                .lineLimit(2)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal)
        .padding(.top, 60)
    }

    // MARK: Actions

    private func actions(_ detail: GalleryDetail) -> some View {
        let lastPage = modelContext.lastReadPage(detail.id) ?? 0
        let source = ReaderSource(detail: detail)
        return HStack(spacing: 12) {
            NavigationLink(value: ReaderRoute(source: source, page: lastPage)) {
                Label(lastPage > 0 ? ("Resume · \(lastPage + 1)" as LocalizedStringKey) : "Read",
                      systemImage: lastPage > 0 ? "play.fill" : "book.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .modifier(ProminentButtonStyle())

            CircleButton(
                systemImage: model.isFavorited ? "heart.fill" : "heart",
                label: model.isFavorited ? "Unfavorite" : "Favorite",
                tint: model.isFavorited ? .pink : nil
            ) {
                if session.isLoggedIn {
                    Task { await model.toggleFavorite() }
                } else {
                    showLogin = true
                }
            }
            .disabled(model.isTogglingFavorite)
            .sensoryFeedback(.success, trigger: model.isFavorited)

            downloadButton(detail)
        }
        .padding(.horizontal)
        .padding(.top, 22)
    }

    @ViewBuilder
    private func downloadButton(_ detail: GalleryDetail) -> some View {
        let record = downloads.record(detail.id)
        switch record?.state {
        case .finished:
            CircleButton(systemImage: "checkmark.circle", label: "Downloaded", tint: .green) {
                confirmDeleteDownload = true
            }
        case .downloading, .queued:
            CircleButton(systemImage: "pause.fill", label: "Pause Download",
                         progress: record?.progress) {
                downloads.pause(detail.id)
            }
        case .paused, .failed:
            CircleButton(systemImage: "arrow.clockwise", label: "Resume Download",
                         progress: record?.progress) {
                downloads.resume(detail.id)
            }
        case nil:
            CircleButton(systemImage: "arrow.down", label: "Download") {
                downloads.start(detail)
            }
        }
    }
}

/// Round glass button next to the Read button (favorite, download).
struct CircleButton: View {
    let systemImage: String
    let label: LocalizedStringKey
    var tint: Color? = nil
    var progress: Double? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(tint ?? Color.accentColor)
                .frame(width: 30, height: 30)
                .contentTransition(.symbolEffect(.replace))
                .overlay {
                    if let progress {
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 40, height: 40)
                            .animation(.smooth, value: progress)
                    }
                }
                .padding(.vertical, 6)
        }
        .accessibilityLabel(Text(label))
        .modifier(CircleGlassStyle())
    }
}

struct CircleGlassStyle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.buttonStyle(.glass).buttonBorderShape(.circle).controlSize(.large)
        } else {
            content.buttonStyle(.bordered).buttonBorderShape(.circle).controlSize(.large)
        }
    }
}

/// `.glassProminent` on iOS 26, `.borderedProminent` before.
struct ProminentButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.buttonStyle(.glassProminent).buttonBorderShape(.capsule).controlSize(.large)
        } else {
            content.buttonStyle(.borderedProminent).buttonBorderShape(.capsule).controlSize(.large)
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

/// The blurred cover behind the top of the gallery page.
private struct Backdrop: View {
    let url: URL?

    var body: some View {
        RemoteImage(url: url, targetWidth: 200)
            .blur(radius: 40, opaque: true)
            .overlay(Color.black.opacity(0.18))
            .frame(height: 420)
            .clipped()
            .mask {
                LinearGradient(stops: [
                    .init(color: .black, location: 0),
                    .init(color: .black, location: 0.55),
                    .init(color: .clear, location: 1),
                ], startPoint: .top, endPoint: .bottom)
            }
            .ignoresSafeArea(edges: .top)
            .accessibilityHidden(true)
    }
}

// MARK: - Info

private struct InfoStrip: View {
    let detail: GalleryDetail
    let favorites: Int

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 0) {
                item("Pages") { Text("\(detail.numPages)") }
                Divider().frame(height: 34)
                item("Favorites") {
                    Label {
                        Text(favorites.formatted(.number.notation(.compactName)))
                    } icon: {
                        Image(systemName: "heart.fill").font(.caption)
                    }
                    .labelStyle(.titleAndIcon)
                }
                Divider().frame(height: 34)
                item("Uploaded") {
                    Text(detail.uploaded.map { Self.dateFormatter.string(from: $0) } ?? "-")
                }
                Divider().frame(height: 34)
                item("ID") { Text(verbatim: "#\(detail.id)") }
            }
            .padding(.vertical, 12)
            Divider()
        }
        .padding(.horizontal)
        .padding(.top, 22)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private func item<Value: View>(_ title: LocalizedStringKey, @ViewBuilder value: () -> Value) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            value()
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Tags

private struct TagsSection: View {
    let detail: GalleryDetail

    @Environment(TagStore.self) private var tagStore

    /// Order used by the site.
    private let order: [TagGroup] = [.category, .language, .tag, .parody, .character, .artist, .group]

    var body: some View {
        let groups = order.filter { !detail.tags(in: $0).isEmpty }
        if !groups.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(groups) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(group.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        FlowLayout(spacing: 8, lineSpacing: 8) {
                            ForEach(detail.tags(in: group)) { tag in
                                NavigationLink(value: SearchRoute(query: tag.query, title: tag.name)) {
                                    TagChip(name: tagStore.displayName(tag.name, type: tag.type), count: tag.count)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 18)
        }
    }
}

struct TagChip: View {
    let name: String
    var count: Int? = nil

    var body: some View {
        HStack(spacing: 5) {
            Text(name)
                .font(.subheadline)
            if let count, count > 0 {
                Text(count.formatted(.number.notation(.compactName)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.fill.tertiary, in: Capsule())
        .contentShape(Capsule())
    }
}

// MARK: - Pages preview

private struct PreviewSection: View {
    let detail: GalleryDetail

    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        let limit = sizeClass == .regular ? 18 : 9
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                SectionTitle(title: "Pages")
                Spacer()
                if detail.pages.count > limit {
                    NavigationLink {
                        PagesView(detail: detail)
                    } label: {
                        Text("See All")
                    }
                    .padding(.trailing)
                }
            }
            PageGrid(detail: detail, limit: limit)
                .padding(.horizontal)
        }
        .padding(.top, 8)
    }
}

struct PageGrid: View {
    let detail: GalleryDetail
    var limit: Int? = nil

    var body: some View {
        let source = ReaderSource(detail: detail)
        let pages = limit.map { Array(detail.pages.prefix($0)) } ?? detail.pages
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 96, maximum: 160), spacing: 10, alignment: .top)],
                  spacing: 14) {
            ForEach(pages) { page in
                NavigationLink(value: ReaderRoute(source: source, page: page.number - 1)) {
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

    var body: some View {
        ScrollView {
            PageGrid(detail: detail)
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
