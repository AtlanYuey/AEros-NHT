import SwiftUI
import WebKit

/// Signs in on nhentai.net in a web view (the site handles Turnstile and
/// its proof of work); the API tokens are read from the cookies it sets.
struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(UserSession.self) private var session
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            LoginWebView(isLoading: $isLoading) { access, refresh in
                Task {
                    await session.login(access: access, refresh: refresh)
                    dismiss()
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("Log In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") { dismiss() }
                }
                if isLoading {
                    ToolbarItem(placement: .confirmationAction) {
                        ProgressView()
                    }
                }
            }
        }
    }
}

struct LoginWebView: UIViewRepresentable {
    @Binding var isLoading: Bool
    let onToken: (String, String?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        configuration.websiteDataStore.httpCookieStore.add(context.coordinator)
        context.coordinator.cookieStore = configuration.websiteDataStore.httpCookieStore
        webView.load(URLRequest(url: NHHost.site.appendingPathComponent("login/")))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        coordinator.cookieStore?.remove(coordinator)
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKHTTPCookieStoreObserver {
        var parent: LoginWebView
        weak var cookieStore: WKHTTPCookieStore?
        private var done = false

        init(_ parent: LoginWebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            check(webView.configuration.websiteDataStore.httpCookieStore)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }

        func cookiesDidChange(in cookieStore: WKHTTPCookieStore) {
            check(cookieStore)
        }

        private func check(_ store: WKHTTPCookieStore) {
            store.getAllCookies { [weak self] cookies in
                guard let self, !self.done else { return }
                let site = cookies.filter { $0.domain.hasSuffix("nhentai.net") }
                guard let access = site.first(where: { $0.name == "access_token" })?.value,
                      !access.isEmpty
                else { return }
                let refresh = site.first(where: { $0.name == "refresh_token" })?.value
                self.done = true
                self.parent.onToken(access.removingPercentEncoding ?? access,
                                    refresh?.removingPercentEncoding ?? refresh)
            }
        }
    }
}
