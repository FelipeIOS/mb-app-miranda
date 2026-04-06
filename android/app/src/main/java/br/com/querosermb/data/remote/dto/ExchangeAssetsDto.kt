package br.com.querosermb.data.remote.dto

import br.com.querosermb.domain.model.Currency
import com.google.gson.annotations.SerializedName

data class ExchangeAssetsResponse(
    val data: List<ExchangeAssetItem>
)

data class ExchangeAssetItem(
    val currency: AssetCurrencyData,
    val balance: Double?,
    @SerializedName("wallet_address") val walletAddress: String?
) {
    fun toDomain(): Currency = Currency(
        id = currency.id,
        name = currency.name,
        symbol = currency.symbol,
        priceUSD = currency.priceUsd,
        balance = balance
    )
}

data class AssetCurrencyData(
    @SerializedName("crypto_id") val id: Int,
    val name: String,
    val symbol: String,
    @SerializedName("price_usd") val priceUsd: Double?
)
