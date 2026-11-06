package com.atlanyuey.nhentai.core

import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.longOrNull

// MARK: - Hosts

object NHHost {
    const val SITE = "https://nhentai.net"
    private const val THUMBS = "https://t.nhentai.net/"
    private const val IMAGES = "https://i.nhentai.net/"

    fun thumb(path: String?): String? {
        if (path.isNullOrEmpty()) return null
        if (path.startsWith("http")) return path
        return THUMBS + path.removePrefix("/")
    }

    fun image(path: String?): String? {
        if (path.isNullOrEmpty()) return null
        if (path.startsWith("http")) return path
        return IMAGES + path.removePrefix("/")
    }

    fun gallery(id: Int) = "$SITE/g/$id/"
}

// MARK: - Lenient JSON helpers (the API mixes strings and numbers)

internal fun JsonElement?.obj(): JsonObject? = this as? JsonObject
internal fun JsonElement?.arr(): JsonArray? = this as? JsonArray

internal fun JsonObject.str(key: String): String? {
    val p = this[key] as? JsonPrimitive ?: return null
    if (p is JsonNull) return null
    return p.content
}

internal fun JsonObject.int(key: String): Int? {
    val p = this[key] as? JsonPrimitive ?: return null
    if (p is JsonNull) return null
    return p.longOrNull?.toInt() ?: p.doubleOrNull?.toInt() ?: p.content.toIntOrNull()
}

internal fun JsonObject.long(key: String): Long? {
    val p = this[key] as? JsonPrimitive ?: return null
    if (p is JsonNull) return null
    return p.longOrNull ?: p.doubleOrNull?.toLong() ?: p.content.toLongOrNull()
}

internal fun JsonObject.bool(key: String): Boolean? {
    val p = this[key] as? JsonPrimitive ?: return null
    if (p is JsonNull) return null
    return p.booleanOrNull
}

// MARK: - Galleries

/** Language shown as a badge, derived from well-known language tag ids. */
enum class GalleryLanguage(val badge: String) {
    Japanese("JP"), Chinese("ZH"), English("EN");

    companion object {
        fun from(tagIds: Collection<Int>): GalleryLanguage? = when {
            6346 in tagIds -> Japanese
            29963 in tagIds -> Chinese
            12227 in tagIds -> English
            else -> null
        }
    }
}

/** An entry of a gallery list. */
@Serializable
data class GalleryItem(
    val id: Int,
    val mediaId: String = "",
    val englishTitle: String? = null,
    val japaneseTitle: String? = null,
    val thumbnail: String? = null,
    val thumbnailWidth: Int = 0,
    val thumbnailHeight: Int = 0,
    val numPages: Int = 0,
    val numFavorites: Int = 0,
    val tagIds: List<Int> = emptyList(),
    val blacklisted: Boolean = false,
) {
    val title: String
        get() = englishTitle?.takeIf { it.isNotEmpty() } ?: japaneseTitle ?: "#$id"

    /** The title without the leading [circle] / (event) parts. */
    val prettyTitle: String get() = pretty(title)

    val thumbUrl: String? get() = NHHost.thumb(thumbnail)

    /** Width / height of the cover thumbnail. */
    val aspectRatio: Float
        get() = if (thumbnailWidth > 0 && thumbnailHeight > 0) thumbnailWidth.toFloat() / thumbnailHeight else 0.7f

    val language: GalleryLanguage? get() = GalleryLanguage.from(tagIds)

    companion object {
        fun parse(o: JsonObject) = GalleryItem(
            id = o.int("id") ?: 0,
            mediaId = o.str("media_id") ?: "",
            englishTitle = o.str("english_title"),
            japaneseTitle = o.str("japanese_title"),
            thumbnail = o.str("thumbnail"),
            thumbnailWidth = o.int("thumbnail_width") ?: 0,
            thumbnailHeight = o.int("thumbnail_height") ?: 0,
            numPages = o.int("num_pages") ?: 0,
            numFavorites = o.int("num_favorites") ?: 0,
            tagIds = o["tag_ids"].arr()?.mapNotNull { (it as? JsonPrimitive)?.longOrNull?.toInt() } ?: emptyList(),
            blacklisted = o.bool("blacklisted") ?: false,
        )

        private val leading = Regex("""^\s*(\([^)]*\)\s*)?(\[[^\]]*]\s*)?""")
        private val trailing = Regex("""(\s*\[[^\]]*]|\s*\([^)]*\)|\s*\{[^}]*})+\s*$""")

        fun pretty(title: String): String {
            val result = title.replaceFirst(leading, "").replaceFirst(trailing, "").trim()
            return result.ifEmpty { title }
        }
    }
}

/** A paginated list response. */
data class PageResponse<T>(val result: List<T>, val numPages: Int, val total: Int?) {
    companion object {
        fun <T> parse(o: JsonObject, item: (JsonObject) -> T) = PageResponse(
            result = o["result"].arr()?.mapNotNull { it.obj()?.let(item) } ?: emptyList(),
            numPages = o.int("num_pages") ?: 1,
            total = o.int("total"),
        )
    }
}

data class ImageInfo(val path: String, val width: Int, val height: Int) {
    companion object {
        fun parse(o: JsonObject?) = o?.let {
            ImageInfo(it.str("path") ?: "", it.int("width") ?: 0, it.int("height") ?: 0)
        }
    }
}

data class GalleryPage(
    val number: Int,
    val path: String,
    val width: Int,
    val height: Int,
    val thumbnail: String?,
) {
    val imageUrl: String? get() = NHHost.image(path)
    val thumbUrl: String? get() = NHHost.thumb(thumbnail) ?: NHHost.image(path)
    val aspectRatio: Float get() = if (width > 0 && height > 0) width.toFloat() / height else 0.7f

    companion object {
        fun parse(o: JsonObject) = GalleryPage(
            number = o.int("number") ?: 0,
            path = o.str("path") ?: "",
            width = o.int("width") ?: 0,
            height = o.int("height") ?: 0,
            thumbnail = o.str("thumbnail"),
        )
    }
}

data class GalleryTag(
    val id: Int,
    val type: String,
    val name: String,
    val url: String?,
    val count: Int?,
) {
    /** Search syntax for this tag, e.g. `artist:"name"`. */
    val query: String
        get() {
            val prefix = url?.split("/")?.firstOrNull { it.isNotEmpty() } ?: type
            return "$prefix:\"$name\""
        }

    companion object {
        fun parse(o: JsonObject) = GalleryTag(
            id = o.int("id") ?: 0,
            type = o.str("type") ?: "tag",
            name = o.str("name") ?: "",
            url = o.str("url"),
            count = o.int("count"),
        )
    }
}

enum class TagGroup(val key: String, val title: String) {
    Parody("parody", "Parodies"),
    Character("character", "Characters"),
    Tag("tag", "Tags"),
    Artist("artist", "Artists"),
    Group("group", "Groups"),
    Language("language", "Languages"),
    Category("category", "Categories"),
}

data class GalleryDetail(
    val id: Int,
    val mediaId: String,
    val englishTitle: String?,
    val japaneseTitle: String?,
    val prettyTitle: String?,
    val cover: ImageInfo?,
    val thumbnail: ImageInfo?,
    val uploadDate: Long?,
    val tags: List<GalleryTag>,
    val numPages: Int,
    val numFavorites: Int,
    val pages: List<GalleryPage>,
    val related: List<GalleryItem>,
    val isFavorited: Boolean?,
) {
    val displayTitle: String get() = englishTitle ?: japaneseTitle ?: prettyTitle ?: "#$id"
    val subtitle: String? get() = japaneseTitle?.takeIf { it != displayTitle }
    val coverUrl: String? get() = NHHost.thumb(cover?.path ?: thumbnail?.path)
    val thumbUrl: String? get() = NHHost.thumb(thumbnail?.path ?: cover?.path)
    val language: GalleryLanguage? get() = GalleryLanguage.from(tags.map { it.id })
    val url: String get() = NHHost.gallery(id)

    fun tags(group: TagGroup) = tags.filter { it.type == group.key }

    /** A list item for this gallery (history, sharing between screens). */
    val asItem: GalleryItem
        get() = GalleryItem(
            id = id, mediaId = mediaId, englishTitle = displayTitle,
            thumbnail = thumbnail?.path ?: cover?.path,
            thumbnailWidth = thumbnail?.width ?: cover?.width ?: 0,
            thumbnailHeight = thumbnail?.height ?: cover?.height ?: 0,
            numPages = numPages,
            tagIds = tags.map { it.id },
        )

    companion object {
        fun parse(o: JsonObject): GalleryDetail {
            val title = o["title"].obj()
            return GalleryDetail(
                id = o.int("id") ?: 0,
                mediaId = o.str("media_id") ?: "",
                englishTitle = title?.str("english")?.takeIf { it.isNotEmpty() },
                japaneseTitle = title?.str("japanese")?.takeIf { it.isNotEmpty() },
                prettyTitle = title?.str("pretty")?.takeIf { it.isNotEmpty() },
                cover = ImageInfo.parse(o["cover"].obj()),
                thumbnail = ImageInfo.parse(o["thumbnail"].obj()),
                uploadDate = o.long("upload_date"),
                tags = o["tags"].arr()?.mapNotNull { it.obj()?.let(GalleryTag::parse) } ?: emptyList(),
                numPages = o.int("num_pages") ?: 0,
                numFavorites = o.int("num_favorites") ?: 0,
                pages = o["pages"].arr()?.mapNotNull { it.obj()?.let(GalleryPage::parse) } ?: emptyList(),
                related = (o["related"].arr()?.mapNotNull { it.obj()?.let(GalleryItem::parse) } ?: emptyList())
                    .filter { !it.blacklisted },
                isFavorited = o.bool("is_favorited"),
            )
        }
    }
}

// MARK: - Comments / users

data class CommentPoster(val id: Int, val username: String, val avatarUrl: String?) {
    val avatar: String? get() = avatarUrl?.takeIf { it.isNotEmpty() }?.let { NHHost.image(it) }

    companion object {
        fun parse(o: JsonObject?) = o?.let {
            CommentPoster(it.int("id") ?: 0, it.str("username") ?: "", it.str("avatar_url"))
        }
    }
}

data class GalleryComment(val id: Int, val poster: CommentPoster?, val postDate: Long, val body: String) {
    companion object {
        fun parse(o: JsonObject) = GalleryComment(
            id = o.int("id") ?: 0,
            poster = CommentPoster.parse(o["poster"].obj()),
            postDate = o.long("post_date") ?: 0,
            body = o.str("body") ?: "",
        )
    }
}

data class CurrentUser(val id: Int, val username: String, val avatarUrl: String?) {
    val avatar: String? get() = avatarUrl?.takeIf { it.isNotEmpty() }?.let { NHHost.image(it) }

    companion object {
        fun parse(o: JsonObject) = CurrentUser(o.int("id") ?: 0, o.str("username") ?: "", o.str("avatar_url"))
    }
}

data class FavoriteResult(val favorited: Boolean?, val numFavorites: Int?)

data class TagSuggestion(val id: Int, val type: String, val name: String, val count: Int?) {
    val query: String get() = "$type:\"$name\""

    companion object {
        fun parse(o: JsonObject) = TagSuggestion(
            id = o.int("id") ?: 0,
            type = o.str("type") ?: "tag",
            name = o.str("name") ?: "",
            count = o.int("count"),
        )
    }
}
