import Foundation

final class ExchangeRepositoryImpl: ExchangeRepository {
    private let dataSource: ExchangeRemoteDataSource

    init(dataSource: ExchangeRemoteDataSource) {
        self.dataSource = dataSource
    }

    // MARK: - Lista de exchanges (map + info em batch)
    func getExchangeList(start: Int, limit: Int) async throws -> [Exchange] {
        // 1. Busca o mapa (id + name + slug)
        let mapItems = try await dataSource.fetchExchangeMap(start: start, limit: limit)
        guard !mapItems.isEmpty else { return [] }

        // 2. Busca detalhes em batch com até 100 IDs por vez
        let ids = mapItems.prefix(100).map { "\($0.id)" }.joined(separator: ",")
        let infoItems = try await dataSource.fetchExchangeInfo(ids: ids)

        // 3. Mapeia preservando a ordem original do mapa
        let infoDict = Dictionary(uniqueKeysWithValues: infoItems.map { ($0.id, $0) })
        return mapItems.compactMap { mapItem in
            infoDict[mapItem.id]?.toDomain()
        }
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
