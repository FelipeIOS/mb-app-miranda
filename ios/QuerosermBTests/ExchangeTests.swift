import XCTest
@testable import QuerosermB

// MARK: - Mock Repository
final class MockExchangeRepository: ExchangeRepository {
    var shouldFail = false
    /// Página devolvida quando `pageHandler` é `nil`.
    var stubbedPage = ExchangeListPage(items: [], hasMore: false, nextStart: 1)
    var stubbedExchanges: [Exchange] = []
    var stubbedCurrencies: [Currency] = []

    /// Se definido, substitui `stubbedPage` (útil para simular várias páginas por `start`).
    var pageHandler: ((Int, Int) throws -> ExchangeListPage)?

    private(set) var getExchangeListCallCount = 0
    private(set) var getExchangeDetailCallCount = 0
    private(set) var getExchangeAssetsCallCount = 0

    func getExchangeList(start: Int, limit: Int) async throws -> ExchangeListPage {
        getExchangeListCallCount += 1
        if shouldFail { throw NetworkError.serverError(statusCode: 500) }
        if let pageHandler {
            return try pageHandler(start, limit)
        }
        return stubbedPage
    }

    func getExchangeDetail(id: Int) async throws -> Exchange {
        getExchangeDetailCallCount += 1
        if shouldFail { throw NetworkError.serverError(statusCode: 500) }
        guard let exchange = stubbedExchanges.first(where: { $0.id == id }) else {
            throw NetworkError.invalidResponse
        }
        return exchange
    }

    func getExchangeAssets(id: Int) async throws -> [Currency] {
        getExchangeAssetsCallCount += 1
        if shouldFail { throw NetworkError.serverError(statusCode: 500) }
        return stubbedCurrencies
    }
}

// MARK: - Mock detail cache
final class MockExchangeDetailCache: ExchangeDetailCaching {
    var stub: CachedExchangeDetail?

    func get(exchangeId: Int, ttl: TimeInterval) -> CachedExchangeDetail? {
        guard let s = stub, s.detail.id == exchangeId else { return nil }
        return s
    }

    func set(exchangeId: Int, detail: Exchange, assets: [Currency]) {
        stub = CachedExchangeDetail(detail: detail, assets: assets, fetchedAt: Date())
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
        mockRepo.stubbedPage = ExchangeListPage(items: expected, hasMore: false, nextStart: 2)

        // When
        let result = try await useCase.execute()

        // Then
        XCTAssertEqual(result.items.count, 1)
        XCTAssertEqual(result.items.first?.name, "Binance")
        XCTAssertFalse(result.hasMore)
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
        mockRepo.stubbedPage = ExchangeListPage(items: [], hasMore: false, nextStart: 1)

        // When
        let result = try await useCase.execute()

        // Then
        XCTAssertTrue(result.items.isEmpty)
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
        let items = [
            Exchange(id: 1, name: "Coinbase", logo: "", slug: "coinbase",
                     description: nil, websiteURL: nil, makerFee: nil, takerFee: nil,
                     dateLaunched: nil, spotVolumeUSD: nil)
        ]
        mockRepo.stubbedPage = ExchangeListPage(items: items, hasMore: false, nextStart: 2)

        // When
        await viewModel.loadExchanges()

        // Then
        if case .success(let exchanges) = viewModel.state {
            XCTAssertEqual(exchanges.count, 1)
        } else {
            XCTFail("Expected success state")
        }
    }

    func test_loadMore_appendsSecondPage() async {
        let first = Exchange(id: 1, name: "A", logo: "", slug: "a",
                             description: nil, websiteURL: nil, makerFee: nil, takerFee: nil,
                             dateLaunched: nil, spotVolumeUSD: nil)
        let second = Exchange(id: 2, name: "B", logo: "", slug: "b",
                              description: nil, websiteURL: nil, makerFee: nil, takerFee: nil,
                              dateLaunched: nil, spotVolumeUSD: nil)

        mockRepo.pageHandler = { start, _ in
            if start == 1 {
                return ExchangeListPage(items: [first], hasMore: true, nextStart: 41)
            }
            if start == 41 {
                return ExchangeListPage(items: [second], hasMore: false, nextStart: 42)
            }
            return ExchangeListPage(items: [], hasMore: false, nextStart: start)
        }

        let vm = ExchangeListViewModel(
            getExchangeList: GetExchangeListUseCase(repository: mockRepo),
            pageSize: 40
        )

        await vm.loadExchanges()

        guard case .success(let afterFirst) = vm.state else {
            return XCTFail("Expected success after first page")
        }
        XCTAssertEqual(afterFirst.count, 1)

        await vm.loadMore()

        guard case .success(let merged) = vm.state else {
            return XCTFail("Expected success after load more")
        }
        XCTAssertEqual(merged.count, 2)
        XCTAssertEqual(merged.map(\.id), [1, 2])
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
        mockRepo.stubbedPage = ExchangeListPage(items: [], hasMore: false, nextStart: 1)

        // When
        await viewModel.loadExchanges()

        // Then
        if case .empty = viewModel.state { return }
        XCTFail("Expected empty state")
    }

    func test_loadInitialListIfNeeded_afterSuccess_doesNotCallRepositoryAgain() async {
        let items = [
            Exchange(id: 1, name: "Coinbase", logo: "", slug: "coinbase",
                     description: nil, websiteURL: nil, makerFee: nil, takerFee: nil,
                     dateLaunched: nil, spotVolumeUSD: nil)
        ]
        mockRepo.stubbedPage = ExchangeListPage(items: items, hasMore: false, nextStart: 2)

        await viewModel.loadExchanges()
        XCTAssertEqual(mockRepo.getExchangeListCallCount, 1)

        await viewModel.loadInitialListIfNeeded()
        XCTAssertEqual(mockRepo.getExchangeListCallCount, 1, "Segunda carga inicial não deve ir à rede")
    }
}

// MARK: - ExchangeDetailViewModel Tests
@MainActor
final class ExchangeDetailViewModelTests: XCTestCase {
    var mockRepo: MockExchangeRepository!
    var cache: MockExchangeDetailCache!

    override func setUp() {
        super.setUp()
        mockRepo = MockExchangeRepository()
        cache = MockExchangeDetailCache()
    }

    func test_load_usesCache_skipsRepository() async {
        let exchange = Exchange(id: 7, name: "X", logo: "", slug: "x",
                                  description: "d", websiteURL: nil, makerFee: nil, takerFee: nil,
                                  dateLaunched: nil, spotVolumeUSD: 1)
        cache.stub = CachedExchangeDetail(
            detail: exchange,
            assets: [],
            fetchedAt: Date()
        )
        mockRepo.stubbedExchanges = [exchange]

        let vm = ExchangeDetailViewModel(
            getExchangeDetail: GetExchangeDetailUseCase(repository: mockRepo),
            getExchangeAssets: GetExchangeAssetsUseCase(repository: mockRepo),
            detailCache: cache
        )

        await vm.load(exchange: exchange)

        XCTAssertEqual(mockRepo.getExchangeDetailCallCount, 0)
        XCTAssertEqual(mockRepo.getExchangeAssetsCallCount, 0)
        if case .success(let d) = vm.detailState {
            XCTAssertEqual(d.id, 7)
        } else {
            XCTFail("Expected detail success from cache")
        }
        if case .empty = vm.assetsState {} else {
            XCTFail("Expected empty assets from cache")
        }
    }

    func test_load_withoutCache_callsRepository() async {
        let exchange = Exchange(id: 8, name: "Y", logo: "", slug: "y",
                                  description: "d", websiteURL: "https://y.com", makerFee: nil, takerFee: nil,
                                  dateLaunched: nil, spotVolumeUSD: 2)
        mockRepo.stubbedExchanges = [exchange]
        mockRepo.stubbedCurrencies = [
            Currency(id: 1, name: "BTC", symbol: "BTC", priceUSD: 1, balance: nil)
        ]
        cache.stub = nil

        let vm = ExchangeDetailViewModel(
            getExchangeDetail: GetExchangeDetailUseCase(repository: mockRepo),
            getExchangeAssets: GetExchangeAssetsUseCase(repository: mockRepo),
            detailCache: cache
        )

        await vm.load(exchange: exchange)

        XCTAssertEqual(mockRepo.getExchangeDetailCallCount, 1)
        XCTAssertEqual(mockRepo.getExchangeAssetsCallCount, 1)
        if case .success = vm.detailState {} else { XCTFail("Expected detail success") }
        if case .success(let assets) = vm.assetsState {
            XCTAssertEqual(assets.count, 1)
        } else {
            XCTFail("Expected assets success")
        }
    }
}
