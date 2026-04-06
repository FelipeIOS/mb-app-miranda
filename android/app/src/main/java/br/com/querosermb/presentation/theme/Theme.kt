package br.com.querosermb.presentation.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable

private val DarkColorScheme = darkColorScheme(
    primary = MbGold,
    onPrimary = MbPrimary,
    secondary = MbAccent,
    onSecondary = MbText,
    background = MbPrimary,
    onBackground = MbText,
    surface = MbSurface,
    onSurface = MbText,
    surfaceVariant = MbSurfaceAlt,
    onSurfaceVariant = MbTextSub,
    error = MbError,
    onError = MbText
)

@Composable
fun QuerosermBTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = DarkColorScheme,
        typography = MbTypography,
        content = content
    )
}
