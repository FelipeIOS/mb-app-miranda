package br.com.querosermb.presentation.utils

import android.content.Context
import br.com.querosermb.R
import br.com.querosermb.core.network.NetworkError

fun NetworkError.toUserMessage(context: Context): String = when (this) {
    NetworkError.InvalidURL -> context.getString(R.string.network_invalid_url)
    NetworkError.InvalidResponse -> context.getString(R.string.network_invalid_response)
    is NetworkError.ServerError -> context.getString(R.string.network_server_error, statusCode)
    is NetworkError.DecodingError -> context.getString(R.string.network_decoding)
    NetworkError.NoConnection -> context.getString(R.string.network_no_connection)
    is NetworkError.Unknown -> context.getString(R.string.network_unknown)
}

fun Throwable.toUserMessage(context: Context): String =
    (this as? NetworkError)?.toUserMessage(context) ?: context.getString(R.string.network_unknown)
