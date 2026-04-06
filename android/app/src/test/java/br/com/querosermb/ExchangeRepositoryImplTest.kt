package br.com.querosermb

import br.com.querosermb.core.network.NetworkError
import br.com.querosermb.data.remote.datasource.ExchangeRemoteDataSourcing
import br.com.querosermb.data.remote.dto.AssetCurrencyData
import br.com.querosermb.data.remote.dto.ExchangeAssetItem
import br.com.querosermb.data.remote.dto.ExchangeInfoData
import br.com.querosermb.data.remote.dto.ExchangeMapItem
import br.com.querosermb.data.repository.ExchangeRepositoryImpl
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import io.mockk.slot
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ExchangeRepositoryImplTest {

    private val dataSource = mockk<ExchangeRemoteDataSourcing>()
    private val repo = ExchangeRepositoryImpl(dataSource)

    @Test
    fun `getExchangeList returns empty page when map is empty`() = runTest {
        coEvery { dataSource.fetchExchangeMap(5, 40) } returns emptyList()

        val page = repo.getExchangeList(5, 40)

        assertTrue(page.items.isEmpty())
        assertFalse(page.hasMore)
        assertEquals(5, page.nextStart)
    }

    @Test
    fun `getExchangeList merges map and info`() = runTest {
        coEvery { dataSource.fetchExchangeMap(1, 40) } returns listOf(
            ExchangeMapItem(1, "A", "a"),
            ExchangeMapItem(2, "B", "b")
        )
        coEvery { dataSource.fetchExchangeInfo(any()) } returns listOf(
            infoData(1), infoData(2)
        )

        val page = repo.getExchangeList(1, 40)

        assertEquals(2, page.items.size)
        assertFalse(page.hasMore)
        assertEquals(3, page.nextStart)
    }

    @Test
    fun `getExchangeList hasMore true when page is full`() = runTest {
        coEvery { dataSource.fetchExchangeMap(1, 10) } returns
            (1..10).map { ExchangeMapItem(it, "E$it", "e$it") }
        coEvery { dataSource.fetchExchangeInfo(any()) } returns
            (1..10).map { infoData(it) }

        val page = repo.getExchangeList(1, 10)

        assertTrue(page.hasMore)
        assertEquals(10, page.items.size)
    }

    @Test
    fun `getExchangeList batches info when more than 100 map items`() = runTest {
        val mapItems = (1..101).map { ExchangeMapItem(it, "E$it", "e$it") }
        coEvery { dataSource.fetchExchangeMap(1, 200) } returns mapItems
        val idsSlot = slot<String>()
        coEvery { dataSource.fetchExchangeInfo(capture(idsSlot)) } answers {
            idsSlot.captured.split(",").mapNotNull { it.trim().toIntOrNull() }.map { infoData(it) }
        }

        repo.getExchangeList(1, 200)

        coVerify(exactly = 2) { dataSource.fetchExchangeInfo(any()) }
    }

    @Test
    fun `getExchangeDetail throws InvalidResponse when info empty`() = runTest {
        coEvery { dataSource.fetchExchangeInfo("99") } returns emptyList()

        try {
            repo.getExchangeDetail(99)
            error("Expected NetworkError.InvalidResponse")
        } catch (e: NetworkError.InvalidResponse) {
            // pass
        }
    }

    @Test
    fun `getExchangeDetail returns domain model`() = runTest {
        coEvery { dataSource.fetchExchangeInfo("7") } returns listOf(infoData(7))

        val exchange = repo.getExchangeDetail(7)

        assertEquals(7, exchange.id)
        assertEquals("Name7", exchange.name)
    }

    @Test
    fun `getExchangeAssets maps rows to Currency`() = runTest {
        val currency = AssetCurrencyData(5, "Bitcoin", "BTC", 10_000.0)
        coEvery { dataSource.fetchExchangeAssets(1) } returns listOf(
            ExchangeAssetItem(currency, 2.0, null)
        )

        val rows = repo.getExchangeAssets(1)

        assertEquals(1, rows.size)
        assertEquals(5, rows[0].id)
        assertEquals(2.0, rows[0].balance)
    }

    private fun infoData(id: Int) = ExchangeInfoData(
        id = id,
        name = "Name$id",
        slug = "slug-$id",
        logo = "https://logo/$id",
        description = null,
        urls = null,
        makerFee = null,
        takerFee = null,
        dateLaunched = null,
        spotVolumeUsd = id.toDouble() * 1_000_000
    )
}
