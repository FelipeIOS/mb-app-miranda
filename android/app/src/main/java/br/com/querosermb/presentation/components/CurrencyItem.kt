package br.com.querosermb.presentation.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import br.com.querosermb.domain.model.Currency
import br.com.querosermb.presentation.theme.MbAccent
import br.com.querosermb.presentation.theme.MbSurfaceAlt
import br.com.querosermb.presentation.theme.MbText

@Composable
fun CurrencyItem(currency: Currency) {
    Column {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(CircleShape)
                    .background(MbAccent),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = currency.symbol.take(3),
                    style = MaterialTheme.typography.bodySmall,
                    color = MbText,
                    textAlign = TextAlign.Center
                )
            }
            Spacer(Modifier.width(12.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = currency.name,
                    style = MaterialTheme.typography.titleMedium
                )
                Text(
                    text = currency.symbol,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            currency.priceUSD?.let { price ->
                Text(
                    text = price.formatAsUSD(),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MbText
                )
            }
        }
        HorizontalDivider(color = MbSurfaceAlt, thickness = 0.5.dp)
    }
}
