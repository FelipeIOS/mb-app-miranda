import Foundation

/// Abstrai o data source remoto para testes do `ExchangeRepositoryImpl` sem rede.
protocol ExchangeRemoteDataSourcing: AnyObject {
    func fetchExchangeMap(start: Int, limit: Int) async throws -> [ExchangeMapItem]
    func fetchExchangeInfo(ids: String) async throws -> [ExchangeInfoData]
    func fetchExchangeAssets(id: Int) async throws -> [ExchangeAssetItem]
}

final class ExchangeRemoteDataSource: ExchangeRemoteDataSourcing {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchExchangeMap(start: Int, limit: Int) async throws -> [ExchangeMapItem] {
        let response: ExchangeMapResponse = try await client.request(
            .exchangeMap(start: start, limit: limit)
        )
        return response.data
    }

    func fetchExchangeInfo(ids: String) async throws -> [ExchangeInfoData] {
        let response: ExchangeInfoResponse = try await client.request(
            .exchangeInfo(ids: ids)
        )
        return Array(response.data.values)
    }

    func fetchExchangeAssets(id: Int) async throws -> [ExchangeAssetItem] {
        let response: ExchangeAssetsResponse = try await client.request(
            .exchangeAssets(id: id)
        )
        return response.data
    }
}
