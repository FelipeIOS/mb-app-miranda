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
final class ExchangeListViewModel: ObservableObject {
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
            loadMoreErrorMessage = error.errorDescription ?? "Não foi possível carregar mais."
        } catch {
            loadMoreErrorMessage = error.localizedDescription
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
            state = .error(error.errorDescription ?? "Erro desconhecido.")
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}

// MARK: - ExchangeDetail ViewModel
@MainActor
final class ExchangeDetailViewModel: ObservableObject {
    @Published var detailState: ViewState<Exchange> = .loading
    @Published var assetsState: ViewState<[Currency]> = .loading

    private let getExchangeDetail: GetExchangeDetailUseCase
    private let getExchangeAssets: GetExchangeAssetsUseCase

    init(
        getExchangeDetail: GetExchangeDetailUseCase,
        getExchangeAssets: GetExchangeAssetsUseCase
    ) {
        self.getExchangeDetail = getExchangeDetail
        self.getExchangeAssets = getExchangeAssets
    }

    func load(exchange: Exchange) async {
        // Carrega detail e assets em paralelo
        async let detail = loadDetail(id: exchange.id)
        async let assets = loadAssets(id: exchange.id)
        _ = await (detail, assets)
    }

    private func loadDetail(id: Int) async {
        do {
            let detail = try await getExchangeDetail.execute(id: id)
            detailState = .success(detail)
        } catch let error as NetworkError {
            detailState = .error(error.errorDescription ?? "Erro ao carregar detalhes.")
        } catch {
            detailState = .error(error.localizedDescription)
        }
    }

    private func loadAssets(id: Int) async {
        do {
            let assets = try await getExchangeAssets.execute(id: id)
            assetsState = assets.isEmpty ? .empty : .success(assets)
        } catch let error as NetworkError {
            assetsState = .error(error.errorDescription ?? "Erro ao carregar moedas.")
        } catch {
            assetsState = .error(error.localizedDescription)
        }
    }
}
