package br.com.querosermb.core.network

sealed class NetworkError : Exception() {
    object InvalidURL : NetworkError()
    object InvalidResponse : NetworkError()
    data class ServerError(val statusCode: Int) : NetworkError()
    data class DecodingError(override val cause: Throwable) : NetworkError()
    object NoConnection : NetworkError()
    data class Unknown(override val cause: Throwable) : NetworkError()
}
