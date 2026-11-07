package com.atlanyuey.nhentai.core

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Semaphore
import kotlinx.coroutines.sync.withPermit
import kotlinx.coroutines.withContext
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.serialization.Serializable
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.JsonObject
import okhttp3.Request
import java.io.File

/** Coroutine scope for app-wide work (saving files, downloads). */
val AppScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

// MARK: - History

/** A gallery the user opened, with the last page read. */
@Serializable
data class HistoryEntry(
    val gid: Int,
    val mediaId: String,
    val title: String,
    val thumbnail: String?,
    val thumbWidth: Int,
    val thumbHeight: Int,
    val numPages: Int,
    val lastPage: Int,
    val lastRead: Long,
    /** For the language badge and tags on cards (empty for entries from before 2.1.0). */
    val tagIds: List<Int> = emptyList(),
) {
    val item: GalleryItem
        get() = GalleryItem(
            id = gid, mediaId = mediaId, englishTitle = title, thumbnail = thumbnail,
            thumbnailWidth = thumbWidth, thumbnailHeight = thumbHeight, numPages = numPages,
            tagIds = tagIds,
        )
}

object HistoryStore {
    private lateinit var file: File
    val entries = mutableStateListOf<HistoryEntry>()
    private var saveJob: Job? = null

    fun init(context: Context) {
        file = File(context.filesDir, "history.json")
        val loaded = try {
            Net.json.decodeFromString(ListSerializer(HistoryEntry.serializer()), file.readText())
        } catch (_: Exception) {
            emptyList()
        }
        entries.addAll(loaded.sortedByDescending { it.lastRead })
    }

    fun record(item: GalleryItem, title: String, numPages: Int, page: Int? = null) {
        val index = entries.indexOfFirst { it.gid == item.id }
        val previous = entries.getOrNull(index)
        val entry = HistoryEntry(
            gid = item.id,
            mediaId = item.mediaId.ifEmpty { previous?.mediaId ?: "" },
            title = title,
            thumbnail = item.thumbnail ?: previous?.thumbnail,
            thumbWidth = if (item.thumbnailWidth > 0) item.thumbnailWidth else previous?.thumbWidth ?: 0,
            thumbHeight = if (item.thumbnailHeight > 0) item.thumbnailHeight else previous?.thumbHeight ?: 0,
            numPages = if (numPages > 0) numPages else previous?.numPages ?: 0,
            lastPage = page ?: previous?.lastPage ?: 0,
            lastRead = System.currentTimeMillis(),
            tagIds = item.tagIds.ifEmpty { previous?.tagIds ?: emptyList() },
        )
        if (index >= 0) entries.removeAt(index)
        entries.add(0, entry)
        save()
    }

    fun record(detail: GalleryDetail, page: Int? = null) =
        record(detail.asItem, detail.displayTitle, detail.numPages, page)

    fun lastReadPage(gid: Int): Int? = entries.firstOrNull { it.gid == gid }?.lastPage

    fun delete(gid: Int) {
        entries.removeAll { it.gid == gid }
        save()
    }

    fun clear() {
        entries.clear()
        save()
    }

    private fun save() {
        saveJob?.cancel()
        saveJob = AppScope.launch {
            delay(500)
            val snapshot = entries.toList()
            withContext(Dispatchers.IO) {
                runCatching {
                    file.writeText(Net.json.encodeToString(ListSerializer(HistoryEntry.serializer()), snapshot))
                }
            }
        }
    }
}

// MARK: - Downloads

@Serializable
data class DownloadPage(
    val number: Int,
    val remote: String,
    val file: String,
    val width: Int,
    val height: Int,
)

@Serializable
data class DownloadRecord(
    val id: Int,
    val mediaId: String,
    val title: String,
    val thumbnail: String?,
    val thumbWidth: Int,
    val thumbHeight: Int,
    val pages: List<DownloadPage>,
    val completed: Int,
    val state: String,
    val added: Long,
    /** For the language badge and tags on cards (null for downloads from before 2.1.0). */
    val tagIds: List<Int>? = null,
) {
    val progress: Float get() = if (pages.isEmpty()) 0f else completed.toFloat() / pages.size

    val item: GalleryItem
        get() = GalleryItem(
            id = id, mediaId = mediaId, englishTitle = title, thumbnail = thumbnail,
            thumbnailWidth = thumbWidth, thumbnailHeight = thumbHeight, numPages = pages.size,
            tagIds = tagIds ?: emptyList(),
        )

    companion object {
        const val QUEUED = "queued"
        const val DOWNLOADING = "downloading"
        const val PAUSED = "paused"
        const val FINISHED = "finished"
        const val FAILED = "failed"
    }
}

/** Downloads gallery pages for offline reading (three at a time). */
object Downloads {
    private lateinit var root: File
    val records = mutableStateListOf<DownloadRecord>()
    private val jobs = mutableMapOf<Int, Job>()
    private var lastSave = 0L

    fun init(context: Context) {
        root = File(context.filesDir, "Downloads")
        val loaded = try {
            Net.json.decodeFromString(ListSerializer(DownloadRecord.serializer()), File(root, "index.json").readText())
        } catch (_: Exception) {
            emptyList()
        }
        // Downloads interrupted by the app being closed resume as paused.
        records.addAll(loaded.map {
            if (it.state == DownloadRecord.DOWNLOADING || it.state == DownloadRecord.QUEUED) {
                it.copy(state = DownloadRecord.PAUSED)
            } else {
                it
            }
        })
    }

    fun record(id: Int): DownloadRecord? = records.firstOrNull { it.id == id }

    fun folder(id: Int) = File(root, "$id")

    /** Local file of a page if it has been downloaded. */
    fun localFile(galleryId: Int, index: Int): File? {
        val record = record(galleryId) ?: return null
        val page = record.pages.getOrNull(index) ?: return null
        return File(folder(galleryId), page.file).takeIf { it.exists() }
    }

    private fun detailFile(id: Int) = File(folder(id), "gallery.json")

    /**
     * The page of a downloaded gallery without the network: the gallery's
     * JSON saved with the download, or what the download record knows.
     */
    fun offlineDetail(id: Int): GalleryDetail? {
        val record = record(id) ?: return null
        val saved = runCatching {
            Net.json.parseToJsonElement(detailFile(id).readText()).obj()?.let(GalleryDetail::parse)
        }.getOrNull()
        return saved ?: GalleryDetail.from(record)
    }

    /** Keeps the gallery's [json] (as the API sent it) with its download, for its page offline. */
    fun saveDetail(json: JsonObject, detail: GalleryDetail) {
        val record = record(detail.id) ?: return
        if (record.tagIds == null) {
            update(detail.id) { it.copy(tagIds = detail.tags.map { tag -> tag.id }) }
            saveIndex()
        }
        val file = detailFile(detail.id)
        AppScope.launch(Dispatchers.IO) {
            runCatching {
                file.parentFile?.mkdirs()
                file.writeText(json.toString())
            }
        }
    }

    /** Downloads [detail]; [json] is its JSON, kept for its page offline. */
    fun start(detail: GalleryDetail, json: JsonObject? = null) {
        if (record(detail.id) == null) {
            val item = detail.asItem
            val pages = detail.pages.mapIndexed { offset, page ->
                val ext = page.path.substringAfterLast('.', "").ifEmpty { "jpg" }
                DownloadPage(
                    number = page.number,
                    remote = page.imageUrl ?: "",
                    file = String.format(java.util.Locale.ROOT, "%04d.%s", offset + 1, ext),
                    width = page.width,
                    height = page.height,
                )
            }
            records.add(
                0,
                DownloadRecord(
                    id = detail.id, mediaId = detail.mediaId, title = detail.displayTitle,
                    thumbnail = item.thumbnail, thumbWidth = item.thumbnailWidth,
                    thumbHeight = item.thumbnailHeight, pages = pages, completed = 0,
                    state = DownloadRecord.QUEUED, added = System.currentTimeMillis(),
                    tagIds = detail.tags.map { it.id },
                ),
            )
            saveIndex()
        }
        json?.let { saveDetail(it, detail) }
        resume(detail.id)
    }

    fun resume(id: Int) {
        val record = record(id) ?: return
        if (jobs[id] != null || record.state == DownloadRecord.FINISHED) return
        update(id) { it.copy(state = DownloadRecord.DOWNLOADING) }
        saveIndex()
        jobs[id] = AppScope.launch { run(id) }
    }

    fun pause(id: Int) {
        jobs.remove(id)?.cancel()
        update(id) { it.copy(state = DownloadRecord.PAUSED) }
        saveIndex()
    }

    fun delete(id: Int) {
        jobs.remove(id)?.cancel()
        records.removeAll { it.id == id }
        AppScope.launch(Dispatchers.IO) { folder(id).deleteRecursively() }
        saveIndex()
    }

    private suspend fun run(id: Int) {
        val record = record(id) ?: return
        val folder = folder(id)
        val pending = withContext(Dispatchers.IO) {
            folder.mkdirs()
            record.pages.filter { !File(folder, it.file).exists() }
        }
        update(id) { it.copy(completed = it.pages.size - pending.size) }
        var failures = 0
        val semaphore = Semaphore(3)
        coroutineScope {
            pending.map { page ->
                async {
                    val ok = semaphore.withPermit { fetch(page, File(folder, page.file)) }
                    if (ok) update(id) { it.copy(completed = it.completed + 1) } else failures++
                    if (System.currentTimeMillis() - lastSave > 2000) saveIndex()
                }
            }.awaitAll()
        }
        jobs.remove(id)
        update(id) {
            it.copy(
                state = if (failures == 0 && it.completed >= it.pages.size) DownloadRecord.FINISHED
                else DownloadRecord.FAILED,
            )
        }
        saveIndex()
    }

    private suspend fun fetch(page: DownloadPage, file: File): Boolean = withContext(Dispatchers.IO) {
        repeat(3) { attempt ->
            if (!isActive) return@withContext false
            try {
                val request = Request.Builder().url(page.remote).build()
                val ok = Net.client.newCall(request).execute().use { response ->
                    if (response.code != 200) return@use false
                    val temp = File(file.parentFile, file.name + ".part")
                    temp.outputStream().use { out -> response.body.byteStream().copyTo(out) }
                    temp.length() > 0 && temp.renameTo(file)
                }
                if (ok) return@withContext true
            } catch (_: Exception) {
            }
            delay(1000L * (attempt + 1))
        }
        false
    }

    private fun update(id: Int, change: (DownloadRecord) -> DownloadRecord) {
        val index = records.indexOfFirst { it.id == id }
        if (index >= 0) records[index] = change(records[index])
    }

    private fun saveIndex() {
        lastSave = System.currentTimeMillis()
        val snapshot = records.toList()
        AppScope.launch(Dispatchers.IO) {
            runCatching {
                root.mkdirs()
                File(root, "index.json").writeText(
                    Net.json.encodeToString(ListSerializer(DownloadRecord.serializer()), snapshot),
                )
            }
        }
    }

    /** Bytes used by downloads. */
    fun diskUsage(): Long = root.walkTopDown().filter { it.isFile }.sumOf { it.length() }
}

// MARK: - Tags

@Serializable
data class TagName(val name: String, val type: String)

@Serializable
private data class TagSnapshot(
    val tags: Map<Int, TagName>,
    val translations: Map<String, Map<String, String>>,
    val date: Long,
)

/**
 * Local tag database: maps the tag ids of list items to names and
 * translates tag names to Chinese (EhTagTranslation). Downloaded once and
 * refreshed weekly; jsDelivr is tried first because GitHub is often slow.
 */
object TagStore {
    private lateinit var cacheFile: File
    private var tags: Map<Int, TagName> = emptyMap()
    private var translations: Map<String, Map<String, String>> = emptyMap()
    private var prepared = false

    var isUpdating by mutableStateOf(false)
        private set
    var lastUpdated by mutableStateOf<Long?>(null)
        private set
    var tagCount by mutableIntStateOf(0)
        private set
    var translationCount by mutableIntStateOf(0)
        private set
    /** Bumped when the data changes, so views that read tags refresh. */
    var revision by mutableIntStateOf(0)
        private set

    private val builtIn = mapOf(
        6346 to TagName("japanese", "language"),
        12227 to TagName("english", "language"),
        29963 to TagName("chinese", "language"),
        17249 to TagName("translated", "language"),
        33173 to TagName("manga", "category"),
    )

    fun init(context: Context) {
        cacheFile = File(File(context.filesDir, "Tags"), "tags.json")
    }

    fun tag(id: Int): TagName? = tags[id] ?: builtIn[id]

    /** The name to show for a tag (translated when the setting is on). */
    fun displayName(name: String, type: String): String {
        revision
        if (!AppSettings.translateTags) return name
        return translate(name, type) ?: name
    }

    fun translate(name: String, type: String): String? {
        val namespaces = when (type) {
            "tag" -> listOf("female", "male", "mixed", "other", "location", "cosplayer")
            "category" -> listOf("reclass")
            else -> listOf(type)
        }
        for (namespace in namespaces) {
            translations[namespace]?.get(name)?.takeIf { it.isNotEmpty() }?.let { return it }
        }
        return null
    }

    /** Tags shown on a card: languages first, then content tags. */
    fun cardTags(ids: List<Int>, limit: Int = 8): List<TagName> {
        revision
        val languages = mutableListOf<TagName>()
        val others = mutableListOf<TagName>()
        for (id in ids) {
            val tag = tag(id) ?: continue
            if (tag.type == "language") languages += tag else if (tag.type == "tag") others += tag
        }
        return (languages + others).take(limit)
    }

    /** Loads the cached database and refreshes it when missing or old. */
    suspend fun prepare() {
        if (prepared) return
        prepared = true
        withContext(Dispatchers.IO) { readCache() }?.let(::apply)
        val stale = lastUpdated?.let { System.currentTimeMillis() - it > 7L * 24 * 3600 * 1000 } ?: true
        if (stale || tags.isEmpty()) update()
    }

    suspend fun update() {
        if (isUpdating) return
        isUpdating = true
        try {
            withContext(Dispatchers.IO) { download() }?.let(::apply)
        } finally {
            isUpdating = false
        }
    }

    private fun apply(snapshot: TagSnapshot) {
        if (snapshot.tags.isNotEmpty()) tags = snapshot.tags
        if (snapshot.translations.isNotEmpty()) translations = snapshot.translations
        lastUpdated = snapshot.date
        tagCount = tags.size
        translationCount = translations.values.sumOf { it.size }
        revision++
    }

    private fun readCache(): TagSnapshot? = try {
        Net.json.decodeFromString(TagSnapshot.serializer(), cacheFile.readText())
    } catch (_: Exception) {
        null
    }

    private fun fetch(urls: List<String>): String? {
        for (url in urls) {
            try {
                Net.client.newCall(Request.Builder().url(url).build()).execute().use {
                    if (it.code == 200) return it.body.string()
                }
            } catch (_: Exception) {
            }
        }
        return null
    }

    private fun download(): TagSnapshot? {
        val lists = listOf(
            "tag" to "tags", "artist" to "artists", "group" to "groups",
            "parody" to "parodies", "character" to "characters",
        )
        val result = HashMap<Int, TagName>()
        for ((type, file) in lists) {
            val text = fetch(
                listOf(
                    "https://fastly.jsdelivr.net/gh/honjow/nhentai_tags_fetcher@master/assets/$file.json",
                    "https://raw.githubusercontent.com/honjow/nhentai_tags_fetcher/master/assets/$file.json",
                ),
            ) ?: return null
            val array = runCatching { Net.json.parseToJsonElement(text).arr() }.getOrNull() ?: return null
            for (element in array) {
                val o = element as? JsonObject ?: continue
                val id = o.int("id") ?: continue
                val name = o.str("name") ?: continue
                result[id] = TagName(name, type)
            }
        }
        val translated = HashMap<String, Map<String, String>>()
        fetch(
            listOf(
                "https://fastly.jsdelivr.net/gh/EhTagTranslation/DatabaseReleases/db.text.json",
                "https://cdn.jsdelivr.net/gh/EhTagTranslation/DatabaseReleases/db.text.json",
            ),
        )?.let { text ->
            runCatching {
                val data = Net.json.parseToJsonElement(text).obj()?.get("data").arr() ?: return@runCatching
                for (element in data) {
                    val namespace = element.obj() ?: continue
                    val key = namespace.str("namespace") ?: continue
                    val items = namespace["data"].obj() ?: continue
                    translated[key] = items.mapValues { (_, v) -> v.obj()?.str("name")?.trim() ?: "" }
                }
            }
        }
        if (translated.isEmpty()) readCache()?.translations?.let { translated.putAll(it) }
        val snapshot = TagSnapshot(result, translated, System.currentTimeMillis())
        runCatching {
            cacheFile.parentFile?.mkdirs()
            cacheFile.writeText(Net.json.encodeToString(TagSnapshot.serializer(), snapshot))
        }
        return snapshot
    }
}

// MARK: - Feeds

/** A paginated list of galleries with refresh and infinite scroll. */
class GalleryFeed(private val scope: CoroutineScope, var fetch: suspend (Int) -> PageResponse<GalleryItem>) {
    val items = mutableStateListOf<GalleryItem>()
    var isLoading by mutableStateOf(false)
        private set
    var error by mutableStateOf<String?>(null)
        private set
    var hasLoaded by mutableStateOf(false)
        private set
    var total by mutableStateOf<Int?>(null)
        private set

    private var page = 0
    private var pageCount = 1
    private val seen = HashSet<Int>()
    private var generation = 0
    private var job: Job? = null

    val canLoadMore: Boolean get() = hasLoaded && page < pageCount

    fun reload(): Job {
        generation++
        val current = generation
        job?.cancel()
        isLoading = true
        error = null
        return scope.launch {
            try {
                val response = fetch(1)
                if (current != generation) return@launch
                page = 1
                pageCount = maxOf(1, response.numPages)
                total = response.total
                seen.clear()
                items.clear()
                items.addAll(unique(response.result))
            } catch (e: kotlinx.coroutines.CancellationException) {
                throw e
            } catch (e: Exception) {
                if (current == generation) error = e.localizedMessage
            }
            if (current == generation) {
                isLoading = false
                hasLoaded = true
            }
        }.also { job = it }
    }

    fun loadMoreIfNeeded(index: Int) {
        if (index >= items.size - 8) loadMore()
    }

    fun loadMore() {
        if (!canLoadMore || isLoading) return
        val current = generation
        isLoading = true
        job = scope.launch {
            try {
                val response = fetch(page + 1)
                if (current != generation) return@launch
                page++
                pageCount = maxOf(page, response.numPages)
                items.addAll(unique(response.result))
            } catch (e: kotlinx.coroutines.CancellationException) {
                throw e
            } catch (e: Exception) {
                if (current == generation) error = e.localizedMessage
            }
            if (current == generation) isLoading = false
        }
    }

    private fun unique(list: List<GalleryItem>) = list.filter { !it.blacklisted && seen.add(it.id) }
}
