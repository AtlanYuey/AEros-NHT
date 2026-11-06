package com.atlanyuey.nhentai

import android.content.Context
import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.mutableStateOf
import com.atlanyuey.nhentai.core.AppLanguage
import com.atlanyuey.nhentai.core.Session
import com.atlanyuey.nhentai.core.TagStore
import com.atlanyuey.nhentai.ui.RootView
import com.atlanyuey.nhentai.ui.theme.AppTheme

class MainActivity : ComponentActivity() {
    /** A gallery id from an opened nhentai link. */
    val linkedGallery = mutableStateOf<Int?>(null)

    override fun attachBaseContext(newBase: Context) {
        super.attachBaseContext(AppLanguage.wrap(newBase))
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge(
            statusBarStyle = SystemBarStyle.auto(android.graphics.Color.TRANSPARENT, android.graphics.Color.TRANSPARENT),
            navigationBarStyle = SystemBarStyle.auto(android.graphics.Color.TRANSPARENT, android.graphics.Color.TRANSPARENT),
        )
        super.onCreate(savedInstanceState)
        window.isNavigationBarContrastEnforced = false
        handle(intent)
        setContent {
            AppTheme {
                LaunchedEffect(Unit) { Session.reload() }
                LaunchedEffect(Unit) { TagStore.prepare() }
                RootView(linkedGallery)
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handle(intent)
    }

    private fun handle(intent: Intent?) {
        val path = intent?.data?.path ?: return
        Regex("/g/(\\d+)").find(path)?.groupValues?.get(1)?.toIntOrNull()?.let { linkedGallery.value = it }
    }
}
