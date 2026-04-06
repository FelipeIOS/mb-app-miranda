package br.com.querosermb.presentation.exchangelist

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.pulltorefresh.PullToRefreshContainer
import androidx.compose.material3.pulltorefresh.rememberPullToRefreshState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import br.com.querosermb.R
import br.com.querosermb.domain.model.Exchange
import br.com.querosermb.presentation.ViewState
import br.com.querosermb.presentation.components.EmptyStateView
import br.com.querosermb.presentation.components.ErrorView
import br.com.querosermb.presentation.components.ExchangeCard
import br.com.querosermb.presentation.components.ExchangeCardSkeleton
import br.com.querosermb.presentation.theme.MbGold
import br.com.querosermb.presentation.theme.MbPrimary
import br.com.querosermb.presentation.theme.MbText

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ExchangeListScreen(
    onItemClick: (Exchange) -> Unit,
    viewModel: ExchangeListViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsState()
    val isLoadingMore by viewModel.isLoadingMore.collectAsState()
    val loadMoreError by viewModel.loadMoreError.collectAsState()

    val pullRefreshState = rememberPullToRefreshState()
    LaunchedEffect(pullRefreshState.isRefreshing) {
        if (pullRefreshState.isRefreshing) {
            viewModel.refresh()
            pullRefreshState.endRefresh()
        }
    }

    LaunchedEffect(Unit) {
        viewModel.loadInitialIfNeeded()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = stringResource(R.string.exchanges_title),
                        style = MaterialTheme.typography.titleLarge,
                        color = MbText
                    )
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = MbPrimary)
            )
        },
        containerColor = MbPrimary
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .nestedScroll(pullRefreshState.nestedScrollConnection)
        ) {
            when (val s = state) {
                is ViewState.Idle, is ViewState.Loading -> {
                    LazyColumn(modifier = Modifier.fillMaxSize()) {
                        items(8) { ExchangeCardSkeleton() }
                    }
                }

                is ViewState.Success -> {
                    ExchangeList(
                        exchanges = s.data,
                        isLoadingMore = isLoadingMore,
                        loadMoreError = loadMoreError,
                        onItemClick = onItemClick,
                        onLoadMore = { viewModel.loadMore() }
                    )
                }

                is ViewState.Empty -> EmptyStateView(
                    modifier = Modifier.fillMaxSize()
                )

                is ViewState.Error -> ErrorView(
                    message = s.message,
                    onRetry = { viewModel.loadExchanges() },
                    modifier = Modifier.fillMaxSize()
                )
            }

            PullToRefreshContainer(
                state = pullRefreshState,
                modifier = Modifier.align(Alignment.TopCenter),
                containerColor = MbPrimary,
                contentColor = MbGold
            )
        }
    }
}

@Composable
private fun ExchangeList(
    exchanges: List<Exchange>,
    isLoadingMore: Boolean,
    loadMoreError: String?,
    onItemClick: (Exchange) -> Unit,
    onLoadMore: () -> Unit
) {
    val listState = rememberLazyListState()
    val shouldLoadMore by remember {
        derivedStateOf {
            val lastVisible = listState.layoutInfo.visibleItemsInfo.lastOrNull()?.index ?: -1
            lastVisible >= exchanges.size - 1 && exchanges.isNotEmpty()
        }
    }

    LaunchedEffect(shouldLoadMore) {
        if (shouldLoadMore) onLoadMore()
    }

    LazyColumn(
        state = listState,
        modifier = Modifier.fillMaxSize()
    ) {
        items(items = exchanges, key = { it.id }) { exchange ->
            ExchangeCard(exchange = exchange, onClick = { onItemClick(exchange) })
        }

        if (isLoadingMore) {
            item {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp)
                        .background(MbPrimary),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator(color = MbGold)
                }
            }
        }

        loadMoreError?.let { error ->
            item {
                Text(
                    text = error,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.error,
                    textAlign = TextAlign.Center
                )
            }
        }
    }
}
