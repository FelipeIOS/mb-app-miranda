package br.com.querosermb.data.remote.datasource

import br.com.querosermb.core.network.ApiService
import br.com.querosermb.core.network.NetworkError
import br.com.querosermb.data.remote.dto.ExchangeAssetItem
import br.com.querosermb.data.remote.dto.ExchangeInfoData
import br.com.querosermb.data.remote.dto.ExchangeMapItem
import com.google.gson.JsonParseException
import retrofit2.HttpException
import java.io.IOException
import javax.inject.Inject

interface ExchangeRemoteDataSourcing {
    suspend fun fetchExchangeMap(start: Int, limit: Int): List<ExchangeMapItem>
    suspend fun fetchExchangeInfo(ids: String): List<ExchangeInfoData>
    suspend fun fetchExchangeAssets(id: Int): List<ExchangeAssetItem>
}

class ExchangeRemoteDataSource @Inject constructor(
    private val apiService: ApiService
) : ExchangeRemoteDataSourcing {

    override suspend fun fetchExchangeMap(start: Int, limit: Int): List<ExchangeMapItem> =
        safeCall { apiService.getExchangeMap(start, limit).data }

    override suspend fun fetchExchangeInfo(ids: String): List<ExchangeInfoData> =
        safeCall { apiService.getExchangeInfo(ids).data.values.toList() }

    override suspend fun fetchExchangeAssets(id: Int): List<ExchangeAssetItem> =
        safeCall { apiService.getExchangeAssets(id).data }

    private suspend fun <T> safeCall(block: suspend () -> T): T {
        return try {
            block()
        } catch (e: HttpException) {
            throw NetworkError.ServerError(e.code())
        } catch (e: JsonParseException) {
            throw NetworkError.DecodingError(e)
        } catch (e: IOException) {
            throw NetworkError.NoConnection
        }
    }
}
