import SwiftUI

struct FavoritesView: View {
    @Environment(UserSession.self) private var session
    @State private var feed = GalleryFeed { page in
        try await NHClient.shared.favorites(page: page)
    }
    @State private var showLogin = false

    var body: some View {
        Group {
            if session.isLoggedIn {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        GalleryCollection(items: feed.items) { item in
                            Task { await feed.loadMoreIfNeeded(after: item) }
                        }
                        .padding(.top, 8)
                        FeedPlaceholder(feed: feed, emptyTitle: "No Favorites", emptyImage: "heart")
                        FeedFooter(feed: feed)
                    }
                }
                .refreshable { await feed.reload() }
            } else {
                ContentUnavailableView {
                    Label("Favorites", systemImage: "heart")
                } description: {
                    Text("Log in to your nhentai account to see your favorites.")
                } actions: {
                    Button("Log In") { showLogin = true }
                        .modifier(ProminentButtonStyle())
                }
            }
        }
        .navigationTitle("Favorites")
        .sheet(isPresented: $showLogin) { LoginView() }
        .task(id: session.isLoggedIn) {
            if session.isLoggedIn { await feed.reload() }
        }
    }
}
