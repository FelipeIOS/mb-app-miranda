import Foundation

// MARK: - Generic ViewState
enum ViewState<T> {
    case idle
    case loading
    case success(T)
    case empty
    case error(String)

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}

// MARK: - ExchangeList ViewModel
@MainActor
final class ExchangeListViewModel {
    @Published private(set) var state: ViewState<[Exchange]> = .idle
    @Published private(set) var isLoadingMore = false
    @Published var loadMoreErrorMessage: String?

    private let getExchangeList: GetExchangeListUseCase
    private let pageSize: Int

    private var nextStart = 1
    private var hasMorePages = true

    init(getExchangeList: GetExchangeListUseCase, pageSize: Int = GetExchangeListUseCase.defaultPageSize) {
        self.getExchangeList = getExchangeList
        self.pageSize = pageSize
    }

    /// Evita novo fetch ao reaparecer a lista (ex.: após voltar do detalhe). Pull-to-refresh usa `refresh()`.
    func loadInitialListIfNeeded() async {
        if case .success(let exchanges) = state, !exchanges.isEmpty {
            return
        }
        await loadExchanges()
    }

    func loadExchanges() async {
        guard !state.isLoading else { return }
        resetPaginationForInitialLoad()
        state = .loading
        loadMoreErrorMessage = nil
        await fetchFirstPage()
    }

    func loadMore() async {
        guard hasMorePages, !isLoadingMore else { return }
        if case .loading = state { return }
        guard case .success = state else { return }

        isLoadingMore = true
        loadMoreErrorMessage = nil
        defer { isLoadingMore = false }

        do {
            let page = try await getExchangeList.execute(start: nextStart, limit: pageSize)
            guard case .success(let current) = state else { return }

            hasMorePages = page.hasMore
            nextStart = page.nextStart
            let merged = Self.sortExchangesByVolume(current + page.items)
            state = merged.isEmpty ? .empty : .success(merged)
        } catch let error as NetworkError {
            loadMoreErrorMessage = error.errorDescription ?? Strings.Error.loadMore
        } catch {
            loadMoreErrorMessage = Strings.Error.loadMore
        }
    }

    func refresh() async {
        resetPaginationForInitialLoad()
        loadMoreErrorMessage = nil
        state = .loading
        await fetchFirstPage()
    }

    private func resetPaginationForInitialLoad() {
        nextStart = 1
        hasMorePages = true
    }

    /// Volume 24h vem do `/exchange/info`; ordenação no app substitui `sort=volume_24h` no map.
    private static func sortExchangesByVolume(_ list: [Exchange]) -> [Exchange] {
        list.sorted { a, b in
            (a.spotVolumeUSD ?? 0) > (b.spotVolumeUSD ?? 0)
        }
    }

    private func fetchFirstPage() async {
        do {
            let page = try await getExchangeList.execute(start: 1, limit: pageSize)
            hasMorePages = page.hasMore
            nextStart = page.nextStart
            let sorted = Self.sortExchangesByVolume(page.items)
            state = sorted.isEmpty ? .empty : .success(sorted)
        } catch let error as NetworkError {
            state = .error(error.errorDescription ?? Strings.Error.unknown)
        } catch {
            state = .error(Strings.Error.unknown)
        }
    }
}

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
