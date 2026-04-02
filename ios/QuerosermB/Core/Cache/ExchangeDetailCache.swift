import Foundation

struct CachedExchangeDetail {
    let detail: Exchange
    let assets: [Currency]
    let fetchedAt: Date
}

protocol ExchangeDetailCaching: AnyObject {
    func get(exchangeId: Int, ttl: TimeInterval) -> CachedExchangeDetail?
    func set(exchangeId: Int, detail: Exchange, assets: [Currency])
}

/// Cache em memória por `exchangeId` com TTL e limite simples de entradas (evita crescimento indefinido).
final class ExchangeDetailCache: ExchangeDetailCaching {
    private let lock = NSLock()
    private var storage: [Int: CachedExchangeDetail] = [:]
    private let maxEntries: Int

    init(maxEntries: Int = 20) {
        self.maxEntries = max(1, maxEntries)
    }

    func get(exchangeId: Int, ttl: TimeInterval) -> CachedExchangeDetail? {
        lock.lock()
        defer { lock.unlock() }
        guard let entry = storage[exchangeId] else { return nil }
        guard Date().timeIntervalSince(entry.fetchedAt) < ttl else {
            storage.removeValue(forKey: exchangeId)
            return nil
        }
        return entry
    }

    func set(exchangeId: Int, detail: Exchange, assets: [Currency]) {
        lock.lock()
        defer { lock.unlock() }
        let entry = CachedExchangeDetail(detail: detail, assets: assets, fetchedAt: Date())
        storage[exchangeId] = entry
        evictIfNeeded()
    }

    private func evictIfNeeded() {
        guard storage.count > maxEntries else { return }
        guard let oldestKey = storage.min(by: { $0.value.fetchedAt < $1.value.fetchedAt })?.key else { return }
        storage.removeValue(forKey: oldestKey)
    }
}
