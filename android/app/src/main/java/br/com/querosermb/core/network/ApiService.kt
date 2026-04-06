package br.com.querosermb.core.network

import br.com.querosermb.data.remote.dto.ExchangeAssetsResponse
import br.com.querosermb.data.remote.dto.ExchangeInfoResponse
import br.com.querosermb.data.remote.dto.ExchangeMapResponse
import retrofit2.http.GET
import retrofit2.http.Query

interface ApiService {
    @GET("/v1/exchange/map")
    suspend fun getExchangeMap(
        @Query("start") start: Int,
        @Query("limit") limit: Int
    ): ExchangeMapResponse

    @GET("/v1/exchange/info")
    suspend fun getExchangeInfo(
        @Query("id") ids: String
    ): ExchangeInfoResponse

    @GET("/v1/exchange/assets")
    suspend fun getExchangeAssets(
        @Query("id") id: Int
    ): ExchangeAssetsResponse
}
