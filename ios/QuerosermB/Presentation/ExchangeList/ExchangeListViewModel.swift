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
    @Published var state: ViewState<[Exchange]> = .idle

    private let getExchangeList: GetExchangeListUseCase

    init(getExchangeList: GetExchangeListUseCase) {
        self.getExchangeList = getExchangeList
    }

    func loadExchanges() async {
        guard !state.isLoading else { return }
        state = .loading
        do {
            let exchanges = try await getExchangeList.execute()
            state = exchanges.isEmpty ? .empty : .success(exchanges)
        } catch let error as NetworkError {
            state = .error(error.errorDescription ?? "Erro desconhecido.")
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func refresh() async {
        state = .idle
        await loadExchanges()
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
