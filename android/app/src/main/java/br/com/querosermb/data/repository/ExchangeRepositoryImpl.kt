package br.com.querosermb.data.repository

import br.com.querosermb.data.remote.datasource.ExchangeRemoteDataSourcing
import br.com.querosermb.domain.model.Currency
import br.com.querosermb.domain.model.Exchange
import br.com.querosermb.domain.model.ExchangeListPage
import br.com.querosermb.domain.repository.ExchangeRepository
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import javax.inject.Inject

class ExchangeRepositoryImpl @Inject constructor(
    private val dataSource: ExchangeRemoteDataSourcing
) : ExchangeRepository {

    companion object {
        private const val MAX_IDS_PER_INFO_REQUEST = 100
    }

    override suspend fun getExchangeList(start: Int, limit: Int): ExchangeListPage {
        val mapItems = dataSource.fetchExchangeMap(start, limit)
        if (mapItems.isEmpty()) {
            return ExchangeListPage(items = emptyList(), hasMore = false, nextStart = start)
        }

        val chunks = mapItems.map { it.id }.chunked(MAX_IDS_PER_INFO_REQUEST)
        val allInfo = coroutineScope {
            chunks.map { chunk ->
                async { dataSource.fetchExchangeInfo(chunk.joinToString(",")) }
            }.awaitAll().flatten()
        }

        val infoById = allInfo.associateBy { it.id }

        val exchanges = mapItems.mapNotNull { mapItem ->
            infoById[mapItem.id]?.toDomain()
        }.sortedByDescending { it.spotVolumeUSD ?: -1.0 }

        val hasMore = mapItems.size == limit
        val nextStart = start + mapItems.size

        return ExchangeListPage(items = exchanges, hasMore = hasMore, nextStart = nextStart)
    }

    override suspend fun getExchangeDetail(id: Int): Exchange {
        val infoList = dataSource.fetchExchangeInfo(id.toString())
        return infoList.firstOrNull()?.toDomain()
            ?: throw br.com.querosermb.core.network.NetworkError.InvalidResponse
    }

    override suspend fun getExchangeAssets(id: Int): List<Currency> {
        return dataSource.fetchExchangeAssets(id).map { it.toDomain() }
    }
}
