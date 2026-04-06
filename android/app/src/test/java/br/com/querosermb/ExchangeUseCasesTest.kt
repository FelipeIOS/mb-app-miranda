package br.com.querosermb

import br.com.querosermb.core.network.NetworkError
import br.com.querosermb.domain.model.Currency
import br.com.querosermb.domain.model.Exchange
import br.com.querosermb.domain.model.ExchangeListPage
import br.com.querosermb.domain.repository.ExchangeRepository
import br.com.querosermb.domain.usecase.GetExchangeAssetsUseCase
import br.com.querosermb.domain.usecase.GetExchangeDetailUseCase
import br.com.querosermb.domain.usecase.GetExchangeListUseCase
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class GetExchangeListUseCaseTest {
    private val repo = mockk<ExchangeRepository>()
    private val useCase = GetExchangeListUseCase(repo)

    @Test
    fun `execute returns page on success`() = runTest {
        val page = ExchangeListPage(items = listOf(sampleExchange(1)), hasMore = false, nextStart = 2)
        coEvery { repo.getExchangeList(1, 40) } returns page

        val result = useCase.execute()

        assertEquals(1, result.items.size)
        assertEquals("E1", result.items[0].name)
        coVerify(exactly = 1) { repo.getExchangeList(1, 40) }
    }

    @Test
    fun `execute returns empty page`() = runTest {
        coEvery { repo.getExchangeList(any(), any()) } returns ExchangeListPage(emptyList(), false, 1)
        val result = useCase.execute()
        assertTrue(result.items.isEmpty())
    }

    @Test(expected = NetworkError.NoConnection::class)
    fun `execute propagates error`() = runTest {
        coEvery { repo.getExchangeList(any(), any()) } throws NetworkError.NoConnection
        useCase.execute()
    }
}

class GetExchangeDetailUseCaseTest {
    private val repo = mockk<ExchangeRepository>()
    private val useCase = GetExchangeDetailUseCase(repo)

    @Test
    fun `execute returns exchange on success`() = runTest {
        val exchange = sampleExchange(7)
        coEvery { repo.getExchangeDetail(7) } returns exchange

        val result = useCase.execute(7)

        assertEquals(7, result.id)
        assertEquals("E7", result.name)
    }

    @Test(expected = NetworkError.InvalidResponse::class)
    fun `execute propagates invalid response`() = runTest {
        coEvery { repo.getExchangeDetail(any()) } throws NetworkError.InvalidResponse
        useCase.execute(99)
    }
}

class GetExchangeAssetsUseCaseTest {
    private val repo = mockk<ExchangeRepository>()
    private val useCase = GetExchangeAssetsUseCase(repo)

    @Test
    fun `execute returns currencies on success`() = runTest {
        val currencies = listOf(Currency(1, "Bitcoin", "BTC", 50_000.0, null))
        coEvery { repo.getExchangeAssets(1) } returns currencies

        val result = useCase.execute(1)

        assertEquals(1, result.size)
        assertEquals("BTC", result[0].symbol)
    }

    @Test
    fun `execute returns empty list`() = runTest {
        coEvery { repo.getExchangeAssets(any()) } returns emptyList()
        val result = useCase.execute(1)
        assertTrue(result.isEmpty())
    }
}

internal fun sampleExchange(id: Int) = Exchange(
    id = id,
    name = "E$id",
    logo = "https://logo/$id",
    slug = "e$id",
    description = null,
    websiteURL = null,
    makerFee = null,
    takerFee = null,
    dateLaunched = null,
    spotVolumeUSD = id.toDouble() * 1_000_000
)
