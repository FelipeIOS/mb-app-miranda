package br.com.querosermb.domain.usecase

import br.com.querosermb.domain.model.Currency
import br.com.querosermb.domain.model.Exchange
import br.com.querosermb.domain.model.ExchangeListPage
import br.com.querosermb.domain.repository.ExchangeRepository
import javax.inject.Inject

class GetExchangeListUseCase @Inject constructor(
    private val repository: ExchangeRepository
) {
    companion object {
        const val DEFAULT_PAGE_SIZE = 40
    }

    suspend fun execute(start: Int = 1, limit: Int = DEFAULT_PAGE_SIZE): ExchangeListPage {
        return repository.getExchangeList(start, limit)
    }
}

class GetExchangeDetailUseCase @Inject constructor(
    private val repository: ExchangeRepository
) {
    suspend fun execute(id: Int): Exchange {
        return repository.getExchangeDetail(id)
    }
}

class GetExchangeAssetsUseCase @Inject constructor(
    private val repository: ExchangeRepository
) {
    suspend fun execute(id: Int): List<Currency> {
        return repository.getExchangeAssets(id)
    }
}
