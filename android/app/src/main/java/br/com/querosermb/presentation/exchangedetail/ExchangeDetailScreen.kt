package br.com.querosermb.presentation.exchangedetail

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.painter.ColorPainter
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import br.com.querosermb.R
import br.com.querosermb.domain.model.Currency
import br.com.querosermb.domain.model.Exchange
import br.com.querosermb.presentation.ViewState
import br.com.querosermb.presentation.components.CurrencyItem
import br.com.querosermb.presentation.components.ErrorView
import br.com.querosermb.presentation.components.InfoRowSkeleton
import br.com.querosermb.presentation.components.TextLineSkeleton
import br.com.querosermb.presentation.theme.MbSurface
import br.com.querosermb.presentation.components.formatAsCompactUSD
import br.com.querosermb.presentation.components.formatAsMonthYear
import br.com.querosermb.presentation.components.formattedDecimal
import br.com.querosermb.presentation.theme.MbAccent
import br.com.querosermb.presentation.theme.MbGold
import br.com.querosermb.presentation.theme.MbPrimary
import br.com.querosermb.presentation.theme.MbSurface
import br.com.querosermb.presentation.theme.MbSurfaceAlt
import br.com.querosermb.presentation.theme.MbText
import br.com.querosermb.presentation.theme.MbTextSub
import coil.compose.AsyncImage
import coil.request.ImageRequest

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ExchangeDetailScreen(
    exchangeId: Int,
    onBack: () -> Unit,
    viewModel: ExchangeDetailViewModel = hiltViewModel()
) {
    val detailState by viewModel.detailState.collectAsState()
    val assetsState by viewModel.assetsState.collectAsState()

    LaunchedEffect(exchangeId) {
        viewModel.load(exchangeId)
    }

    val topBarTitle = (detailState as? ViewState.Success)?.data?.name.orEmpty()

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = topBarTitle,
                        style = MaterialTheme.typography.titleLarge,
                        color = MbText
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Voltar",
                            tint = MbText
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = MbPrimary)
            )
        },
        containerColor = MbPrimary
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .verticalScroll(rememberScrollState())
        ) {
            ExchangeHeaderSection(state = detailState)
            HorizontalDivider(color = MbSurfaceAlt)

            InfoSection(
                state = detailState,
                onRetry = { viewModel.triggerLoad(exchangeId) }
            )
            HorizontalDivider(color = MbSurfaceAlt)

            CurrenciesSection(
                state = assetsState,
                onRetry = { viewModel.triggerLoad(exchangeId) }
            )
        }
    }
}

@Composable
private fun ExchangeHeaderSection(state: ViewState<Exchange>) {
    when (state) {
        is ViewState.Loading, is ViewState.Idle -> {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    modifier = Modifier
                        .size(72.dp)
                        .clip(CircleShape)
                        .background(MbSurfaceAlt)
                )
                Spacer(Modifier.width(16.dp))
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    TextLineSkeleton(fraction = 0.55f, height = 18)
                    TextLineSkeleton(fraction = 0.2f, height = 13)
                }
            }
        }
        is ViewState.Success -> ExchangeHeader(exchange = state.data)
        else -> {}
    }
}

@Composable
private fun ExchangeHeader(exchange: Exchange) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        AsyncImage(
            model = ImageRequest.Builder(LocalContext.current)
                .data(exchange.logo)
                .crossfade(true)
                .build(),
            placeholder = ColorPainter(MbSurface),
            error = ColorPainter(MbSurface),
            contentDescription = exchange.name,
            contentScale = ContentScale.Fit,
            modifier = Modifier
                .size(72.dp)
                .clip(CircleShape)
        )
        Spacer(Modifier.width(16.dp))
        Column {
            Text(
                text = exchange.name,
                style = MaterialTheme.typography.displayLarge
            )
            Text(
                text = "ID: ${exchange.id}",
                style = MaterialTheme.typography.labelSmall,
                fontFamily = FontFamily.Monospace,
                color = MbTextSub
            )
        }
    }
}

@Composable
private fun InfoSection(
    state: ViewState<Exchange>,
    onRetry: () -> Unit
) {
    Column(modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp)) {
        Text(
            text = stringResource(R.string.detail_about),
            style = MaterialTheme.typography.titleLarge,
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
        )

        when (state) {
            is ViewState.Loading, is ViewState.Idle -> {
                repeat(4) { InfoRowSkeleton() }
            }
            is ViewState.Success -> {
                InfoContent(exchange = state.data, onRetry = onRetry)
            }
            is ViewState.Error -> {
                ErrorView(message = state.message, onRetry = onRetry)
            }
            is ViewState.Empty -> {}
        }
    }
}

@Composable
private fun InfoContent(exchange: Exchange, onRetry: () -> Unit) {
    val context = LocalContext.current
    var isDescriptionExpanded by remember { mutableStateOf(false) }

    val tiles = buildList {
        exchange.spotVolumeUSD?.let { add(stringResource(R.string.detail_volume) to it.formatAsCompactUSD()) }
        exchange.dateLaunched?.let { add(stringResource(R.string.detail_launched) to it.formatAsMonthYear()) }
        exchange.makerFee?.let { add(stringResource(R.string.detail_maker_fee) to "${it.formattedDecimal(2, 12)}%") }
        exchange.takerFee?.let { add(stringResource(R.string.detail_taker_fee) to "${it.formattedDecimal(2, 12)}%") }
    }

    if (tiles.isNotEmpty()) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 8.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            tiles.chunked(2).forEach { row ->
                Row(
                    modifier = Modifier.weight(1f),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    row.forEach { (label, value) ->
                        InfoTileCard(
                            label = label,
                            value = value,
                            modifier = Modifier.weight(1f)
                        )
                    }
                    if (row.size == 1) Spacer(Modifier.weight(1f))
                }
            }
        }
    }

    exchange.description?.takeIf { it.isNotBlank() }?.let { desc ->
        Column(modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)) {
            Text(
                text = desc,
                style = MaterialTheme.typography.bodyMedium,
                maxLines = if (isDescriptionExpanded) Int.MAX_VALUE else 3,
                color = MbTextSub
            )
            TextButton(
                onClick = { isDescriptionExpanded = !isDescriptionExpanded },
                colors = ButtonDefaults.textButtonColors(contentColor = MbAccent)
            ) {
                Text(
                    text = if (isDescriptionExpanded) {
                        stringResource(R.string.detail_see_less)
                    } else {
                        stringResource(R.string.detail_see_more)
                    }
                )
            }
        }
    }

    exchange.websiteURL?.let { url ->
        Button(
            onClick = {
                context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
            },
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 8.dp),
            colors = ButtonDefaults.buttonColors(containerColor = MbAccent)
        ) {
            Text(
                text = stringResource(R.string.detail_visit_website),
                color = MbText
            )
        }
    }
}

@Composable
private fun InfoTileCard(label: String, value: String, modifier: Modifier = Modifier) {
    Card(
        modifier = modifier,
        colors = CardDefaults.cardColors(containerColor = MbSurface),
        shape = RoundedCornerShape(8.dp)
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            Text(
                text = label,
                style = MaterialTheme.typography.bodySmall,
                color = MbTextSub
            )
            Spacer(Modifier.height(4.dp))
            Text(
                text = value,
                style = MaterialTheme.typography.titleMedium,
                color = MbGold
            )
        }
    }
}

@Composable
private fun CurrenciesSection(
    state: ViewState<List<Currency>>,
    onRetry: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp)
            .testTag("currencies_section")
    ) {
        Text(
            text = stringResource(R.string.detail_currencies),
            style = MaterialTheme.typography.titleLarge,
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
        )

        when (state) {
            is ViewState.Loading, is ViewState.Idle -> {
                repeat(6) { InfoRowSkeleton() }
            }
            is ViewState.Success -> {
                state.data.forEach { currency ->
                    CurrencyItem(currency = currency)
                }
            }
            is ViewState.Empty -> {
                Box(modifier = Modifier.fillMaxWidth().padding(16.dp)) {
                    Text(
                        text = stringResource(R.string.detail_currencies_empty),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MbTextSub
                    )
                }
            }
            is ViewState.Error -> {
                ErrorView(message = state.message, onRetry = onRetry)
            }
        }
    }
}
