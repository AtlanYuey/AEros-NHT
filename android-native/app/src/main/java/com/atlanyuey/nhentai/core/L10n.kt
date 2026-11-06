package com.atlanyuey.nhentai.core

import android.app.LocaleManager
import android.content.Context
import android.content.res.Configuration
import android.os.Build
import android.os.LocaleList
import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import java.util.Locale

/**
 * Strings use the same keys as the iOS app (English text, `%lld` / `%@`
 * placeholders); [L10nKeys] maps each key to its Android string resource.
 */
object L10n {
    lateinit var context: Context

    fun string(key: String, vararg args: Any): String {
        val id = L10nKeys.ids[key]
        return if (id != null) context.getString(id, *args) else fallback(key, args)
    }

    internal fun fallback(key: String, args: Array<out Any>): String {
        if (args.isEmpty()) return key
        val format = key.replace(Regex("%(\\d\\$)?lld"), "%$1d").replace(Regex("%(\\d\\$)?@"), "%$1s")
        return runCatching { String.format(format, *args) }.getOrDefault(key)
    }
}

/** A translated string for an iOS-style key. */
@Composable
fun tr(key: String, vararg args: Any): String {
    val id = L10nKeys.ids[key]
    return if (id != null) stringResource(id, *args) else L10n.fallback(key, args)
}

/**
 * The app's own language: the system language, or one picked in the app.
 * Android 13+ keeps it as the per-app language (also in system Settings);
 * older versions apply it to the app's resources.
 */
object AppLanguage {
    data class Option(val code: String, val name: String)

    /** Languages the app is translated into (nhentai's own first). */
    val all = listOf(
        Option("en", "English"),
        Option("ja", "日本語"),
        Option("zh-Hans", "简体中文"),
        Option("zh-Hant", "繁體中文"),
        Option("ko", "한국어"),
        Option("es", "Español"),
        Option("fr", "Français"),
        Option("de", "Deutsch"),
        Option("it", "Italiano"),
        Option("pt-BR", "Português (Brasil)"),
        Option("ru", "Русский"),
        Option("vi", "Tiếng Việt"),
        Option("th", "ไทย"),
        Option("id", "Bahasa Indonesia"),
    )

    private const val PREF = "appLanguage"

    /** The language picked for this app, or "" when it follows the system. */
    fun selected(context: Context): String {
        if (Build.VERSION.SDK_INT >= 33) {
            val locales = context.getSystemService(LocaleManager::class.java).applicationLocales
            if (locales.isEmpty) return ""
            return match(locales[0].toLanguageTag())?.code ?: ""
        }
        return context.getSharedPreferences("settings", Context.MODE_PRIVATE).getString(PREF, "") ?: ""
    }

    fun select(context: Context, code: String) {
        if (Build.VERSION.SDK_INT >= 33) {
            context.getSystemService(LocaleManager::class.java).applicationLocales =
                if (code.isEmpty()) LocaleList.getEmptyLocaleList() else LocaleList.forLanguageTags(code)
        } else {
            context.getSharedPreferences("settings", Context.MODE_PRIVATE).edit().putString(PREF, code).apply()
        }
    }

    /** The device's own language (ignoring this app's choice). */
    fun systemLocale(): Locale = android.content.res.Resources.getSystem().configuration.locales[0]

    /** Wraps [base] with the picked language on Android 12 and older. */
    fun wrap(base: Context): Context {
        if (Build.VERSION.SDK_INT >= 33) return base
        val code = base.getSharedPreferences("settings", Context.MODE_PRIVATE).getString(PREF, "") ?: ""
        if (code.isEmpty()) return base
        val locale = Locale.forLanguageTag(code)
        Locale.setDefault(locale)
        val config = Configuration(base.resources.configuration)
        config.setLocales(LocaleList(locale))
        return base.createConfigurationContext(config)
    }

    private fun match(tag: String): Option? {
        val locale = Locale.forLanguageTag(tag)
        if (locale.language == "zh") {
            val traditional = locale.script == "Hant" ||
                (locale.script.isEmpty() && locale.country in setOf("TW", "HK", "MO"))
            return all.first { it.code == if (traditional) "zh-Hant" else "zh-Hans" }
        }
        if (locale.language == "pt") return all.first { it.code == "pt-BR" }
        val language = if (locale.language == "in") "id" else locale.language
        return all.firstOrNull { it.code == language }
    }
}
