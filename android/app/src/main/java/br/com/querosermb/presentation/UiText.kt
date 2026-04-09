package br.com.querosermb.presentation

import androidx.annotation.StringRes
import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource

sealed class UiText {
    data class StringRes(
        @androidx.annotation.StringRes val id: Int,
        val args: List<Any> = emptyList()
    ) : UiText()

    data class Dynamic(val value: String) : UiText()

    @Composable
    fun asString(): String = when (this) {
        is StringRes -> if (args.isEmpty()) stringResource(id) else stringResource(id, *args.toTypedArray())
        is Dynamic   -> value
    }
}
