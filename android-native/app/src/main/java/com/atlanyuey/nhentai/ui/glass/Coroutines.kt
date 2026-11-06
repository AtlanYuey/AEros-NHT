// Adapted from Kyant0/AndroidLiquidGlass (Backdrop catalog), Apache License 2.0,
// Copyright Kyant. https://github.com/Kyant0/AndroidLiquidGlass
package com.atlanyuey.nhentai.ui.glass

import androidx.compose.runtime.withFrameNanos

suspend fun awaitFrame() {
    withFrameNanos { }
}
