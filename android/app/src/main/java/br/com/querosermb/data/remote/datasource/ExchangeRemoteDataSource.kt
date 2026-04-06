package br.com.querosermb.data.remote.datasource

import br.com.querosermb.core.network.ApiService
import br.com.querosermb.data.remote.dto.ExchangeAssetItem
import br.com.querosermb.data.remote.dto.ExchangeInfoData
import br.com.querosermb.data.remote.dto.ExchangeMapItem
import javax.inject.Inject

interface ExchangeRemoteDataSourcing {
    suspend fun fetchExchangeMap(start: Int, limit: Int): List<ExchangeMapItem>
    suspend fun fetchExchangeInfo(ids: String): List<ExchangeInfoData>
    suspend fun fetchExchangeAssets(id: Int): List<ExchangeAssetItem>
}

class ExchangeRemoteDataSource @Inject constructor(
    private val apiService: ApiService
) : ExchangeRemoteDataSourcing {

    override suspend fun fetchExchangeMap(start: Int, limit: Int): List<ExchangeMapItem> {
        return apiService.getExchangeMap(start, limit).data
    }

    override suspend fun fetchExchangeInfo(ids: String): List<ExchangeInfoData> {
        return apiService.getExchangeInfo(ids).data.values.toList()
    }

    override suspend fun fetchExchangeAssets(id: Int): List<ExchangeAssetItem> {
        return apiService.getExchangeAssets(id).data
    }
}
