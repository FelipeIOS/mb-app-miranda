package br.com.querosermb.domain.repository

import br.com.querosermb.domain.model.Currency
import br.com.querosermb.domain.model.Exchange
import br.com.querosermb.domain.model.ExchangeListPage

interface ExchangeRepository {
    suspend fun getExchangeList(start: Int, limit: Int): ExchangeListPage
    suspend fun getExchangeDetail(id: Int): Exchange
    suspend fun getExchangeAssets(id: Int): List<Currency>
}
