package br.com.querosermb.presentation.exchangelist

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import br.com.querosermb.domain.model.Exchange
import br.com.querosermb.domain.usecase.GetExchangeListUseCase
import br.com.querosermb.presentation.UiText
import br.com.querosermb.presentation.ViewState
import br.com.querosermb.presentation.utils.toUiText
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class ExchangeListViewModel @Inject constructor(
    private val getExchangeList: GetExchangeListUseCase
) : ViewModel() {

    private val pageSize = GetExchangeListUseCase.DEFAULT_PAGE_SIZE

    private val _state = MutableStateFlow<ViewState<List<Exchange>>>(ViewState.Idle)
    val state: StateFlow<ViewState<List<Exchange>>> = _state.asStateFlow()

    private val _isLoadingMore = MutableStateFlow(false)
    val isLoadingMore: StateFlow<Boolean> = _isLoadingMore.asStateFlow()

    private val _loadMoreError = MutableStateFlow<UiText?>(null)
    val loadMoreError: StateFlow<UiText?> = _loadMoreError.asStateFlow()

    private var nextStart = 1
    private var hasMorePages = true

    fun loadInitialIfNeeded() {
        if (_state.value is ViewState.Success) return
        loadExchanges()
    }

    fun loadExchanges() {
        viewModelScope.launch {
            nextStart = 1
            hasMorePages = true
            _state.value = ViewState.Loading
            fetchPage()
        }
    }

    fun loadMore() {
        if (_isLoadingMore.value) return
        if (_state.value !is ViewState.Success) return
        if (!hasMorePages) return

        viewModelScope.launch {
            _isLoadingMore.value = true
            _loadMoreError.value = null
            try {
                val page = getExchangeList.execute(start = nextStart, limit = pageSize)
                hasMorePages = page.hasMore
                nextStart = page.nextStart
                val current = (_state.value as? ViewState.Success)?.data ?: emptyList()
                val merged = (current + page.items).sortedByDescending { it.spotVolumeUSD ?: -1.0 }
                _state.value = ViewState.Success(merged)
            } catch (e: Exception) {
                _loadMoreError.value = e.toUiText()
            } finally {
                _isLoadingMore.value = false
            }
        }
    }

    fun refresh() {
        loadExchanges()
    }

    private suspend fun fetchPage() {
        try {
            val page = getExchangeList.execute(start = nextStart, limit = pageSize)
            hasMorePages = page.hasMore
            nextStart = page.nextStart
            _state.value = if (page.items.isEmpty()) ViewState.Empty else ViewState.Success(page.items)
        } catch (e: Exception) {
            _state.value = ViewState.Error(e.toUiText())
        }
    }
}
