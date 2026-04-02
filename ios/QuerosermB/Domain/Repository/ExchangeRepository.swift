import Foundation

protocol ExchangeRepository {
    func getExchangeList(start: Int, limit: Int) async throws -> [Exchange]
    func getExchangeDetail(id: Int) async throws -> Exchange
    func getExchangeAssets(id: Int) async throws -> [Currency]
}
