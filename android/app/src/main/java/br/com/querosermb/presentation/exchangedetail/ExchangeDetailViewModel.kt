package br.com.querosermb.presentation.exchangedetail

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import br.com.querosermb.core.cache.ExchangeDetailCaching
import br.com.querosermb.core.network.NetworkError
import br.com.querosermb.domain.model.Currency
import br.com.querosermb.domain.model.Exchange
import br.com.querosermb.domain.usecase.GetExchangeAssetsUseCase
import br.com.querosermb.domain.usecase.GetExchangeDetailUseCase
import br.com.querosermb.presentation.ViewState
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Job
import kotlinx.coroutines.async
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

    fun load(exchange: Exchange) {
        if (loadJob?.isActive == true) return
        loadJob = viewModelScope.launch {
            doLoad(exchange)
        }
    }

    fun triggerLoad(exchange: Exchange) {
        loadJob?.cancel()
        _detailState.value = ViewState.Loading
        _assetsState.value = ViewState.Loading
        loadJob = viewModelScope.launch {
            doLoad(exchange)
        }
    }

    private suspend fun doLoad(exchange: Exchange) {
        val cached = detailCache.get(exchange.id, CACHE_TTL_MS)
        if (cached != null) {
            _detailState.value = ViewState.Success(cached.detail)
            _assetsState.value = if (cached.assets.isEmpty()) {
                ViewState.Empty
            } else {
                ViewState.Success(cached.assets)
            }
            return
        }

        val detailDeferred = viewModelScope.async {
            runCatching { getExchangeDetail.execute(exchange.id) }
        }
        val assetsDeferred = viewModelScope.async {
            runCatching { getExchangeAssets.execute(exchange.id) }
        }

        val detailResult = detailDeferred.await()
        val assetsResult = assetsDeferred.await()

        val detail = detailResult.getOrNull()
        val assets = assetsResult.getOrNull()

        if (detail != null && assets != null) {
            detailCache.set(exchange.id, detail, assets)
        }

        _detailState.value = detailResult.fold(
            onSuccess = { ViewState.Success(it) },
            onFailure = { ViewState.Error(it.toUserMessage()) }
        )

        _assetsState.value = assetsResult.fold(
            onSuccess = { if (it.isEmpty()) ViewState.Empty else ViewState.Success(it) },
            onFailure = { ViewState.Error(it.toUserMessage()) }
        )
    }

    private fun Throwable.toUserMessage(): String =
        (this as? NetworkError)?.userMessage() ?: message ?: "Erro desconhecido"
}
