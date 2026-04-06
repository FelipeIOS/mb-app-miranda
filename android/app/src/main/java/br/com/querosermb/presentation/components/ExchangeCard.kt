package br.com.querosermb.presentation.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.painter.ColorPainter
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import br.com.querosermb.domain.model.Exchange
import br.com.querosermb.presentation.theme.MbGold
import br.com.querosermb.presentation.theme.MbSurface
import br.com.querosermb.presentation.theme.MbSurfaceAlt
import coil.compose.AsyncImage
import coil.request.ImageRequest

@Composable
fun ExchangeCard(
    exchange: Exchange,
    onClick: () -> Unit
) {
    Column {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clickable(onClick = onClick)
                .padding(horizontal = 16.dp, vertical = 12.dp),
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
                    .size(48.dp)
                    .clip(CircleShape)
            )
            Spacer(Modifier.width(12.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = exchange.name,
                    style = MaterialTheme.typography.titleMedium
                )
                exchange.spotVolumeUSD?.let { volume ->
                    Text(
                        text = volume.formatAsCompactUSD(),
                        style = MaterialTheme.typography.bodySmall,
                        color = MbGold
                    )
                }
                exchange.dateLaunched?.let { date ->
                    Text(
                        text = date.formatAsMonthYear(),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
            Icon(
                imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                contentDescription = null,
                tint = MbSurfaceAlt
            )
        }
        HorizontalDivider(color = MbSurfaceAlt, thickness = 0.5.dp)
    }
}
