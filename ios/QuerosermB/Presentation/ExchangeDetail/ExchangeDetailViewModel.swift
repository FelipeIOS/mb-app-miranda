import Foundation

// MARK: - ExchangeDetail ViewModel

@MainActor
final class ExchangeDetailViewModel {
    @Published var detailState: ViewState<Exchange> = .loading
    @Published var assetsState: ViewState<[Currency]> = .loading

    private let getExchangeDetail: GetExchangeDetailUseCase
    private let getExchangeAssets: GetExchangeAssetsUseCase
    private let detailCache: ExchangeDetailCaching

    /// TTL sugerido no plano: 60–120 s.
    private static let cacheTTL: TimeInterval = 90

    private var currentLoadTask: Task<Void, Never>?

    init(
        getExchangeDetail: GetExchangeDetailUseCase,
        getExchangeAssets: GetExchangeAssetsUseCase,
        detailCache: ExchangeDetailCaching
    ) {
        self.getExchangeDetail = getExchangeDetail
        self.getExchangeAssets = getExchangeAssets
        self.detailCache = detailCache
    }

    /// Dispara o carregamento cancelando qualquer load anterior em andamento.
    /// Use nos botões de retry — o `.task {}` da view usa `load(exchange:)` diretamente.
    func triggerLoad(exchange: Exchange) {
        currentLoadTask?.cancel()
        currentLoadTask = Task {
            await load(exchange: exchange)
        }
    }

    func load(exchange: Exchange) async {
        let id = exchange.id
        if let cached = detailCache.get(exchangeId: id, ttl: Self.cacheTTL) {
            detailState = .success(cached.detail)
            assetsState = cached.assets.isEmpty ? .empty : .success(cached.assets)
            return
        }

        detailState = .loading
        assetsState = .loading

        async let detailResult = fetchDetail(id: id)
        async let assetsResult = fetchAssets(id: id)
        let (detailRes, assetsRes) = await (detailResult, assetsResult)

        switch (detailRes, assetsRes) {
        case (.success(let detail), .success(let assets)):
            detailCache.set(exchangeId: id, detail: detail, assets: assets)
            detailState = .success(detail)
            assetsState = assets.isEmpty ? .empty : .success(assets)
        case (.failure(let err), .success(let assets)):
            detailState = .error(Self.message(for: err, fallback: Strings.Error.detail))
            assetsState = assets.isEmpty ? .empty : .success(assets)
        case (.success(let detail), .failure(let err)):
            detailState = .success(detail)
            assetsState = .error(Self.message(for: err, fallback: Strings.Error.assets))
        case (.failure(let dErr), .failure(let aErr)):
            detailState = .error(Self.message(for: dErr, fallback: Strings.Error.detail))
            assetsState = .error(Self.message(for: aErr, fallback: Strings.Error.assets))
        }
    }

    private func fetchDetail(id: Int) async -> Result<Exchange, Error> {
        do {
            return .success(try await getExchangeDetail.execute(id: id))
        } catch {
            return .failure(error)
        }
    }

    private func fetchAssets(id: Int) async -> Result<[Currency], Error> {
        do {
            return .success(try await getExchangeAssets.execute(id: id))
        } catch {
            return .failure(error)
        }
    }

    private static func message(for error: Error, fallback: String) -> String {
        if let ne = error as? NetworkError {
            return ne.errorDescription ?? fallback
        }
        return error.localizedDescription
    }
}
