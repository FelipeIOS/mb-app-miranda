package br.com.querosermb.core.network

sealed class NetworkError : Exception() {
    object InvalidURL : NetworkError()
    object InvalidResponse : NetworkError()
    data class ServerError(val statusCode: Int) : NetworkError()
    data class DecodingError(override val cause: Throwable) : NetworkError()
    object NoConnection : NetworkError()
    data class Unknown(override val cause: Throwable) : NetworkError()

    fun userMessage(): String = when (this) {
        is InvalidURL -> "URL inválida"
        is InvalidResponse -> "Resposta inválida do servidor"
        is ServerError -> "Erro no servidor (código $statusCode)"
        is DecodingError -> "Erro ao processar os dados"
        is NoConnection -> "Sem conexão com a internet"
        is Unknown -> cause.message ?: "Erro desconhecido"
    }
}
