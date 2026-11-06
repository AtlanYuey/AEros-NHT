package com.atlanyuey.nhentai.ui.components

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.text.BasicText
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.isSpecified
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.atlanyuey.nhentai.ui.theme.AppTheme
import com.atlanyuey.nhentai.ui.theme.Type

/** An icon tinted with [tint] (label color by default). */
@Composable
fun AppIcon(
    icon: ImageVector,
    contentDescription: String?,
    modifier: Modifier = Modifier,
    tint: Color = Color.Unspecified,
    size: Dp = 22.dp,
) {
    val color = if (tint.isSpecified) tint else AppTheme.colors.label
    Image(
        imageVector = icon,
        contentDescription = contentDescription,
        modifier = modifier.size(size),
        colorFilter = ColorFilter.tint(color),
    )
}

/** Text in an iOS text style (label color by default). */
@Composable
fun Txt(
    text: String,
    modifier: Modifier = Modifier,
    style: TextStyle = Type.body,
    color: Color = Color.Unspecified,
    maxLines: Int = Int.MAX_VALUE,
    align: TextAlign? = null,
    overflow: TextOverflow = TextOverflow.Ellipsis,
) {
    val resolved = if (color.isSpecified) color else AppTheme.colors.label
    BasicText(
        text = text,
        modifier = modifier,
        style = style.copy(color = resolved, textAlign = align ?: TextAlign.Unspecified),
        maxLines = maxLines,
        overflow = overflow,
    )
}
