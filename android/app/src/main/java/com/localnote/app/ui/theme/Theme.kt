package com.localnote.app.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

/** 温暖手账风：只做浅色 */
private val JournalColorScheme = lightColorScheme(
    primary = AccentOrange,
    onPrimary = Color.White,
    secondary = TagBlue,
    onSecondary = Color.White,
    background = Cream,
    onBackground = InkBrown,
    surface = Cream,
    onSurface = InkBrown,
    surfaceVariant = Color.White,
    onSurfaceVariant = InkSoft,
    surfaceContainerHighest = Color.White,
    error = Color(0xFFD14343),
)

@Composable
fun LocalNoteTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = JournalColorScheme,
        content = content
    )
}
