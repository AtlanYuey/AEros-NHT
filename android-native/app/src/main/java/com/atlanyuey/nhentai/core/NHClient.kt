package com.atlanyuey.nhentai.core

import android.content.Context
import android.content.SharedPreferences
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import okhttp3.HttpUrl.Companion.toHttpUrl
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import java.security.MessageDigest
import java.util.concurrent.TimeUnit

class NHException(message: String) : Exception(message)

/** Shared HTTP clients. */
object Net {
    const val USER_AGENT = "AEros-NHT/2.1 (Android; +https://github.com/AtlanYuey/eros_n)"

    /** Extra interceptors (tests answer requests with sample data). */
    val interceptors = mutableListOf<okhttp3.Interceptor>()

    val client: OkHttpClient by lazy {
        OkHttpClient.Builder()
            .apply { interceptors.forEach { addInterceptor(it) } }
            .connectTimeout(20, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .addInterceptor { chain ->
                chain.proceed(chain.request().newBuilder().header("User-Agent", USER_AGENT).build())
            }
            .build()
    }

    val json = Json { ignoreUnknownKeys = true; isLenient = true; explicitNulls = false }
}

/**
 * nhentai REST API v2 (https://nhentai.net/api/v2/docs). Account actions
 * send the user's token (`Authorization: User <token>`).
 */
object NHClient {
    private val jsonType = "application/json".toMediaType()

    private suspend fun send(
        path: String,
        method: String = "GET",
        query: List<Pair<String, String>> = emptyList(),
        body: JsonObject? = null,
        retried: Boolean = false,
    ): JsonElement = withContext(Dispatchers.IO) {
        val url = "${NHHost.SITE}/api/v2/$path".toHttpUrl().newBuilder().apply {
            query.forEach { (k, v) -> addQueryParameter(k, v) }
        }.build()
        val request = Request.Builder().url(url).header("Accept", "application/json").apply {
            Auth.accessToken?.let { header("Authorization", "User $it") }
            val requestBody = body?.toString()?.toRequestBody(jsonType)
            when (method) {
                "GET" -> get()
                "DELETE" -> if (requestBody != null) delete(requestBody) else delete()
                else -> method(method, requestBody ?: "".toRequestBody(jsonType))
            }
        }.build()
        val (code, text) = try {
            Net.client.newCall(request).execute().use { it.code to (it.body.string()) }
        } catch (e: Exception) {
            throw NHException(e.localizedMessage ?: e.toString())
        }
        if (code == 401 && !retried && Auth.refreshToken != null && Auth.refresh()) {
            return@withContext send(path, method, query, body, retried = true)
        }
        if (code !in 200..299) {
            throw NHException(message(text) ?: L10n.string("Request failed (%lld)", code))
        }
        try {
            Net.json.parseToJsonElement(text)
        } catch (e: Exception) {
            throw NHException(L10n.string("Unexpected response from the server"))
        }
    }

    private fun message(text: String): String? = try {
        val o = Net.json.parseToJsonElement(text).obj()
        listOf("error", "detail", "message").firstNotNullOfOrNull { o?.str(it) }
    } catch (_: Exception) {
        null
    }

    private fun JsonElement.objOrThrow(): JsonObject =
        obj() ?: throw NHException(L10n.string("Unexpected response from the server"))

    // MARK: Galleries

    /** Latest galleries, or a search when a query or a non-date sort is given. */
    suspend fun galleries(query: String, sort: SearchSort, page: Int): PageResponse<GalleryItem> {
        val q = query.trim()
        val response = if (q.isEmpty() && sort == SearchSort.Recent) {
            send("galleries", query = listOf("page" to "$page"))
        } else {
            send(
                "search",
                query = listOf("query" to q.ifEmpty { "*" }, "sort" to sort.raw, "page" to "$page"),
            )
        }
        return PageResponse.parse(response.objOrThrow(), GalleryItem::parse)
    }

    suspend fun popular(): List<GalleryItem> =
        send("galleries/popular").arr()?.mapNotNull { it.obj()?.let(GalleryItem::parse) }
            ?.filter { !it.blacklisted } ?: emptyList()

    suspend fun gallery(id: Int): GalleryDetail = GalleryDetail.parse(galleryJson(id))

    /** A gallery as the API sends it (downloads keep it for offline use). */
    suspend fun galleryJson(id: Int): JsonObject {
        val include = if (Auth.isLoggedIn) "related,favorite" else "related"
        return send("galleries/$id", query = listOf("include" to include)).objOrThrow()
    }

    suspend fun comments(id: Int): List<GalleryComment> =
        PageResponse.parse(
            send("galleries/$id/comments", query = listOf("page" to "1", "per_page" to "50")).objOrThrow(),
            GalleryComment::parse,
        ).result

    // MARK: Account

    suspend fun favorites(page: Int): PageResponse<GalleryItem> {
        if (!Auth.isLoggedIn) throw NHException(L10n.string("Please log in first"))
        return PageResponse.parse(send("favorites", query = listOf("page" to "$page")).objOrThrow(), GalleryItem::parse)
    }

    suspend fun setFavorite(id: Int, favorite: Boolean): FavoriteResult {
        if (!Auth.isLoggedIn) throw NHException(L10n.string("Please log in first"))
        val o = send("galleries/$id/favorite", method = if (favorite) "POST" else "DELETE").obj()
        return FavoriteResult(o?.bool("favorited"), o?.int("num_favorites"))
    }

    suspend fun currentUser(): CurrentUser = CurrentUser.parse(send("user").objOrThrow())

    suspend fun postComment(id: Int, body: String): GalleryComment {
        if (!Auth.isLoggedIn) throw NHException(L10n.string("Please log in first"))
        val pow = send("pow", query = listOf("action" to "comment")).objOrThrow()
        val challenge = pow.str("challenge") ?: ""
        val difficulty = pow.int("difficulty") ?: 0
        val nonce = withContext(Dispatchers.Default) { ProofOfWork.solve(challenge, difficulty) }
        val payload = buildJsonObject {
            put("body", body)
            put("pow_challenge", challenge)
            put("pow_nonce", nonce)
        }
        return GalleryComment.parse(send("galleries/$id/comments", method = "POST", body = payload).objOrThrow())
    }

    // MARK: Tags

    suspend fun suggestTags(text: String): List<TagSuggestion> {
        val payload = buildJsonObject {
            put("query", text)
            put("limit", 12)
        }
        return send("tags/search", method = "POST", body = payload).arr()
            ?.mapNotNull { it.obj()?.let(TagSuggestion::parse) } ?: emptyList()
    }

    // MARK: Auth

    /** Exchanges a refresh token (no Authorization header). */
    suspend fun refreshTokens(refreshToken: String): Pair<String, String?> = withContext(Dispatchers.IO) {
        val payload = buildJsonObject { put("refresh_token", refreshToken) }
        val request = Request.Builder()
            .url("${NHHost.SITE}/api/v2/auth/refresh")
            .post(payload.toString().toRequestBody(jsonType))
            .build()
        val text = Net.client.newCall(request).execute().use {
            if (it.code != 200) throw NHException(L10n.string("Unexpected response from the server"))
            it.body.string()
        }
        val o = Net.json.parseToJsonElement(text).objOrThrow()
        val access = o.str("access_token") ?: throw NHException(L10n.string("Unexpected response from the server"))
        access to o.str("refresh_token")
    }
}

/** Stores the API tokens (app-private, not backed up) and refreshes them. */
object Auth {
    private lateinit var prefs: SharedPreferences
    private val mutex = Mutex()

    fun init(context: Context) {
        prefs = context.getSharedPreferences("auth", Context.MODE_PRIVATE)
    }

    val accessToken: String? get() = prefs.getString("api_v2_access_token", null)?.takeIf { it.isNotEmpty() }
    val refreshToken: String? get() = prefs.getString("api_v2_refresh_token", null)?.takeIf { it.isNotEmpty() }
    val isLoggedIn: Boolean get() = accessToken != null

    fun save(access: String, refresh: String?) {
        prefs.edit().apply {
            putString("api_v2_access_token", access)
            if (!refresh.isNullOrEmpty()) putString("api_v2_refresh_token", refresh)
        }.apply()
    }

    fun clear() {
        prefs.edit().clear().apply()
    }

    /** Refreshes the access token once, sharing concurrent requests. */
    suspend fun refresh(): Boolean {
        val before = accessToken
        return mutex.withLock {
            if (accessToken != before) return@withLock true
            val token = refreshToken ?: return@withLock false
            try {
                val (access, refresh) = NHClient.refreshTokens(token)
                save(access, refresh)
                true
            } catch (_: Exception) {
                false
            }
        }
    }
}

/** The signed-in user, observed by the UI. */
object Session {
    var user by mutableStateOf<CurrentUser?>(null)
        private set
    var isLoggedIn by mutableStateOf(false)
        private set

    suspend fun reload() {
        isLoggedIn = Auth.isLoggedIn
        if (!isLoggedIn) {
            user = null
            return
        }
        try {
            user = NHClient.currentUser()
        } catch (_: Exception) {
        }
    }

    suspend fun login(access: String, refresh: String?) {
        Auth.save(access, refresh)
        reload()
    }

    fun logout() {
        Auth.clear()
        user = null
        isLoggedIn = false
    }
}

/**
 * The API's proof of work for posting: a nonce such that
 * sha256(challenge + nonce) starts with `difficulty` zero bits.
 */
object ProofOfWork {
    fun solve(challenge: String, difficulty: Int): String {
        if (difficulty <= 0) return ""
        val fullBytes = difficulty / 8
        val remainingBits = difficulty % 8
        val mask = if (remainingBits == 0) 0 else (0xFF shl (8 - remainingBits)) and 0xFF
        val digest = MessageDigest.getInstance("SHA-256")
        var nonce = 0
        while (nonce < (1 shl 30)) {
            val hash = digest.digest("$challenge$nonce".toByteArray())
            var ok = true
            for (i in 0 until fullBytes) {
                if (hash[i].toInt() != 0) {
                    ok = false
                    break
                }
            }
            if (ok && (mask == 0 || (hash[fullBytes].toInt() and mask) == 0)) return "$nonce"
            nonce++
        }
        return ""
    }
}
