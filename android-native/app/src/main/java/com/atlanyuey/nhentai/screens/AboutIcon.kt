package com.atlanyuey.nhentai.screens

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.zIndex
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.ColorMatrix
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.atlanyuey.nhentai.R
import com.atlanyuey.nhentai.ui.components.Txt
import com.atlanyuey.nhentai.ui.theme.AppTheme
import com.atlanyuey.nhentai.ui.theme.Type
import com.kyant.shapes.Capsule
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.math.cos
import kotlin.math.sin
import kotlin.random.Random

private val faces = listOf(
    "(≧▽≦)", "(｡•̀ᴗ-)✧", "ヾ(＾∇＾)", "(〃▽〃)", "ฅ^•ﻌ•^ฅ",
    "(*/ω＼*)", "( ˘ ³˘)♥", "(ノ´ヮ`)ノ*: ･ﾟ", "(=^･ω･^=)", "(*≧ω≦)",
)

/**
 * The app icon on the About page, with a small easter egg: long press it
 * and it spins, hearts and sparkles burst out of it and it pulls a face.
 * Every fifth time it turns rainbow.
 */
@Composable
fun AboutIcon() {
    val scope = rememberCoroutineScope()
    val haptics = LocalHapticFeedback.current
    val spin = remember { Animatable(0f) }
    val hue = remember { Animatable(0f) }
    var pressing by remember { mutableStateOf(false) }
    val scale by animateFloatAsState(if (pressing) 0.88f else 1f, spring(dampingRatio = 0.45f, stiffness = 500f), label = "press")
    val bursts = remember { mutableStateListOf<Burst>() }
    var bubble by remember { mutableStateOf<Bubble?>(null) }
    var count by remember { mutableIntStateOf(0) }

    fun celebrate() {
        count++
        haptics.performHapticFeedback(HapticFeedbackType.LongPress)
        val rainbow = count % 5 == 0
        scope.launch { spin.animateTo(spin.value + 360f, spring(dampingRatio = 0.55f, stiffness = 110f)) }
        if (rainbow) {
            scope.launch {
                hue.animateTo(720f, tween(2400, easing = LinearEasing))
                hue.snapTo(0f)
            }
        }
        val burst = Burst(rainbow)
        bursts.add(burst)
        val shown = Bubble(if (rainbow) "🌈 (ﾉ◕ヮ◕)ﾉ*:･ﾟ✧" else faces.random())
        bubble = shown
        scope.launch {
            delay(if (rainbow) 2400 else 1600)
            if (bubble?.id == shown.id) bubble = null
            bursts.remove(burst)
        }
    }

    // Above the texts below it, so the hearts fly over them.
    Box(Modifier.size(88.dp).zIndex(1f), contentAlignment = Alignment.Center) {
        val degrees = hue.value
        Image(
            painter = painterResource(R.drawable.about_icon),
            contentDescription = "AEros-NHT",
            colorFilter = if (degrees != 0f) ColorFilter.colorMatrix(hueMatrix(degrees)) else null,
            modifier = Modifier
                .size(88.dp)
                .graphicsLayer {
                    rotationY = spin.value
                    scaleX = scale
                    scaleY = scale
                    cameraDistance = 14f * density
                }
                .clip(RoundedCornerShape(20.dp))
                .pointerInput(Unit) {
                    detectTapGestures(
                        onPress = {
                            pressing = true
                            tryAwaitRelease()
                            pressing = false
                        },
                        onLongPress = { celebrate() },
                    )
                },
        )
        bursts.forEach { burst -> key(burst.id) { BurstView(burst) } }
        bubble?.let { shown -> key(shown.id) { BubbleView(shown.text, Modifier.offset(y = (-64).dp)) } }
    }
}

private class Bubble(val text: String) {
    val id = Random.nextLong()
}

private class Burst(rainbow: Boolean) {
    class Particle(val emoji: String, val angle: Float, val distance: Float, val size: Float, val spin: Float)

    val id = Random.nextLong()
    val particles: List<Particle>

    init {
        val emoji = if (rainbow) listOf("🌈", "🦄", "💜", "💙", "💚", "💛", "🧡", "❤️") else listOf("💗", "✨", "🌸", "💫", "⭐", "💖")
        val count = if (rainbow) 22 else 16
        particles = List(count) { index ->
            Particle(
                emoji = emoji.random(),
                angle = (index.toFloat() / count * 2f * Math.PI.toFloat()) + Random.nextFloat() * 0.5f - 0.25f,
                distance = 70f + Random.nextFloat() * 80f,
                size = 14f + Random.nextFloat() * 10f,
                spin = Random.nextFloat() * 400f - 200f,
            )
        }
    }
}

@Composable
private fun BurstView(burst: Burst) {
    val progress = remember { Animatable(0f) }
    LaunchedEffect(Unit) { progress.animateTo(1f, tween(1050, easing = FastOutSlowInEasing)) }
    burst.particles.forEach { particle ->
        Txt(
            particle.emoji,
            Modifier.graphicsLayer {
                val t = progress.value
                translationX = cos(particle.angle) * particle.distance.dp.toPx() * t
                translationY = sin(particle.angle) * particle.distance.dp.toPx() * t
                rotationZ = particle.spin * t
                val s = 0.2f + 0.8f * t
                scaleX = s
                scaleY = s
                alpha = if (t < 0.55f) 1f else (1f - (t - 0.55f) / 0.45f).coerceAtLeast(0f)
            },
            style = TextStyle(fontSize = particle.size.sp),
        )
    }
}

@Composable
private fun BubbleView(text: String, modifier: Modifier) {
    val appear = remember { Animatable(0.3f) }
    LaunchedEffect(Unit) { appear.animateTo(1f, spring(dampingRatio = 0.5f, stiffness = 400f)) }
    Txt(
        text,
        modifier
            .graphicsLayer {
                scaleX = appear.value
                scaleY = appear.value
                alpha = ((appear.value - 0.3f) / 0.7f).coerceIn(0f, 1f)
            }
            .clip(Capsule())
            .background(AppTheme.colors.secondaryGroupedBackground)
            .padding(horizontal = 12.dp, vertical = 6.dp),
        style = Type.subheadline.copy(fontWeight = FontWeight.SemiBold),
        maxLines = 1,
    )
}

/** Rotates the hue of an image by [degrees] (like CSS hue-rotate). */
private fun hueMatrix(degrees: Float): ColorMatrix {
    val radians = Math.toRadians(degrees.toDouble())
    val c = cos(radians).toFloat()
    val s = sin(radians).toFloat()
    val lr = 0.213f
    val lg = 0.715f
    val lb = 0.072f
    return ColorMatrix(
        floatArrayOf(
            lr + c * (1 - lr) - s * lr, lg - c * lg - s * lg, lb - c * lb + s * (1 - lb), 0f, 0f,
            lr - c * lr + s * 0.143f, lg + c * (1 - lg) + s * 0.140f, lb - c * lb - s * 0.283f, 0f, 0f,
            lr - c * lr - s * (1 - lr), lg - c * lg + s * lg, lb + c * (1 - lb) + s * lb, 0f, 0f,
            0f, 0f, 0f, 1f, 0f,
        ),
    )
}
