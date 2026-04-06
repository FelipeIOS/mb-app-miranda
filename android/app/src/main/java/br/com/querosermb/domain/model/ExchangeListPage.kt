package br.com.querosermb.domain.model

data class ExchangeListPage(
    val items: List<Exchange>,
    val hasMore: Boolean,
    val nextStart: Int
)
