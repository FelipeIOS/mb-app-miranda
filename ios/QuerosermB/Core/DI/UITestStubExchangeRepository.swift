import Foundation

#if DEBUG
/// Repositório fixo usado só com `launchArguments: ["-UITesting"]` para XCUITest determinístico.
/// Compilado apenas em builds Debug — nunca incluído em Release.
final class UITestStubExchangeRepository: ExchangeRepository {
    private let alpha = Exchange(
        id: 1,
        name: "Alpha Exchange",
        logo: "",
        slug: "alpha",
        description: "Descrição Alpha",
        websiteURL: "https://alpha.example",
        makerFee: 0.1,
        takerFee: 0.2,
        dateLaunched: "2018-01-15T12:00:00.000Z",
        spotVolumeUSD: 1_000_000
    )

    private let beta = Exchange(
        id: 2,
        name: "Beta Exchange",
        logo: "",
        slug: "beta",
        description: "Descrição Beta",
        websiteURL: nil,
        makerFee: nil,
        takerFee: nil,
        dateLaunched: nil,
        spotVolumeUSD: 2_000_000
    )

    private var all: [Exchange] { [alpha, beta] }

    func getExchangeList(start: Int, limit: Int) async throws -> ExchangeListPage {
        ExchangeListPage(items: all, hasMore: false, nextStart: start + all.count)
    }

    func getExchangeDetail(id: Int) async throws -> Exchange {
        guard let ex = all.first(where: { $0.id == id }) else {
            throw NetworkError.invalidResponse
        }
        return ex
    }

    func getExchangeAssets(id: Int) async throws -> [Currency] {
        [
            Currency(id: 100, name: "Bitcoin", symbol: "BTC", priceUSD: 50_000, balance: nil)
        ]
    }
}
#endif
