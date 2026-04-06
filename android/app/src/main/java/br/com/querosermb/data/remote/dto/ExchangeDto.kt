package br.com.querosermb.data.remote.dto

import br.com.querosermb.domain.model.Exchange
import com.google.gson.annotations.SerializedName

data class ExchangeMapResponse(
    val data: List<ExchangeMapItem>
)

data class ExchangeMapItem(
    val id: Int,
    val name: String,
    val slug: String
)

data class ExchangeInfoResponse(
    val data: Map<String, ExchangeInfoData>
)

data class ExchangeInfoData(
    val id: Int,
    val name: String,
    val slug: String,
    val logo: String,
    val description: String?,
    val urls: ExchangeUrls?,
    @SerializedName("maker_fee") val makerFee: Double?,
    @SerializedName("taker_fee") val takerFee: Double?,
    @SerializedName("date_launched") val dateLaunched: String?,
    @SerializedName("spot_volume_usd") val spotVolumeUsd: Double?
) {
    fun toDomain(): Exchange = Exchange(
        id = id,
        name = name,
        logo = logo,
        slug = slug,
        description = description,
        websiteURL = urls?.website?.firstOrNull(),
        makerFee = makerFee,
        takerFee = takerFee,
        dateLaunched = dateLaunched,
        spotVolumeUSD = spotVolumeUsd
    )
}

data class ExchangeUrls(
    val website: List<String>?
)
