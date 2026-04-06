package br.com.querosermb.core.cache

import br.com.querosermb.domain.model.Currency
import br.com.querosermb.domain.model.Exchange
import java.util.concurrent.locks.ReentrantLock
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.concurrent.withLock

interface Clock {
    fun now(): Long
}

class SystemClock @Inject constructor() : Clock {
    override fun now(): Long = System.currentTimeMillis()
}

data class CachedExchangeDetail(
    val detail: Exchange,
    val assets: List<Currency>,
    val fetchedAt: Long
)

interface ExchangeDetailCaching {
    fun get(exchangeId: Int, ttlMs: Long): CachedExchangeDetail?
    fun set(exchangeId: Int, detail: Exchange, assets: List<Currency>)
}

@Singleton
class ExchangeDetailCache @Inject constructor(
    private val clock: Clock
) : ExchangeDetailCaching {

    private val maxEntries: Int = 20

    private val storage = mutableMapOf<Int, CachedExchangeDetail>()
    private val lock = ReentrantLock()

    override fun get(exchangeId: Int, ttlMs: Long): CachedExchangeDetail? = lock.withLock {
        val entry = storage[exchangeId] ?: return null
        val elapsed = clock.now() - entry.fetchedAt
        if (elapsed > ttlMs) {
            storage.remove(exchangeId)
            return null
        }
        entry
    }

    override fun set(exchangeId: Int, detail: Exchange, assets: List<Currency>) = lock.withLock {
        if (storage.size >= maxEntries && !storage.containsKey(exchangeId)) {
            val oldest = storage.minByOrNull { it.value.fetchedAt }?.key
            if (oldest != null) storage.remove(oldest)
        }
        storage[exchangeId] = CachedExchangeDetail(
            detail = detail,
            assets = assets,
            fetchedAt = clock.now()
        )
    }
}
