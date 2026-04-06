package br.com.querosermb.presentation.components

import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.Locale

private val ptBR = Locale("pt", "BR")
private val currencyFormatter by lazy {
    NumberFormat.getCurrencyInstance(ptBR).apply { currency = java.util.Currency.getInstance("USD") }
}

fun Double.formatAsCompactUSD(): String {
    return when {
        this >= 1_000_000_000 -> "US$ ${"%.1f".format(this / 1_000_000_000)} B"
        this >= 1_000_000 -> "US$ ${"%.1f".format(this / 1_000_000)} M"
        this >= 1_000 -> "US$ ${"%.1f".format(this / 1_000)} K"
        else -> currencyFormatter.format(this)
    }
}

fun Double.formatAsUSD(): String = currencyFormatter.format(this)

fun Double.formattedDecimal(minFractionDigits: Int = 2, maxFractionDigits: Int = 4): String {
    val fmt = NumberFormat.getNumberInstance(ptBR).apply {
        this.minimumFractionDigits = minFractionDigits
        this.maximumFractionDigits = maxFractionDigits
    }
    return fmt.format(this)
}

fun String.formatAsMonthYear(): String {
    return try {
        val inputFmt = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
        val outputFmt = SimpleDateFormat("MMM yyyy", Locale("pt", "BR"))
        val date = inputFmt.parse(this)
        outputFmt.format(date!!).replaceFirstChar { it.uppercase() }
    } catch (e: Exception) {
        this
    }
}
