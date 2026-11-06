import Foundation
import Observation

/// Name and type of an nhentai tag (`tag`, `artist`, `language`…).
struct TagName: Codable, Hashable {
    let name: String
    let type: String
}

/// Local tag database: maps the tag ids of list items to names (the list
/// API only returns ids) and translates tag names to Chinese with the
/// EhTagTranslation database. Both are downloaded once and refreshed
/// weekly; jsDelivr is used first because GitHub is often unreachable.
@MainActor
@Observable
final class TagStore {
    static let shared = TagStore()

    private(set) var isUpdating = false
    private(set) var lastUpdated: Date?
    private(set) var tagCount = 0
    private(set) var translationCount = 0
    /// Bumped when the data changes, so views that read tags refresh.
    private(set) var revision = 0

    @ObservationIgnored private var tags: [Int: TagName] = [:]
    @ObservationIgnored private var translations: [String: [String: String]] = [:]
    @ObservationIgnored private var prepared = false

    /// Ids that are not in the downloaded lists (languages, categories).
    private static let builtIn: [Int: TagName] = [
        6346: TagName(name: "japanese", type: "language"),
        12227: TagName(name: "english", type: "language"),
        29963: TagName(name: "chinese", type: "language"),
        17249: TagName(name: "translated", type: "language"),
        33173: TagName(name: "manga", type: "category"),
    ]

    func tag(_ id: Int) -> TagName? {
        tags[id] ?? Self.builtIn[id]
    }

    /// The name to show for a tag (translated when the setting is on).
    func displayName(_ name: String, type: String) -> String {
        _ = revision
        guard AppSettings.shared.translateTags, let translated = translate(name, type: type) else {
            return name
        }
        return translated
    }

    func translate(_ name: String, type: String) -> String? {
        let namespaces: [String]
        switch type {
        case "tag": namespaces = ["female", "male", "mixed", "other", "location", "cosplayer"]
        case "category": namespaces = ["reclass"]
        default: namespaces = [type]
        }
        for namespace in namespaces {
            if let value = translations[namespace]?[name], !value.isEmpty {
                return value
            }
        }
        return nil
    }

    /// Tags shown on a card: languages first, then content tags.
    func cardTags(for ids: [Int], limit: Int = 8) -> [TagName] {
        _ = revision
        var languages: [TagName] = []
        var others: [TagName] = []
        for id in ids {
            guard let tag = tag(id) else { continue }
            if tag.type == "language" {
                languages.append(tag)
            } else if tag.type == "tag" {
                others.append(tag)
            }
        }
        return Array((languages + others).prefix(limit))
    }

    // MARK: Loading

    /// Loads the cached database and refreshes it when missing or old.
    func prepare() async {
        guard !prepared else { return }
        prepared = true
        if let snapshot = await Task.detached(priority: .utility, operation: { Self.readCache() }).value {
            apply(snapshot)
        }
        let stale = lastUpdated.map { Date().timeIntervalSince($0) > 7 * 24 * 3600 } ?? true
        if stale || tags.isEmpty {
            await update()
        }
    }

    func update() async {
        guard !isUpdating else { return }
        isUpdating = true
        defer { isUpdating = false }
        if let snapshot = try? await Task.detached(priority: .utility, operation: { try await Self.download() }).value {
            apply(snapshot)
        }
    }

    private func apply(_ snapshot: Snapshot) {
        if !snapshot.tags.isEmpty {
            tags = snapshot.tags
        }
        if !snapshot.translations.isEmpty {
            translations = snapshot.translations
        }
        lastUpdated = snapshot.date
        tagCount = tags.count
        translationCount = translations.values.reduce(0) { $0 + $1.count }
        revision += 1
    }

    // MARK: Storage

    struct Snapshot: Codable {
        var tags: [Int: TagName]
        var translations: [String: [String: String]]
        var date: Date
    }

    nonisolated private static var cacheURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Tags", isDirectory: true)
            .appendingPathComponent("tags.json")
    }

    nonisolated private static func readCache() -> Snapshot? {
        guard let data = try? Data(contentsOf: cacheURL) else { return nil }
        return try? JSONDecoder().decode(Snapshot.self, from: data)
    }

    nonisolated private static func writeCache(_ snapshot: Snapshot) {
        let url = cacheURL
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                 withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(snapshot) {
            try? data.write(to: url, options: .atomic)
        }
    }

    nonisolated private static func fetch(_ urls: [String]) async throws -> Data {
        var lastError: Error = URLError(.badURL)
        for string in urls {
            guard let url = URL(string: string) else { continue }
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                    return data
                }
                lastError = URLError(.badServerResponse)
            } catch {
                lastError = error
            }
        }
        throw lastError
    }

    nonisolated private static func download() async throws -> Snapshot {
        struct Entry: Decodable {
            let id: Int
            let name: String
        }
        let lists = [
            ("tag", "tags"), ("artist", "artists"), ("group", "groups"),
            ("parody", "parodies"), ("character", "characters"),
        ]
        var tags: [Int: TagName] = [:]
        for (type, file) in lists {
            let data = try await fetch([
                "https://fastly.jsdelivr.net/gh/honjow/nhentai_tags_fetcher@master/assets/\(file).json",
                "https://raw.githubusercontent.com/honjow/nhentai_tags_fetcher/master/assets/\(file).json",
            ])
            for entry in try JSONDecoder().decode([Entry].self, from: data) {
                tags[entry.id] = TagName(name: entry.name, type: type)
            }
        }

        struct Database: Decodable {
            struct Namespace: Decodable {
                let namespace: String
                let data: [String: Item]
            }
            struct Item: Decodable {
                let name: String
            }
            let data: [Namespace]
        }
        var translations: [String: [String: String]] = [:]
        if let data = try? await fetch([
            "https://fastly.jsdelivr.net/gh/EhTagTranslation/DatabaseReleases/db.text.json",
            "https://cdn.jsdelivr.net/gh/EhTagTranslation/DatabaseReleases/db.text.json",
        ]), let database = try? JSONDecoder().decode(Database.self, from: data) {
            for namespace in database.data {
                translations[namespace.namespace] = namespace.data.mapValues {
                    $0.name.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        if translations.isEmpty, let previous = readCache() {
            translations = previous.translations
        }
        let snapshot = Snapshot(tags: tags, translations: translations, date: Date())
        writeCache(snapshot)
        return snapshot
    }
}
