package br.com.querosermb

import br.com.querosermb.domain.model.Currency
import br.com.querosermb.domain.model.Exchange
import br.com.querosermb.domain.model.ExchangeListPage
import br.com.querosermb.domain.repository.ExchangeRepository

class FakeExchangeRepository : ExchangeRepository {

    val alphaExchange = Exchange(
        id = 1,
        name = "Alpha Exchange",
        logo = "https://example.com/alpha.png",
        slug = "alpha",
        description = "Alpha is a leading exchange.",
        websiteURL = "https://alpha.com",
        makerFee = 0.1,
        takerFee = 0.2,
        dateLaunched = "2018-05-01T00:00:00.000Z",
        spotVolumeUSD = 9_000_000_000.0
    )

    val betaExchange = Exchange(
        id = 2,
        name = "Beta Exchange",
        logo = "https://example.com/beta.png",
        slug = "beta",
        description = "Beta exchange description.",
        websiteURL = "https://beta.com",
        makerFee = 0.05,
        takerFee = 0.1,
        dateLaunched = "2020-01-01T00:00:00.000Z",
        spotVolumeUSD = 1_000_000_000.0
    )

    val bitcoin = Currency(id = 1, name = "Bitcoin", symbol = "BTC", priceUSD = 65_000.0, balance = 100.0)

    override suspend fun getExchangeList(start: Int, limit: Int): ExchangeListPage {
        return ExchangeListPage(
            items = listOf(alphaExchange, betaExchange),
            hasMore = false,
            nextStart = 3
        )
    }

    override suspend fun getExchangeDetail(id: Int): Exchange {
        return if (id == 1) alphaExchange else betaExchange
    }

    override suspend fun getExchangeAssets(id: Int): List<Currency> {
        return listOf(bitcoin)
    }
}
