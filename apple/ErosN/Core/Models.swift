import Foundation

// MARK: - Hosts

enum NHHost {
    static let site = URL(string: "https://nhentai.net")!
    static let thumbs = "https://t.nhentai.net/"
    static let images = "https://i.nhentai.net/"

    static func thumb(_ path: String?) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        if path.hasPrefix("http") { return URL(string: path) }
        return URL(string: thumbs + path.trimmingPrefix("/"))
    }

    static func image(_ path: String?) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        if path.hasPrefix("http") { return URL(string: path) }
        return URL(string: images + path.trimmingPrefix("/"))
    }

    static func gallery(_ id: Int) -> URL {
        site.appendingPathComponent("g/\(id)/")
    }
}

private extension String {
    func trimmingPrefix(_ prefix: String) -> String {
        hasPrefix(prefix) ? String(dropFirst(prefix.count)) : self
    }
}

// MARK: - Lenient decoding helpers

/// Decodes a value that the API sends either as a string or as a number.
struct LenientString: Decodable, Hashable {
    let value: String

    init(_ value: String) { self.value = value }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = String(int)
        } else if let double = try? container.decode(Double.self) {
            value = String(Int(double))
        } else {
            value = ""
        }
    }
}

// MARK: - Galleries

/// Language shown as a badge, derived from well-known language tag ids.
enum GalleryLanguage: String, Codable, CaseIterable, Identifiable {
    case japanese, chinese, english

    var id: String { rawValue }

    static func from(tagIDs: [Int]) -> GalleryLanguage? {
        if tagIDs.contains(6346) { return .japanese }
        if tagIDs.contains(29963) { return .chinese }
        if tagIDs.contains(12227) { return .english }
        return nil
    }

    var badge: String {
        switch self {
        case .japanese: "JP"
        case .chinese: "ZH"
        case .english: "EN"
        }
    }
}

/// An entry of a gallery list (`GalleryListItem`).
struct GalleryItem: Decodable, Identifiable, Hashable {
    let id: Int
    let mediaID: String
    let englishTitle: String?
    let japaneseTitle: String?
    let thumbnail: String?
    let thumbnailWidth: Int
    let thumbnailHeight: Int
    let numPages: Int
    let numFavorites: Int
    let tagIDs: [Int]
    let blacklisted: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case mediaID = "media_id"
        case englishTitle = "english_title"
        case japaneseTitle = "japanese_title"
        case thumbnail
        case thumbnailWidth = "thumbnail_width"
        case thumbnailHeight = "thumbnail_height"
        case numPages = "num_pages"
        case numFavorites = "num_favorites"
        case tagIDs = "tag_ids"
        case blacklisted
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        mediaID = (try? c.decode(LenientString.self, forKey: .mediaID))?.value ?? ""
        englishTitle = try? c.decodeIfPresent(String.self, forKey: .englishTitle)
        japaneseTitle = try? c.decodeIfPresent(String.self, forKey: .japaneseTitle)
        thumbnail = try? c.decodeIfPresent(String.self, forKey: .thumbnail)
        thumbnailWidth = (try? c.decodeIfPresent(Int.self, forKey: .thumbnailWidth)) ?? 0
        thumbnailHeight = (try? c.decodeIfPresent(Int.self, forKey: .thumbnailHeight)) ?? 0
        numPages = (try? c.decodeIfPresent(Int.self, forKey: .numPages)) ?? 0
        numFavorites = (try? c.decodeIfPresent(Int.self, forKey: .numFavorites)) ?? 0
        tagIDs = (try? c.decodeIfPresent([Int].self, forKey: .tagIDs)) ?? []
        blacklisted = (try? c.decodeIfPresent(Bool.self, forKey: .blacklisted)) ?? false
    }

    init(id: Int, mediaID: String, title: String?, thumbnail: String?,
         thumbnailWidth: Int = 0, thumbnailHeight: Int = 0) {
        self.id = id
        self.mediaID = mediaID
        self.englishTitle = title
        self.japaneseTitle = nil
        self.thumbnail = thumbnail
        self.thumbnailWidth = thumbnailWidth
        self.thumbnailHeight = thumbnailHeight
        self.numPages = 0
        self.numFavorites = 0
        self.tagIDs = []
        self.blacklisted = false
    }

    var title: String { (englishTitle?.isEmpty == false ? englishTitle : japaneseTitle) ?? "#\(id)" }

    /// The title without the leading [circle] / (event) parts.
    var prettyTitle: String { Self.pretty(title) }

    var thumbURL: URL? { NHHost.thumb(thumbnail) }

    /// Width / height of the cover thumbnail.
    var aspectRatio: CGFloat {
        guard thumbnailWidth > 0, thumbnailHeight > 0 else { return 0.7 }
        return CGFloat(thumbnailWidth) / CGFloat(thumbnailHeight)
    }

    var language: GalleryLanguage? { GalleryLanguage.from(tagIDs: tagIDs) }

    static func pretty(_ title: String) -> String {
        var result = title
        let patterns = [#"^\s*(\([^)]*\)\s*)?(\[[^\]]*\]\s*)?"#, #"(\s*\[[^\]]*\]|\s*\([^)]*\)|\s*\{[^}]*\})+\s*$"#]
        for pattern in patterns {
            if let range = result.range(of: pattern, options: .regularExpression) {
                result.removeSubrange(range)
            }
        }
        result = result.trimmingCharacters(in: .whitespaces)
        return result.isEmpty ? title : result
    }
}

/// A paginated list response.
struct PageResponse<Item: Decodable>: Decodable {
    let result: [Item]
    let numPages: Int
    let total: Int?

    enum CodingKeys: String, CodingKey {
        case result
        case numPages = "num_pages"
        case total
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        result = (try? c.decode([Item].self, forKey: .result)) ?? []
        numPages = (try? c.decodeIfPresent(Int.self, forKey: .numPages)) ?? 1
        total = try? c.decodeIfPresent(Int.self, forKey: .total)
    }
}

struct ImageInfo: Decodable, Hashable {
    let path: String
    let width: Int
    let height: Int

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        path = (try? c.decode(String.self, forKey: .path)) ?? ""
        width = (try? c.decodeIfPresent(Int.self, forKey: .width)) ?? 0
        height = (try? c.decodeIfPresent(Int.self, forKey: .height)) ?? 0
    }

    enum CodingKeys: String, CodingKey { case path, width, height }
}

struct GalleryPage: Decodable, Identifiable, Hashable {
    let number: Int
    let path: String
    let width: Int
    let height: Int
    let thumbnail: String?

    var id: Int { number }
    var imageURL: URL? { NHHost.image(path) }
    var thumbURL: URL? { NHHost.thumb(thumbnail) ?? NHHost.image(path) }
    var aspectRatio: CGFloat {
        guard width > 0, height > 0 else { return 0.7 }
        return CGFloat(width) / CGFloat(height)
    }

    enum CodingKeys: String, CodingKey { case number, path, width, height, thumbnail }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        number = (try? c.decode(Int.self, forKey: .number)) ?? 0
        path = (try? c.decode(String.self, forKey: .path)) ?? ""
        width = (try? c.decodeIfPresent(Int.self, forKey: .width)) ?? 0
        height = (try? c.decodeIfPresent(Int.self, forKey: .height)) ?? 0
        thumbnail = try? c.decodeIfPresent(String.self, forKey: .thumbnail)
    }
}

struct GalleryTag: Decodable, Identifiable, Hashable {
    let id: Int
    let type: String
    let name: String
    let url: String?
    let count: Int?

    enum CodingKeys: String, CodingKey { case id, type, name, url, count }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(Int.self, forKey: .id)) ?? 0
        type = (try? c.decode(String.self, forKey: .type)) ?? "tag"
        name = (try? c.decode(String.self, forKey: .name)) ?? ""
        url = try? c.decodeIfPresent(String.self, forKey: .url)
        count = try? c.decodeIfPresent(Int.self, forKey: .count)
    }

    /// Search syntax for this tag, e.g. `artist:"name"`.
    var query: String {
        let prefix = url.flatMap { url -> String? in
            let parts = url.split(separator: "/")
            return parts.first.map(String.init)
        } ?? type
        return "\(prefix):\"\(name)\""
    }
}

enum TagGroup: String, CaseIterable, Identifiable {
    case parody, character, tag, artist, group, language, category

    var id: String { rawValue }

    var title: String {
        switch self {
        case .parody: String(localized: "Parodies")
        case .character: String(localized: "Characters")
        case .tag: String(localized: "Tags")
        case .artist: String(localized: "Artists")
        case .group: String(localized: "Groups")
        case .language: String(localized: "Languages")
        case .category: String(localized: "Categories")
        }
    }
}

struct GalleryTitles: Decodable, Hashable {
    let english: String?
    let japanese: String?
    let pretty: String?
}

/// `GalleryDetailResponse`.
struct GalleryDetail: Decodable, Identifiable, Hashable {
    let id: Int
    let mediaID: String
    let title: GalleryTitles
    let cover: ImageInfo?
    let thumbnail: ImageInfo?
    let scanlator: String?
    let uploadDate: Int?
    let tags: [GalleryTag]
    let numPages: Int
    let numFavorites: Int
    let pages: [GalleryPage]
    let related: [GalleryItem]
    let isFavorited: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case mediaID = "media_id"
        case title, cover, thumbnail, scanlator
        case uploadDate = "upload_date"
        case tags
        case numPages = "num_pages"
        case numFavorites = "num_favorites"
        case pages, related
        case isFavorited = "is_favorited"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        mediaID = (try? c.decode(LenientString.self, forKey: .mediaID))?.value ?? ""
        title = (try? c.decode(GalleryTitles.self, forKey: .title))
            ?? GalleryTitles(english: nil, japanese: nil, pretty: nil)
        cover = try? c.decodeIfPresent(ImageInfo.self, forKey: .cover)
        thumbnail = try? c.decodeIfPresent(ImageInfo.self, forKey: .thumbnail)
        scanlator = try? c.decodeIfPresent(String.self, forKey: .scanlator)
        uploadDate = try? c.decodeIfPresent(Int.self, forKey: .uploadDate)
        tags = (try? c.decodeIfPresent([GalleryTag].self, forKey: .tags)) ?? []
        numPages = (try? c.decodeIfPresent(Int.self, forKey: .numPages)) ?? 0
        numFavorites = (try? c.decodeIfPresent(Int.self, forKey: .numFavorites)) ?? 0
        pages = (try? c.decodeIfPresent([GalleryPage].self, forKey: .pages)) ?? []
        related = ((try? c.decodeIfPresent([GalleryItem].self, forKey: .related)) ?? [])
            .filter { !$0.blacklisted }
        isFavorited = try? c.decodeIfPresent(Bool.self, forKey: .isFavorited)
    }

    var displayTitle: String { title.english ?? title.japanese ?? title.pretty ?? "#\(id)" }
    var subtitle: String? {
        guard let japanese = title.japanese, japanese != displayTitle else { return nil }
        return japanese
    }
    var coverURL: URL? { NHHost.thumb(cover?.path ?? thumbnail?.path) }
    var thumbURL: URL? { NHHost.thumb(thumbnail?.path ?? cover?.path) }
    var uploaded: Date? { uploadDate.map { Date(timeIntervalSince1970: TimeInterval($0)) } }
    var language: GalleryLanguage? { GalleryLanguage.from(tagIDs: tags.map(\.id)) }
    var url: URL { NHHost.gallery(id) }

    func tags(in group: TagGroup) -> [GalleryTag] {
        tags.filter { $0.type == group.rawValue }
    }

    /// A list item for this gallery (history, sharing between screens).
    var asItem: GalleryItem {
        GalleryItem(
            id: id, mediaID: mediaID, title: displayTitle,
            thumbnail: thumbnail?.path ?? cover?.path,
            thumbnailWidth: thumbnail?.width ?? cover?.width ?? 0,
            thumbnailHeight: thumbnail?.height ?? cover?.height ?? 0
        )
    }
}

// MARK: - Comments / users

struct CommentPoster: Decodable, Hashable {
    let id: Int
    let username: String
    let avatarURL: String?

    enum CodingKeys: String, CodingKey {
        case id, username
        case avatarURL = "avatar_url"
    }

    var avatar: URL? {
        guard let avatarURL, !avatarURL.isEmpty else { return nil }
        return NHHost.image(avatarURL)
    }
}

struct GalleryComment: Decodable, Identifiable, Hashable {
    let id: Int
    let poster: CommentPoster?
    let postDate: Int
    let body: String

    enum CodingKeys: String, CodingKey {
        case id, poster
        case postDate = "post_date"
        case body
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        poster = try? c.decodeIfPresent(CommentPoster.self, forKey: .poster)
        postDate = (try? c.decodeIfPresent(Int.self, forKey: .postDate)) ?? 0
        body = (try? c.decodeIfPresent(String.self, forKey: .body)) ?? ""
    }

    var date: Date { Date(timeIntervalSince1970: TimeInterval(postDate)) }
}

struct CurrentUser: Decodable, Hashable {
    let id: Int
    let username: String
    let avatarURL: String?

    enum CodingKeys: String, CodingKey {
        case id, username
        case avatarURL = "avatar_url"
    }

    var avatar: URL? {
        guard let avatarURL, !avatarURL.isEmpty else { return nil }
        return NHHost.image(avatarURL)
    }
}

struct FavoriteResult: Decodable {
    let favorited: Bool?
    let numFavorites: Int?

    enum CodingKeys: String, CodingKey {
        case favorited
        case numFavorites = "num_favorites"
    }
}

struct TagSuggestion: Decodable, Identifiable, Hashable {
    let id: Int
    let type: String
    let name: String
    let count: Int?

    var query: String { "\(type):\"\(name)\"" }
}

// MARK: - Navigation values

/// Opens a gallery's detail page.
struct GalleryRoute: Hashable {
    let id: Int
    var preview: GalleryItem?
}

/// Opens a search for [query] (e.g. from a tag).
struct SearchRoute: Hashable {
    let query: String
    var title: String?
}
