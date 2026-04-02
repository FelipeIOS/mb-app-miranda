import XCTest
@testable import QuerosermB

// MARK: - Mock Repository
final class MockExchangeRepository: ExchangeRepository {
    var shouldFail = false
    var stubbedExchanges: [Exchange] = []
    var stubbedCurrencies: [Currency] = []

    func getExchangeList(start: Int, limit: Int) async throws -> [Exchange] {
        if shouldFail { throw NetworkError.serverError(statusCode: 500) }
        return stubbedExchanges
    }

    func getExchangeDetail(id: Int) async throws -> Exchange {
        if shouldFail { throw NetworkError.serverError(statusCode: 500) }
        guard let exchange = stubbedExchanges.first(where: { $0.id == id }) else {
            throw NetworkError.invalidResponse
        }
        return exchange
    }

    func getExchangeAssets(id: Int) async throws -> [Currency] {
        if shouldFail { throw NetworkError.serverError(statusCode: 500) }
        return stubbedCurrencies
    }
}

// MARK: - UseCase Tests
final class GetExchangeListUseCaseTests: XCTestCase {
    var mockRepo: MockExchangeRepository!
    var useCase: GetExchangeListUseCase!

    override func setUp() {
        super.setUp()
        mockRepo = MockExchangeRepository()
        useCase = GetExchangeListUseCase(repository: mockRepo)
    }

    func test_execute_returnsExchangesOnSuccess() async throws {
        // Given
        let expected = [
            Exchange(id: 1, name: "Binance", logo: "https://logo.com", slug: "binance",
                     description: nil, websiteURL: nil, makerFee: "0.1", takerFee: "0.1",
                     dateLaunched: nil, spotVolumeUSD: 1_000_000_000)
        ]
        mockRepo.stubbedExchanges = expected

        // When
        let result = try await useCase.execute()

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "Binance")
    }

    func test_execute_throwsOnFailure() async {
        // Given
        mockRepo.shouldFail = true

        // When / Then
        do {
            _ = try await useCase.execute()
            XCTFail("Expected to throw")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }

    func test_execute_returnsEmptyList() async throws {
        // Given
        mockRepo.stubbedExchanges = []

        // When
        let result = try await useCase.execute()

        // Then
        XCTAssertTrue(result.isEmpty)
    }
}

// MARK: - ViewModel Tests
@MainActor
final class ExchangeListViewModelTests: XCTestCase {
    var mockRepo: MockExchangeRepository!
    var viewModel: ExchangeListViewModel!

    override func setUp() {
        super.setUp()
        mockRepo = MockExchangeRepository()
        viewModel = ExchangeListViewModel(
            getExchangeList: GetExchangeListUseCase(repository: mockRepo)
        )
    }

    func test_initialState_isIdle() {
        if case .idle = viewModel.state { return }
        XCTFail("Expected idle state")
    }

    func test_loadExchanges_setsSuccessState() async {
        // Given
        mockRepo.stubbedExchanges = [
            Exchange(id: 1, name: "Coinbase", logo: "", slug: "coinbase",
                     description: nil, websiteURL: nil, makerFee: nil, takerFee: nil,
                     dateLaunched: nil, spotVolumeUSD: nil)
        ]

        // When
        await viewModel.loadExchanges()

        // Then
        if case .success(let exchanges) = viewModel.state {
            XCTAssertEqual(exchanges.count, 1)
        } else {
            XCTFail("Expected success state")
        }
    }

    func test_loadExchanges_setsErrorState_onFailure() async {
        // Given
        mockRepo.shouldFail = true

        // When
        await viewModel.loadExchanges()

        // Then
        if case .error(_) = viewModel.state { return }
        XCTFail("Expected error state")
    }

    func test_loadExchanges_setsEmptyState_whenResultIsEmpty() async {
        // Given
        mockRepo.stubbedExchanges = []

        // When
        await viewModel.loadExchanges()

        // Then
        if case .empty = viewModel.state { return }
        XCTFail("Expected empty state")
    }
}
