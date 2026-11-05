import SwiftUI

struct CommentsView: View {
    let galleryID: Int
    @State private var comments: [GalleryComment]
    @State private var draft = ""
    @State private var isPosting = false
    @State private var error: String?
    @FocusState private var composing: Bool
    @Environment(UserSession.self) private var session

    init(galleryID: Int, initial: [GalleryComment]) {
        self.galleryID = galleryID
        _comments = State(initialValue: initial)
    }

    var body: some View {
        List {
            ForEach(comments) { comment in
                CommentBubble(comment: comment)
                    .padding(.vertical, 4)
            }
        }
        .listStyle(.plain)
        .overlay {
            if comments.isEmpty {
                ContentUnavailableView("No Comments", systemImage: "text.bubble")
            }
        }
        .navigationTitle("Comments")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await load() }
        .task { await load() }
        .safeAreaInset(edge: .bottom) {
            if session.isLoggedIn { composer }
        }
        .alert("Couldn't Post", isPresented: Binding(
            get: { error != nil },
            set: { if !$0 { error = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(error ?? "")
        }
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Add a comment…", text: $draft, axis: .vertical)
                .lineLimit(1...5)
                .focused($composing)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            Button {
                Task { await post() }
            } label: {
                if isPosting {
                    ProgressView().frame(width: 36, height: 36)
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 34))
                        .symbolRenderingMode(.hierarchical)
                }
            }
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).count < 10 || isPosting)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .modifier(BarBackground())
    }

    private func load() async {
        if let fresh = try? await NHClient.shared.comments(galleryID) {
            comments = fresh
        }
    }

    private func post() async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        isPosting = true
        defer { isPosting = false }
        do {
            let comment = try await NHClient.shared.postComment(galleryID, body: text)
            comments.insert(comment, at: 0)
            draft = ""
            composing = false
        } catch {
            self.error = error.localizedDescription
        }
    }
}

/// Glass on iOS 26, the bar material before.
struct BarBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
        } else {
            content.background(.bar)
        }
    }
}

struct CommentBubble: View {
    let comment: GalleryComment
    var lineLimit: Int? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RemoteImage(url: comment.poster?.avatar, targetWidth: 80)
                .frame(width: 34, height: 34)
                .clipShape(Circle())
                .overlay {
                    if comment.poster?.avatar == nil {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(.secondary)
                    }
                }
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(comment.poster?.username ?? String(localized: "Anonymous"))
                        .font(.subheadline.weight(.semibold))
                    Spacer(minLength: 8)
                    Text(comment.date, format: .relative(presentation: .named))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(comment.body)
                    .font(.subheadline)
                    .lineLimit(lineLimit)
                    .textSelection(.enabled)
            }
        }
    }
}
