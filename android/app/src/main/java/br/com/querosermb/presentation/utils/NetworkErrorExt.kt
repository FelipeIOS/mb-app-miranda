package br.com.querosermb.presentation.utils

import br.com.querosermb.R
import br.com.querosermb.core.network.NetworkError
import br.com.querosermb.presentation.UiText

fun NetworkError.toUiText(): UiText = when (this) {
    NetworkError.InvalidURL        -> UiText.StringRes(R.string.network_invalid_url)
    NetworkError.InvalidResponse   -> UiText.StringRes(R.string.network_invalid_response)
    is NetworkError.ServerError    -> UiText.StringRes(R.string.network_server_error, listOf(statusCode))
    is NetworkError.DecodingError  -> UiText.StringRes(R.string.network_decoding)
    NetworkError.NoConnection      -> UiText.StringRes(R.string.network_no_connection)
    is NetworkError.Unknown        -> UiText.StringRes(R.string.network_unknown)
}

fun Throwable.toUiText(): UiText =
    (this as? NetworkError)?.toUiText() ?: UiText.StringRes(R.string.network_unknown)
