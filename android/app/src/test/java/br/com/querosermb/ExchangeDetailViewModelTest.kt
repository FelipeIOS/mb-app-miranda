package br.com.querosermb

import br.com.querosermb.core.cache.CachedExchangeDetail
import br.com.querosermb.core.cache.ExchangeDetailCaching
import br.com.querosermb.domain.model.Currency
import br.com.querosermb.domain.model.Exchange
import br.com.querosermb.domain.repository.ExchangeRepository
import br.com.querosermb.domain.usecase.GetExchangeAssetsUseCase
import br.com.querosermb.domain.usecase.GetExchangeDetailUseCase
import br.com.querosermb.presentation.ViewState
import br.com.querosermb.presentation.exchangedetail.ExchangeDetailViewModel
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.every
import io.mockk.mockk
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class ExchangeDetailViewModelTest {

    private val testDispatcher = StandardTestDispatcher()
    private val repo = mockk<ExchangeRepository>()
    private val cache = mockk<ExchangeDetailCaching>(relaxed = true)
    private lateinit var viewModel: ExchangeDetailViewModel

    @Before
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
        viewModel = ExchangeDetailViewModel(
            getExchangeDetail = GetExchangeDetailUseCase(repo),
            getExchangeAssets = GetExchangeAssetsUseCase(repo),
            detailCache = cache
        )
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `load uses cache and skips repository`() = runTest {
        val exchange = sampleExchange(7)
        val cached = CachedExchangeDetail(exchange, emptyList(), 0L)
        every { cache.get(7, any()) } returns cached

        viewModel.load(exchange.id)
        testDispatcher.scheduler.advanceUntilIdle()

        assertTrue(viewModel.detailState.value is ViewState.Success)
        assertTrue(viewModel.assetsState.value is ViewState.Empty)
        coVerify(exactly = 0) { repo.getExchangeDetail(any()) }
        coVerify(exactly = 0) { repo.getExchangeAssets(any()) }
    }

    @Test
    fun `load without cache calls repository`() = runTest {
        val exchange = sampleExchange(8)
        val currencies = listOf(Currency(1, "BTC", "BTC", 50_000.0, null))
        every { cache.get(8, any()) } returns null
        coEvery { repo.getExchangeDetail(8) } returns exchange
        coEvery { repo.getExchangeAssets(8) } returns currencies

        viewModel.load(exchange.id)
        testDispatcher.scheduler.advanceUntilIdle()

        assertTrue(viewModel.detailState.value is ViewState.Success)
        assertTrue(viewModel.assetsState.value is ViewState.Success)
        coVerify(exactly = 1) { repo.getExchangeDetail(8) }
        coVerify(exactly = 1) { repo.getExchangeAssets(8) }
    }

    @Test
    fun `load with assets empty shows Empty state`() = runTest {
        val exchange = sampleExchange(9)
        every { cache.get(9, any()) } returns null
        coEvery { repo.getExchangeDetail(9) } returns exchange
        coEvery { repo.getExchangeAssets(9) } returns emptyList()

        viewModel.load(exchange.id)
        testDispatcher.scheduler.advanceUntilIdle()

        assertTrue(viewModel.assetsState.value is ViewState.Empty)
    }

    @Test
    fun `triggerLoad cancels previous job and reloads`() = runTest {
        val exchange = sampleExchange(10)
        every { cache.get(10, any()) } returns null
        coEvery { repo.getExchangeDetail(10) } returns exchange
        coEvery { repo.getExchangeAssets(10) } returns emptyList()

        viewModel.triggerLoad(exchange.id)
        testDispatcher.scheduler.advanceUntilIdle()

        assertTrue(viewModel.detailState.value is ViewState.Success)
    }

    @Test
    fun `load sets Error state when detail fails`() = runTest {
        val exchange = sampleExchange(11)
        every { cache.get(11, any()) } returns null
        coEvery { repo.getExchangeDetail(11) } throws RuntimeException("Network error")
        coEvery { repo.getExchangeAssets(11) } returns emptyList()

        viewModel.load(exchange.id)
        testDispatcher.scheduler.advanceUntilIdle()

        assertTrue(viewModel.detailState.value is ViewState.Error)
    }
}
