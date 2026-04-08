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
    /// nil tratado como -1.0 para ficar abaixo de todas as exchanges com volume real (incluindo zero).
    private static func sortExchangesByVolume(_ list: [Exchange]) -> [Exchange] {
        list.sorted { a, b in
            (a.spotVolumeUSD ?? -1.0) > (b.spotVolumeUSD ?? -1.0)
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
