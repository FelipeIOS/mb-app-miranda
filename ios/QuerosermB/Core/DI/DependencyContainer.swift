import Foundation

final class DependencyContainer {
    // Singleton
    static let shared = DependencyContainer()
    private init() {}

    // MARK: - Network
    private lazy var apiClient: APIClient = {
        APIClient(apiKey: APIKeyProvider.key)
    }()

    // MARK: - Data
    private lazy var remoteDataSource: ExchangeRemoteDataSource = {
        ExchangeRemoteDataSource(client: apiClient)
    }()

    private lazy var exchangeRepository: ExchangeRepository = {
        ExchangeRepositoryImpl(dataSource: remoteDataSource)
    }()

    // MARK: - Use Cases (acesso externo)
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
