package br.com.querosermb

import br.com.querosermb.core.cache.Clock
import br.com.querosermb.core.cache.ExchangeDetailCache
import br.com.querosermb.domain.model.Currency
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test

class FakeClock(var time: Long = 0L) : Clock {
    override fun now(): Long = time
}

class ExchangeDetailCacheTest {

    @Test
    fun `get returns null when cache is empty`() {
        val cache = ExchangeDetailCache(FakeClock())
        assertNull(cache.get(1, 90_000L))
    }

    @Test
    fun `get returns entry when within TTL`() {
        val clock = FakeClock(1000L)
        val cache = ExchangeDetailCache(clock)
        cache.set(1, sampleExchange(1), emptyList())
        clock.time = 5000L

        assertNotNull(cache.get(1, 90_000L))
    }

    @Test
    fun `get returns null when TTL expired`() {
        val clock = FakeClock(1000L)
        val cache = ExchangeDetailCache(clock)
        cache.set(1, sampleExchange(1), emptyList())
        clock.time = 100_000L

        assertNull(cache.get(1, 90_000L))
    }

    @Test
    fun `get removes expired entry from storage`() {
        val clock = FakeClock(1000L)
        val cache = ExchangeDetailCache(clock)
        cache.set(1, sampleExchange(1), emptyList())
        clock.time = 100_000L

        cache.get(1, 90_000L) // triggers removal
        clock.time = 1000L    // reset time — still null (was removed)
        assertNull(cache.get(1, 90_000L))
    }

    @Test
    fun `evicts oldest entry when maxEntries exceeded`() {
        val clock = FakeClock()
        val cache = ExchangeDetailCache(clock)

        // Fill 20 entries (maxEntries = 20), entry id=1 is oldest
        for (i in 1..20) {
            clock.time = i * 1000L
            cache.set(i, sampleExchange(i), emptyList())
        }

        // Adding 21st should evict id=1 (oldest fetchedAt)
        clock.time = 21_000L
        cache.set(21, sampleExchange(21), emptyList())

        assertNull("ID 1 should be evicted (oldest)", cache.get(1, 3_600_000L))
        assertNotNull(cache.get(2, 3_600_000L))
        assertNotNull(cache.get(21, 3_600_000L))
    }

    @Test
    fun `set assets are retrievable`() {
        val clock = FakeClock(0L)
        val cache = ExchangeDetailCache(clock)
        val currencies = listOf(Currency(1, "Bitcoin", "BTC", 50_000.0, null))
        cache.set(1, sampleExchange(1), currencies)

        val result = cache.get(1, 90_000L)
        assertNotNull(result)
        assert(result!!.assets.size == 1)
        assert(result.assets[0].symbol == "BTC")
    }
}
