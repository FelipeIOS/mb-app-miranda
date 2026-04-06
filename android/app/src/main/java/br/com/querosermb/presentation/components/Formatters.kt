package br.com.querosermb.presentation.components

import java.text.NumberFormat
import java.time.LocalDate
import java.time.format.DateTimeFormatter
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

private val isoInputFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
private val monthYearFormatter = DateTimeFormatter.ofPattern("MMM yyyy", Locale("pt", "BR"))

fun String.formatAsMonthYear(): String {
    return try {
        val date = LocalDate.parse(this, isoInputFormatter)
        date.format(monthYearFormatter).replaceFirstChar { it.uppercase() }
    } catch (e: Exception) {
        this
    }
}
