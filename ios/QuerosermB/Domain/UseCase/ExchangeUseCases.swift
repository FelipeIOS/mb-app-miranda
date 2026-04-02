import Foundation

// MARK: - Get Exchange List
struct GetExchangeListUseCase {
    private let repository: ExchangeRepository

    init(repository: ExchangeRepository) {
        self.repository = repository
    }

    func execute(start: Int = 1, limit: Int = 100) async throws -> [Exchange] {
        try await repository.getExchangeList(start: start, limit: limit)
    }
}

// MARK: - Get Exchange Detail
struct GetExchangeDetailUseCase {
    private let repository: ExchangeRepository

    init(repository: ExchangeRepository) {
        self.repository = repository
    }

    func execute(id: Int) async throws -> Exchange {
        try await repository.getExchangeDetail(id: id)
    }
}

// MARK: - Get Exchange Assets
struct GetExchangeAssetsUseCase {
    private let repository: ExchangeRepository

    init(repository: ExchangeRepository) {
        self.repository = repository
    }

    func execute(id: Int) async throws -> [Currency] {
        try await repository.getExchangeAssets(id: id)
    }
}
