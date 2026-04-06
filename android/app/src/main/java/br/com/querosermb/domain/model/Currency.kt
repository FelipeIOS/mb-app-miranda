package br.com.querosermb.domain.model

data class Currency(
    val id: Int,
    val name: String,
    val symbol: String,
    val priceUSD: Double?,
    val balance: Double?
)
