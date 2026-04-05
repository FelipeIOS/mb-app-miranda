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

// MARK: - Mock date provider
final class MockDateProvider: DateProviding {
    var now: Date = Date()
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
                     description: nil, websiteURL: nil, makerFee: 0.1, takerFee: 0.1,
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

// MARK: - ExchangeDetailCache Tests

final class ExchangeDetailCacheTests: XCTestCase {
    private func sampleExchange(id: Int) -> Exchange {
        Exchange(
            id: id,
            name: "E\(id)",
            logo: "",
            slug: "e\(id)",
            description: nil,
            websiteURL: nil,
            makerFee: nil,
            takerFee: nil,
            dateLaunched: nil,
            spotVolumeUSD: nil
        )
    }

    func test_get_whenEmpty_returnsNil() {
        let cache = ExchangeDetailCache()
        XCTAssertNil(cache.get(exchangeId: 1, ttl: 60))
    }

    func test_get_whenWithinTTL_returnsCachedEntry() {
        let cache = ExchangeDetailCache()
        let ex = sampleExchange(id: 1)
        cache.set(exchangeId: 1, detail: ex, assets: [])

        let got = cache.get(exchangeId: 1, ttl: 3600)
        XCTAssertEqual(got?.detail.id, 1)
        XCTAssertEqual(got?.assets.count, 0)
    }

    func test_get_whenExpiredTTL_returnsNilAndRemovesEntry() {
        let cache = ExchangeDetailCache()
        let ex = sampleExchange(id: 2)
        cache.set(exchangeId: 2, detail: ex, assets: [])

        XCTAssertNil(cache.get(exchangeId: 2, ttl: 0), "TTL 0 trata entrada como expirada")
        XCTAssertNil(cache.get(exchangeId: 2, ttl: 60), "Entrada expirada não permanece no storage")
    }

    func test_set_whenMaxEntriesExceeded_evictsOldestEntry() {
        let mockDate = MockDateProvider()
        let cache = ExchangeDetailCache(maxEntries: 2, dateProvider: mockDate)

        mockDate.now = Date(timeIntervalSince1970: 1000)
        cache.set(exchangeId: 1, detail: sampleExchange(id: 1), assets: [])

        mockDate.now = Date(timeIntervalSince1970: 2000)
        cache.set(exchangeId: 2, detail: sampleExchange(id: 2), assets: [])

        mockDate.now = Date(timeIntervalSince1970: 3000)
        cache.set(exchangeId: 3, detail: sampleExchange(id: 3), assets: [])

        XCTAssertNil(cache.get(exchangeId: 1, ttl: 3600), "ID 1 deve ser o mais antigo e removido")
        XCTAssertNotNil(cache.get(exchangeId: 2, ttl: 3600))
        XCTAssertNotNil(cache.get(exchangeId: 3, ttl: 3600))
    }
}

// MARK: - Get Exchange Detail / Assets UseCase Tests

final class GetExchangeDetailUseCaseTests: XCTestCase {
    func test_execute_returnsExchangeOnSuccess() async throws {
        let mock = MockExchangeRepository()
        let expected = Exchange(
            id: 99,
            name: "Z",
            logo: "https://z",
            slug: "z",
            description: nil,
            websiteURL: nil,
            makerFee: nil,
            takerFee: nil,
            dateLaunched: nil,
            spotVolumeUSD: 1
        )
        mock.stubbedExchanges = [expected]
        let useCase = GetExchangeDetailUseCase(repository: mock)

        let result = try await useCase.execute(id: 99)

        XCTAssertEqual(result.id, 99)
        XCTAssertEqual(result.name, "Z")
        XCTAssertEqual(mock.getExchangeDetailCallCount, 1)
    }

    func test_execute_propagatesErrorOnFailure() async {
        let mock = MockExchangeRepository()
        mock.shouldFail = true
        mock.stubbedExchanges = []
        let useCase = GetExchangeDetailUseCase(repository: mock)

        do {
            _ = try await useCase.execute(id: 1)
            XCTFail("Expected throw")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }
}

final class GetExchangeAssetsUseCaseTests: XCTestCase {
    func test_execute_returnsCurrenciesOnSuccess() async throws {
        let mock = MockExchangeRepository()
        let currencies = [
            Currency(id: 10, name: "BTC", symbol: "BTC", priceUSD: 50_000, balance: nil)
        ]
        mock.stubbedCurrencies = currencies
        let useCase = GetExchangeAssetsUseCase(repository: mock)

        let result = try await useCase.execute(id: 1)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, 10)
        XCTAssertEqual(mock.getExchangeAssetsCallCount, 1)
    }

    func test_execute_propagatesErrorOnFailure() async {
        let mock = MockExchangeRepository()
        mock.shouldFail = true
        let useCase = GetExchangeAssetsUseCase(repository: mock)

        do {
            _ = try await useCase.execute(id: 1)
            XCTFail("Expected throw")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }
}

// MARK: - DTO Decoding Tests

final class ExchangeDTODecodingTests: XCTestCase {
    func test_exchangeInfoResponse_fullJSON_mapsFeesAndVolume() throws {
        let json = """
        {"data":{"7":{"id":7,"name":"Binance","slug":"binance","logo":"https://logo","description":"Desc","urls":{"website":["https://binance.com"]},"maker_fee":0.03,"taker_fee":0.05,"date_launched":"2018-05-01T00:00:00.000Z","spot_volume_usd":1234567.89}}}
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let decoded = try JSONDecoder().decode(ExchangeInfoResponse.self, from: data)
        let info = try XCTUnwrap(decoded.data["7"])
        let domain = info.toDomain()

        XCTAssertEqual(domain.id, 7)
        XCTAssertEqual(domain.name, "Binance")
        XCTAssertEqual(domain.makerFee, 0.03)
        XCTAssertEqual(domain.takerFee, 0.05)
        XCTAssertEqual(domain.spotVolumeUSD, 1_234_567.89)
        XCTAssertEqual(domain.websiteURL, "https://binance.com")
    }

    func test_exchangeInfoResponse_minimalJSON_optionalsNil() throws {
        let json = """
        {"data":{"1":{"id":1,"name":"A","slug":"a","logo":"https://l"}}}
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let decoded = try JSONDecoder().decode(ExchangeInfoResponse.self, from: data)
        let info = try XCTUnwrap(decoded.data["1"])
        let domain = info.toDomain()

        XCTAssertNil(domain.description)
        XCTAssertNil(domain.websiteURL)
        XCTAssertNil(domain.makerFee)
        XCTAssertNil(domain.takerFee)
        XCTAssertNil(domain.dateLaunched)
        XCTAssertNil(domain.spotVolumeUSD)
    }
}

final class ExchangeAssetsDTODecodingTests: XCTestCase {
    func test_exchangeAssetsResponse_cryptoIdMapsToCurrencyId() throws {
        let json = """
        {"data":[{"currency":{"crypto_id":4242,"name":"Ether","symbol":"ETH","price_usd":2500.5},"balance":0.5,"wallet_address":"0xabc"}]}
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let decoded = try JSONDecoder().decode(ExchangeAssetsResponse.self, from: data)
        XCTAssertEqual(decoded.data.count, 1)
        let currency = try XCTUnwrap(decoded.data.first?.toDomain())
        XCTAssertEqual(currency.id, 4242)
        XCTAssertEqual(currency.name, "Ether")
        XCTAssertEqual(currency.priceUSD, 2500.5)
        XCTAssertEqual(currency.balance, 0.5)
    }
}

// MARK: - Formatters Tests

final class FormattersTests: XCTestCase {
    func test_formatAsCompactUSD_below1000_usesFullCurrency() {
        let s = Double(500).formatAsCompactUSD()
        XCTAssertTrue(s.hasPrefix("US$"), s)
        XCTAssertTrue(s.contains("500"), s)
    }

    func test_formatAsCompactUSD_thousands_appendsK() {
        let s = Double(1_500).formatAsCompactUSD()
        XCTAssertTrue(s.contains("K"), s)
    }

    func test_formatAsCompactUSD_millions_appendsM() {
        let s = Double(2_000_000).formatAsCompactUSD()
        XCTAssertTrue(s.contains("M"), s)
    }

    func test_formatAsCompactUSD_billions_appendsB() {
        let s = Double(3_000_000_000).formatAsCompactUSD()
        XCTAssertTrue(s.contains(" B"), s)
    }

    func test_formatAsMonthYear_iso8601_usesPortugueseLocale() {
        // Meio do dia UTC evita que 1º do mês vire o mês anterior no fuso local (ex.: BRT).
        let formatted = "2018-05-15T12:00:00.000Z".formatAsMonthYear()
        XCTAssertTrue(formatted.contains("2018"), formatted)
        XCTAssertTrue(formatted.lowercased().contains("mai"), formatted)
    }

    func test_formattedDecimal_groupsAndUsesCommaDecimalSeparator() {
        let s = Double(1234.567).formattedDecimal(minFractionDigits: 2, maxFractionDigits: 4)
        XCTAssertTrue(s.contains("1"), s)
        XCTAssertTrue(s.contains(","), s)
    }

    func test_nilIfEmpty_emptyString_returnsNil() {
        XCTAssertNil("".nilIfEmpty)
        XCTAssertEqual("x".nilIfEmpty, "x")
    }
}

// MARK: - Mock remote data source (repository integration)

final class MockExchangeRemoteDataSource: ExchangeRemoteDataSourcing {
    var mapItems: [ExchangeMapItem] = []
    /// `id` → info devolvido em `fetchExchangeInfo` quando o id aparece na string `ids`.
    var infoById: [Int: ExchangeInfoData] = [:]
    var assets: [ExchangeAssetItem] = []

    private(set) var fetchExchangeInfoCalls: [String] = []

    func fetchExchangeMap(start: Int, limit: Int) async throws -> [ExchangeMapItem] {
        mapItems
    }

    func fetchExchangeInfo(ids: String) async throws -> [ExchangeInfoData] {
        fetchExchangeInfoCalls.append(ids)
        let parts = ids.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.compactMap(Int.init)
        return parts.compactMap { infoById[$0] }
    }

    func fetchExchangeAssets(id: Int) async throws -> [ExchangeAssetItem] {
        assets
    }
}

private enum ExchangeTestFixtures {
    static func exchangeInfo(id: Int) -> ExchangeInfoData {
        ExchangeInfoData(
            id: id,
            name: "Name\(id)",
            slug: "slug-\(id)",
            logo: "https://example.com/\(id).png",
            description: nil,
            urls: nil,
            makerFee: nil,
            takerFee: nil,
            dateLaunched: nil,
            spotVolumeUsd: nil
        )
    }
}

// MARK: - ExchangeRepositoryImpl Tests

final class ExchangeRepositoryImplTests: XCTestCase {
    func test_getExchangeList_emptyMap_returnsEmptyPage() async throws {
        let mock = MockExchangeRemoteDataSource()
        mock.mapItems = []
        let repo = ExchangeRepositoryImpl(dataSource: mock)

        let page = try await repo.getExchangeList(start: 5, limit: 40)

        XCTAssertTrue(page.items.isEmpty)
        XCTAssertFalse(page.hasMore)
        XCTAssertEqual(page.nextStart, 5)
    }

    func test_getExchangeList_mergesMapAndInfo() async throws {
        let mock = MockExchangeRemoteDataSource()
        mock.mapItems = [
            ExchangeMapItem(id: 1, name: "A", slug: "a"),
            ExchangeMapItem(id: 2, name: "B", slug: "b")
        ]
        mock.infoById = [
            1: ExchangeTestFixtures.exchangeInfo(id: 1),
            2: ExchangeTestFixtures.exchangeInfo(id: 2)
        ]
        let repo = ExchangeRepositoryImpl(dataSource: mock)

        let page = try await repo.getExchangeList(start: 1, limit: 40)

        XCTAssertEqual(page.items.count, 2)
        XCTAssertEqual(page.items.map(\.id), [1, 2])
        XCTAssertFalse(page.hasMore)
        XCTAssertEqual(page.nextStart, 3)
    }

    func test_getExchangeList_hasMoreWhenPageIsFull() async throws {
        let mock = MockExchangeRemoteDataSource()
        mock.mapItems = (0 ..< 10).map { ExchangeMapItem(id: $0, name: "E\($0)", slug: "e\($0)") }
        mock.infoById = Dictionary(uniqueKeysWithValues: (0 ..< 10).map { ( $0, ExchangeTestFixtures.exchangeInfo(id: $0) ) })
        let repo = ExchangeRepositoryImpl(dataSource: mock)

        let page = try await repo.getExchangeList(start: 1, limit: 10)

        XCTAssertTrue(page.hasMore)
        XCTAssertEqual(page.items.count, 10)
    }

    func test_getExchangeList_batchesInfoWhenMoreThan100MapItems() async throws {
        let mock = MockExchangeRemoteDataSource()
        mock.mapItems = (1 ... 101).map { ExchangeMapItem(id: $0, name: "E\($0)", slug: "e\($0)") }
        mock.infoById = Dictionary(uniqueKeysWithValues: (1 ... 101).map { ( $0, ExchangeTestFixtures.exchangeInfo(id: $0) ) })
        let repo = ExchangeRepositoryImpl(dataSource: mock)

        let page = try await repo.getExchangeList(start: 1, limit: 200)

        XCTAssertEqual(mock.fetchExchangeInfoCalls.count, 2)
        XCTAssertEqual(mock.fetchExchangeInfoCalls[0].split(separator: ",").count, 100)
        XCTAssertEqual(mock.fetchExchangeInfoCalls[1], "101")
        XCTAssertEqual(page.items.count, 101)
    }

    func test_getExchangeDetail_throwsWhenInfoEmpty() async {
        let mock = MockExchangeRemoteDataSource()
        mock.infoById = [:]
        let repo = ExchangeRepositoryImpl(dataSource: mock)

        do {
            _ = try await repo.getExchangeDetail(id: 99)
            XCTFail("Expected throw")
        } catch let error as NetworkError {
            if case .invalidResponse = error { return }
            XCTFail("Wrong error \(error)")
        } catch {
            XCTFail("Wrong type \(error)")
        }
    }

    func test_getExchangeDetail_returnsDomain() async throws {
        let mock = MockExchangeRemoteDataSource()
        mock.infoById[7] = ExchangeTestFixtures.exchangeInfo(id: 7)
        let repo = ExchangeRepositoryImpl(dataSource: mock)

        let ex = try await repo.getExchangeDetail(id: 7)

        XCTAssertEqual(ex.id, 7)
        XCTAssertEqual(ex.name, "Name7")
    }

    func test_getExchangeAssets_mapsRows() async throws {
        let mock = MockExchangeRemoteDataSource()
        let currency = AssetCurrencyData(id: 5, name: "BTC", symbol: "BTC", priceUsd: 10)
        mock.assets = [
            ExchangeAssetItem(currency: currency, balance: 2, walletAddress: nil)
        ]
        let repo = ExchangeRepositoryImpl(dataSource: mock)

        let rows = try await repo.getExchangeAssets(id: 1)

        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].id, 5)
        XCTAssertEqual(rows[0].balance, 2)
    }
}

// MARK: - APIEndpoint Tests

final class APIEndpointTests: XCTestCase {
    func test_exchangeMap_buildsURLWithStartAndLimit() throws {
        let req = try APIEndpoint.exchangeMap(start: 41, limit: 40).buildURLRequest(apiKey: "KEY")
        let url = try XCTUnwrap(req.url)
        XCTAssertEqual(url.path, "/v1/exchange/map")
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        XCTAssertEqual(items.first { $0.name == "start" }?.value, "41")
        XCTAssertEqual(items.first { $0.name == "limit" }?.value, "40")
        XCTAssertEqual(req.value(forHTTPHeaderField: "X-CMC_PRO_API_KEY"), "KEY")
        XCTAssertEqual(req.value(forHTTPHeaderField: "Accept"), "application/json")
    }

    func test_exchangeInfo_buildsIdQuery() throws {
        let req = try APIEndpoint.exchangeInfo(ids: "1,2,3").buildURLRequest(apiKey: "K")
        let url = try XCTUnwrap(req.url)
        XCTAssertEqual(url.path, "/v1/exchange/info")
        let q = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        XCTAssertEqual(q.first { $0.name == "id" }?.value, "1,2,3")
    }

    func test_exchangeAssets_buildsIdQuery() throws {
        let req = try APIEndpoint.exchangeAssets(id: 42).buildURLRequest(apiKey: "K")
        let url = try XCTUnwrap(req.url)
        XCTAssertEqual(url.path, "/v1/exchange/assets")
        let q = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        XCTAssertEqual(q.first { $0.name == "id" }?.value, "42")
    }
}

// MARK: - NetworkError Tests

final class NetworkErrorLocalizedTests: XCTestCase {
    func test_errorDescriptions_nonEmpty() {
        let cases: [NetworkError] = [
            .invalidURL,
            .invalidResponse,
            .serverError(statusCode: 500),
            .decodingError(NSError(domain: "t", code: 1)),
            .noConnection,
            .unknown(NSError(domain: "u", code: 2))
        ]
        for err in cases {
            let desc = err.errorDescription ?? ""
            XCTAssertFalse(desc.isEmpty, "\(err)")
        }
    }
}

// MARK: - APIClient Tests (URLProtocol)

private enum MockURLProtocolResult {
    case http(HTTPURLResponse, Data)
    case fail(Error)
}

private final class MockURLProtocol: URLProtocol {
    static var result: MockURLProtocolResult?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let result = Self.result else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        switch result {
        case .http(let response, let data):
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        case .fail(let error):
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

final class APIClientTests: XCTestCase {
    override func tearDown() {
        super.tearDown()
        MockURLProtocol.result = nil
    }

    private func makeClient() -> APIClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        return APIClient(apiKey: "test-key", session: session)
    }

    func test_request_decodes200() async throws {
        let json = #"{"data":[]}"#.data(using: .utf8)!
        let response = HTTPURLResponse(
            url: URL(string: "https://pro-api.coinmarketcap.com/v1/exchange/map")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        MockURLProtocol.result = .http(response, json)

        let client = makeClient()
        let decoded: ExchangeMapResponse = try await client.request(.exchangeMap(start: 1, limit: 1))

        XCTAssertTrue(decoded.data.isEmpty)
    }

    func test_request_serverError_mapsToNetworkError() async {
        let response = HTTPURLResponse(
            url: URL(string: "https://x")!,
            statusCode: 503,
            httpVersion: nil,
            headerFields: nil
        )!
        MockURLProtocol.result = .http(response, Data())

        let client = makeClient()

        do {
            let _: ExchangeMapResponse = try await client.request(.exchangeMap(start: 1, limit: 1))
            XCTFail("Expected throw")
        } catch let e as NetworkError {
            if case .serverError(let code) = e {
                XCTAssertEqual(code, 503)
            } else {
                XCTFail("Wrong case \(e)")
            }
        } catch {
            XCTFail("\(error)")
        }
    }

    func test_request_invalidJSON_mapsToDecodingError() async {
        let response = HTTPURLResponse(
            url: URL(string: "https://x")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        MockURLProtocol.result = .http(response, Data("{".utf8))

        let client = makeClient()

        do {
            let _: ExchangeMapResponse = try await client.request(.exchangeMap(start: 1, limit: 1))
            XCTFail("Expected throw")
        } catch let e as NetworkError {
            if case .decodingError = e { return }
            XCTFail("Wrong case \(e)")
        } catch {
            XCTFail("\(error)")
        }
    }

    func test_request_noConnection_mapsToNetworkError() async {
        MockURLProtocol.result = .fail(URLError(.notConnectedToInternet))

        let client = makeClient()

        do {
            let _: ExchangeMapResponse = try await client.request(.exchangeMap(start: 1, limit: 1))
            XCTFail("Expected throw")
        } catch let e as NetworkError {
            if case .noConnection = e { return }
            XCTFail("Wrong case \(e)")
        } catch {
            XCTFail("\(error)")
        }
    }
}
