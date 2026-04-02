import Foundation

final class ExchangeRepositoryImpl: ExchangeRepository {
    private let dataSource: ExchangeRemoteDataSource

    init(dataSource: ExchangeRemoteDataSource) {
        self.dataSource = dataSource
    }

    private static let maxIdsPerInfoRequest = 100

    // MARK: - Lista de exchanges (map + info em batch)
    func getExchangeList(start: Int, limit: Int) async throws -> ExchangeListPage {
        let mapItems = try await dataSource.fetchExchangeMap(start: start, limit: limit)
        guard !mapItems.isEmpty else {
            return ExchangeListPage(items: [], hasMore: false, nextStart: start)
        }

        var allInfo: [ExchangeInfoData] = []
        var offset = 0
        while offset < mapItems.count {
            let end = min(offset + Self.maxIdsPerInfoRequest, mapItems.count)
            let chunk = Array(mapItems[offset..<end])
            let ids = chunk.map { "\($0.id)" }.joined(separator: ",")
            let batch = try await dataSource.fetchExchangeInfo(ids: ids)
            allInfo.append(contentsOf: batch)
            offset = end
        }

        let infoDict = Dictionary(uniqueKeysWithValues: allInfo.map { ($0.id, $0) })
        let exchanges = mapItems.compactMap { mapItem in
            infoDict[mapItem.id]?.toDomain()
        }

        let hasMore = mapItems.count == limit
        let nextStart = start + mapItems.count
        return ExchangeListPage(items: exchanges, hasMore: hasMore, nextStart: nextStart)
    }

    // MARK: - Detalhes de uma exchange
    func getExchangeDetail(id: Int) async throws -> Exchange {
        let infoItems = try await dataSource.fetchExchangeInfo(ids: "\(id)")
        guard let info = infoItems.first else {
            throw NetworkError.invalidResponse
        }
        return info.toDomain()
    }

    // MARK: - Assets (moedas) de uma exchange
    func getExchangeAssets(id: Int) async throws -> [Currency] {
        let assets = try await dataSource.fetchExchangeAssets(id: id)
        return assets.map { $0.toDomain() }
    }
}
