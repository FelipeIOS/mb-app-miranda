package br.com.querosermb.presentation.exchangedetail

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import br.com.querosermb.core.cache.ExchangeDetailCaching
import br.com.querosermb.domain.model.Currency
import br.com.querosermb.domain.model.Exchange
import br.com.querosermb.domain.usecase.GetExchangeAssetsUseCase
import br.com.querosermb.domain.usecase.GetExchangeDetailUseCase
import br.com.querosermb.presentation.ViewState
import br.com.querosermb.presentation.utils.toUiText
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Job
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class ExchangeDetailViewModel @Inject constructor(
    private val getExchangeDetail: GetExchangeDetailUseCase,
    private val getExchangeAssets: GetExchangeAssetsUseCase,
    private val detailCache: ExchangeDetailCaching
) : ViewModel() {

    companion object {
        private const val CACHE_TTL_MS = 90_000L
    }

    private val _detailState = MutableStateFlow<ViewState<Exchange>>(ViewState.Loading)
    val detailState: StateFlow<ViewState<Exchange>> = _detailState.asStateFlow()

    private val _assetsState = MutableStateFlow<ViewState<List<Currency>>>(ViewState.Loading)
    val assetsState: StateFlow<ViewState<List<Currency>>> = _assetsState.asStateFlow()

    private var loadJob: Job? = null

    fun load(id: Int) {
        if (loadJob?.isActive == true) return
        loadJob = viewModelScope.launch {
            doLoad(id)
        }
    }

    fun triggerLoad(id: Int) {
        loadJob?.cancel()
        loadJob = viewModelScope.launch {
            doLoad(id)
        }
    }

    private suspend fun doLoad(id: Int) {
        val cached = detailCache.get(id, CACHE_TTL_MS)
        if (cached != null) {
            _detailState.value = ViewState.Success(cached.detail)
            _assetsState.value = if (cached.assets.isEmpty()) {
                ViewState.Empty
            } else {
                ViewState.Success(cached.assets)
            }
            return
        }

        _detailState.value = ViewState.Loading
        _assetsState.value = ViewState.Loading

        val (detailResult, assetsResult) = coroutineScope {
            val detailDeferred = async { runCatching { getExchangeDetail.execute(id) } }
            val assetsDeferred = async { runCatching { getExchangeAssets.execute(id) } }
            detailDeferred.await() to assetsDeferred.await()
        }

        val detail = detailResult.getOrNull()
        val assets = assetsResult.getOrNull()

        if (detail != null && assets != null) {
            detailCache.set(id, detail, assets)
        }

        _detailState.value = detailResult.fold(
            onSuccess = { ViewState.Success(it) },
            onFailure = { ViewState.Error(it.toUiText()) }
        )

        _assetsState.value = assetsResult.fold(
            onSuccess = { if (it.isEmpty()) ViewState.Empty else ViewState.Success(it) },
            onFailure = { ViewState.Error(it.toUiText()) }
        )
    }
}
