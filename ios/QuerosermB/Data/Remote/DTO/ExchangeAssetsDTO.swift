import Foundation

// MARK: - Exchange Assets Response
struct ExchangeAssetsResponse: Codable {
    let data: [ExchangeAssetItem]
}

struct ExchangeAssetItem: Codable {
    let currency: AssetCurrencyData
    let balance: Double?
    let walletAddress: String?

    enum CodingKeys: String, CodingKey {
        case currency
        case balance
        case walletAddress = "wallet_address"
    }
}

struct AssetCurrencyData: Codable {
    let id: Int
    let name: String
    let symbol: String
    let priceUsd: Double?

    enum CodingKeys: String, CodingKey {
        case id = "crypto_id"
        case name, symbol
        case priceUsd = "price_usd"
    }
}

// MARK: - Mapping → Domain
extension ExchangeAssetItem {
    func toDomain() -> Currency {
        Currency(
            id: currency.id,
            name: currency.name,
            symbol: currency.symbol,
            priceUSD: currency.priceUsd,
            balance: balance
        )
    }
}
