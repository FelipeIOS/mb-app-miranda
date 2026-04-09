package br.com.querosermb

import br.com.querosermb.presentation.components.formatAsCompactUSD
import br.com.querosermb.presentation.components.formatAsMonthYear
import br.com.querosermb.presentation.components.formattedDecimal
import org.junit.Assert.assertTrue
import org.junit.Test

class FormattersTest {

    // --- formatAsCompactUSD ---

    @Test
    fun `formatAsCompactUSD below 1000 uses full currency`() {
        val result = 500.0.formatAsCompactUSD()
        assertTrue("got: $result", result.contains("500"))
        assertTrue("got: $result", result.startsWith("US$"))
    }

    @Test
    fun `formatAsCompactUSD at 1000 uses K suffix`() {
        val result = 1_000.0.formatAsCompactUSD()
        assertTrue("got: $result", result.contains("K"))
    }

    @Test
    fun `formatAsCompactUSD millions uses M suffix`() {
        val result = 2_500_000.0.formatAsCompactUSD()
        assertTrue("got: $result", result.contains("M"))
        assertTrue("got: $result", result.contains("2,5") || result.contains("2.5"))
    }

    @Test
    fun `formatAsCompactUSD billions uses B suffix`() {
        val result = 3_000_000_000.0.formatAsCompactUSD()
        assertTrue("got: $result", result.contains("B"))
        assertTrue("got: $result", result.contains("3,0") || result.contains("3.0"))
    }

    @Test
    fun `formatAsCompactUSD threshold 999 stays below K`() {
        val result = 999.0.formatAsCompactUSD()
        assertTrue("got: $result", !result.contains("K"))
    }

    // --- formatAsMonthYear ---

    @Test
    fun `formatAsMonthYear parses ISO 8601 and contains year`() {
        val result = "2018-05-01T12:00:00.000Z".formatAsMonthYear()
        assertTrue("got: $result", result.contains("2018"))
    }

    @Test
    fun `formatAsMonthYear parses ISO 8601 and contains portuguese month`() {
        val result = "2018-05-01T12:00:00.000Z".formatAsMonthYear()
        assertTrue("got: $result", result.lowercase().contains("mai"))
    }

    @Test
    fun `formatAsMonthYear returns original string on invalid input`() {
        val invalid = "not-a-date"
        val result = invalid.formatAsMonthYear()
        assertTrue("got: $result", result == invalid)
    }

    // --- formattedDecimal ---

    @Test
    fun `formattedDecimal uses comma as decimal separator for pt-BR`() {
        val result = 1234.5.formattedDecimal(2, 4)
        assertTrue("got: $result", result.contains(","))
    }

    @Test
    fun `formattedDecimal respects minFractionDigits`() {
        val result = 1.0.formattedDecimal(2, 4)
        // pt-BR: "1,00"
        assertTrue("got: $result", result.endsWith("00"))
    }

    @Test
    fun `formattedDecimal respects maxFractionDigits`() {
        val result = 1.123456.formattedDecimal(2, 4)
        val decimals = result.substringAfter(",")
        assertTrue("got: $result", decimals.length <= 4)
    }
}
