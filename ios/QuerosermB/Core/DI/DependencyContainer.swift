import Foundation

final class DependencyContainer: ObservableObject {

    private let testMode: Bool

    init(testMode: Bool = false) {
        self.testMode = testMode
    }

    // MARK: - Network
    private lazy var apiClient: APIClient = {
        APIClient(apiKey: APIKeyProvider.key)
    }()

    // MARK: - Data
    private lazy var remoteDataSource: ExchangeRemoteDataSource = {
        ExchangeRemoteDataSource(client: apiClient)
    }()

    private lazy var exchangeRepository: ExchangeRepository = {
        #if DEBUG
        if testMode { return UITestStubExchangeRepository() }
        #endif
        return ExchangeRepositoryImpl(dataSource: remoteDataSource)
    }()

    private(set) lazy var exchangeDetailCache: ExchangeDetailCaching = ExchangeDetailCache()

    // MARK: - Use Cases
    func makeGetExchangeListUseCase() -> GetExchangeListUseCase {
        GetExchangeListUseCase(repository: exchangeRepository)
    }

    func makeGetExchangeDetailUseCase() -> GetExchangeDetailUseCase {
        GetExchangeDetailUseCase(repository: exchangeRepository)
    }

    func makeGetExchangeAssetsUseCase() -> GetExchangeAssetsUseCase {
        GetExchangeAssetsUseCase(repository: exchangeRepository)
    }
}
