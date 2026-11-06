import Foundation

enum NHError: LocalizedError {
    case http(Int, String)
    case notLoggedIn
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case let .http(code, message):
            message.isEmpty ? String(localized: "Request failed (\(code))") : message
        case .notLoggedIn:
            String(localized: "Please log in first")
        case .invalidResponse:
            String(localized: "Unexpected response from the server")
        }
    }
}

enum SearchSort: String, CaseIterable, Identifiable, Codable {
    case recent = "date"
    case popularToday = "popular-today"
    case popularWeek = "popular-week"
    case popularMonth = "popular-month"
    case popular

    var id: String { rawValue }

    var title: String {
        switch self {
        case .recent: String(localized: "Recent")
        case .popularToday: String(localized: "Popular Today")
        case .popularWeek: String(localized: "Popular This Week")
        case .popularMonth: String(localized: "Popular This Month")
        case .popular: String(localized: "All-Time Popular")
        }
    }
}

enum LanguageFilter: String, CaseIterable, Identifiable, Codable {
    case all = ""
    case japanese
    case chinese
    case english
    case translated

    var id: String { rawValue.isEmpty ? "all" : rawValue }

    var title: String {
        switch self {
        case .all: String(localized: "All Languages")
        case .japanese: String(localized: "Japanese")
        case .chinese: String(localized: "Chinese")
        case .english: String(localized: "English")
        case .translated: String(localized: "Translated")
        }
    }

    /// Search syntax added to a query.
    var queryTerm: String? { self == .all ? nil : "language:\(rawValue)" }
}

/// nhentai REST API v2 (https://nhentai.net/api/v2/docs). The JSON API is
/// not behind Cloudflare's browser challenge; account actions send the
/// user's token (`Authorization: User <token>`).
final class NHClient: @unchecked Sendable {
    static let shared = NHClient()

    static let userAgent = "AEros-NHT/2.0 (iOS; +https://github.com/AtlanYuey/eros_n)"

    private let session: URLSession
    private let decoder = JSONDecoder()

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.httpAdditionalHeaders = [
            "User-Agent": NHClient.userAgent,
            "Accept": "application/json",
        ]
        config.requestCachePolicy = .useProtocolCachePolicy
        session = URLSession(configuration: config)
    }

    // MARK: Requests

    private func makeRequest(
        _ path: String,
        method: String = "GET",
        query: [URLQueryItem] = [],
        body: [String: Any]? = nil
    ) throws -> URLRequest {
        var components = URLComponents(
            url: NHHost.site.appendingPathComponent("api/v2/" + path),
            resolvingAgainstBaseURL: false
        )!
        if !query.isEmpty {
            components.queryItems = query
        }
        var request = URLRequest(url: components.url!)
        request.httpMethod = method
        if let token = AuthStore.shared.accessToken {
            request.setValue("User \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return request
    }

    private func send<T: Decodable>(
        _ type: T.Type,
        _ path: String,
        method: String = "GET",
        query: [URLQueryItem] = [],
        body: [String: Any]? = nil,
        retried: Bool = false
    ) async throws -> T {
        let request = try makeRequest(path, method: method, query: query, body: body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw NHError.invalidResponse
        }
        if http.statusCode == 401, !retried, AuthStore.shared.refreshToken != nil {
            if await AuthStore.shared.refresh() {
                return try await send(type, path, method: method, query: query,
                                      body: body, retried: true)
            }
        }
        guard (200..<300).contains(http.statusCode) else {
            throw NHError.http(http.statusCode, Self.message(from: data))
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NHError.invalidResponse
        }
    }

    private static func message(from data: Data) -> String {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return ""
        }
        for key in ["error", "detail", "message"] {
            if let value = object[key] as? String {
                return value
            }
        }
        return ""
    }

    // MARK: Galleries

    /// Latest galleries, or a search when a query or a non-date sort is
    /// given ("*" matches everything).
    func galleries(query: String, sort: SearchSort, page: Int) async throws -> PageResponse<GalleryItem> {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty, sort == .recent {
            return try await send(PageResponse<GalleryItem>.self, "galleries",
                                  query: [URLQueryItem(name: "page", value: "\(page)")])
        }
        return try await send(PageResponse<GalleryItem>.self, "search", query: [
            URLQueryItem(name: "query", value: q.isEmpty ? "*" : q),
            URLQueryItem(name: "sort", value: sort.rawValue),
            URLQueryItem(name: "page", value: "\(page)"),
        ])
    }

    func popular() async throws -> [GalleryItem] {
        try await send([GalleryItem].self, "galleries/popular").filter { !$0.blacklisted }
    }

    func gallery(_ id: Int) async throws -> GalleryDetail {
        let include = AuthStore.shared.isLoggedIn ? "related,favorite" : "related"
        return try await send(GalleryDetail.self, "galleries/\(id)",
                              query: [URLQueryItem(name: "include", value: include)])
    }

    func comments(_ id: Int) async throws -> [GalleryComment] {
        try await send(PageResponse<GalleryComment>.self, "galleries/\(id)/comments", query: [
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "per_page", value: "50"),
        ]).result
    }

    // MARK: Account

    func favorites(page: Int) async throws -> PageResponse<GalleryItem> {
        guard AuthStore.shared.isLoggedIn else { throw NHError.notLoggedIn }
        return try await send(PageResponse<GalleryItem>.self, "favorites",
                              query: [URLQueryItem(name: "page", value: "\(page)")])
    }

    func setFavorite(_ id: Int, _ favorite: Bool) async throws -> FavoriteResult {
        guard AuthStore.shared.isLoggedIn else { throw NHError.notLoggedIn }
        return try await send(FavoriteResult.self, "galleries/\(id)/favorite",
                              method: favorite ? "POST" : "DELETE")
    }

    func currentUser() async throws -> CurrentUser {
        try await send(CurrentUser.self, "user")
    }

    func postComment(_ id: Int, body: String) async throws -> GalleryComment {
        guard AuthStore.shared.isLoggedIn else { throw NHError.notLoggedIn }
        struct Challenge: Decodable {
            let challenge: String
            let difficulty: Int
        }
        let pow = try await send(Challenge.self, "pow",
                                 query: [URLQueryItem(name: "action", value: "comment")])
        let nonce = await Task.detached(priority: .userInitiated) {
            ProofOfWork.solve(challenge: pow.challenge, difficulty: pow.difficulty)
        }.value
        return try await send(GalleryComment.self, "galleries/\(id)/comments", method: "POST", body: [
            "body": body,
            "pow_challenge": pow.challenge,
            "pow_nonce": nonce,
        ])
    }

    // MARK: Tags

    func suggestTags(_ text: String) async throws -> [TagSuggestion] {
        try await send([TagSuggestion].self, "tags/search", method: "POST", body: [
            "query": text,
            "limit": 12,
        ])
    }

    // MARK: Auth

    struct TokenPair: Decodable {
        let accessToken: String
        let refreshToken: String?

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
        }
    }

    /// Exchanges a refresh token (no Authorization header).
    func refreshTokens(_ refreshToken: String) async throws -> TokenPair {
        var request = URLRequest(url: NHHost.site.appendingPathComponent("api/v2/auth/refresh"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["refresh_token": refreshToken])
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw NHError.invalidResponse
        }
        return try decoder.decode(TokenPair.self, from: data)
    }
}
