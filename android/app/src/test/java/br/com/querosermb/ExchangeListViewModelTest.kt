package br.com.querosermb

import app.cash.turbine.test
import br.com.querosermb.core.network.NetworkError
import br.com.querosermb.domain.model.ExchangeListPage
import br.com.querosermb.domain.repository.ExchangeRepository
import br.com.querosermb.domain.usecase.GetExchangeListUseCase
import br.com.querosermb.presentation.ViewState
import br.com.querosermb.presentation.exchangelist.ExchangeListViewModel
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class ExchangeListViewModelTest {

    private val testDispatcher = StandardTestDispatcher()
    private val repo = mockk<ExchangeRepository>()
    private lateinit var viewModel: ExchangeListViewModel

    @Before
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
        viewModel = ExchangeListViewModel(GetExchangeListUseCase(repo))
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `initial state is Idle`() {
        assertTrue(viewModel.state.value is ViewState.Idle)
    }

    @Test
    fun `loadExchanges sets Success state`() = runTest {
        val page = ExchangeListPage(listOf(sampleExchange(1)), false, 2)
        coEvery { repo.getExchangeList(1, 40) } returns page

        viewModel.state.test {
            assertEquals(ViewState.Idle, awaitItem())
            viewModel.loadExchanges()
            assertEquals(ViewState.Loading, awaitItem())
            val success = awaitItem()
            assertTrue(success is ViewState.Success)
            assertEquals(1, (success as ViewState.Success).data.size)
        }
    }

    @Test
    fun `loadExchanges sets Empty state when page is empty`() = runTest {
        coEvery { repo.getExchangeList(any(), any()) } returns
            ExchangeListPage(emptyList(), false, 1)

        viewModel.state.test {
            awaitItem() // Idle
            viewModel.loadExchanges()
            awaitItem() // Loading
            assertTrue(awaitItem() is ViewState.Empty)
        }
    }

    @Test
    fun `loadExchanges sets Error state on failure`() = runTest {
        coEvery { repo.getExchangeList(any(), any()) } throws NetworkError.NoConnection

        viewModel.state.test {
            awaitItem() // Idle
            viewModel.loadExchanges()
            awaitItem() // Loading
            val error = awaitItem()
            assertTrue(error is ViewState.Error)
        }
    }

    @Test
    fun `loadMore appends second page`() = runTest {
        coEvery { repo.getExchangeList(1, 40) } returns
            ExchangeListPage(listOf(sampleExchange(1)), true, 41)
        coEvery { repo.getExchangeList(41, 40) } returns
            ExchangeListPage(listOf(sampleExchange(2)), false, 42)

        viewModel.loadExchanges()
        testDispatcher.scheduler.advanceUntilIdle()

        val afterFirst = (viewModel.state.value as ViewState.Success).data
        assertEquals(1, afterFirst.size)

        viewModel.loadMore()
        testDispatcher.scheduler.advanceUntilIdle()

        val merged = (viewModel.state.value as ViewState.Success).data
        assertEquals(2, merged.size)
    }

    @Test
    fun `loadInitialIfNeeded does not re-fetch after success`() = runTest {
        coEvery { repo.getExchangeList(any(), any()) } returns
            ExchangeListPage(listOf(sampleExchange(1)), false, 2)

        viewModel.loadExchanges()
        testDispatcher.scheduler.advanceUntilIdle()
        coVerify(exactly = 1) { repo.getExchangeList(any(), any()) }

        viewModel.loadInitialIfNeeded()
        testDispatcher.scheduler.advanceUntilIdle()
        coVerify(exactly = 1) { repo.getExchangeList(any(), any()) }
    }
}
