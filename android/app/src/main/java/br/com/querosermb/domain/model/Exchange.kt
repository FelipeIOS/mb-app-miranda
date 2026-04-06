package br.com.querosermb.domain.model

data class Exchange(
    val id: Int,
    val name: String,
    val logo: String,
    val slug: String,
    val description: String?,
    val websiteURL: String?,
    val makerFee: Double?,
    val takerFee: Double?,
    val dateLaunched: String?,
    val spotVolumeUSD: Double?
)
