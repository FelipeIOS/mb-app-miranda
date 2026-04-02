import Foundation

// MARK: - Exchange Map (lista)
struct ExchangeMapResponse: Codable {
    let data: [ExchangeMapItem]
}

struct ExchangeMapItem: Codable {
    let id: Int
    let name: String
    let slug: String
}

// MARK: - Exchange Info (detalhes)
struct ExchangeInfoResponse: Codable {
    let data: [String: ExchangeInfoData]
}

struct ExchangeInfoData: Codable {
    let id: Int
    let name: String
    let slug: String
    let logo: String
    let description: String?
    let urls: ExchangeURLsData?
    /// A API envia números (ex.: `0.03`); decodificar como `Double` evita falha de decode.
    let makerFee: Double?
    let takerFee: Double?
    let dateLaunched: String?
    let spotVolumeUsd: Double?

    enum CodingKeys: String, CodingKey {
        case id, name, slug, logo, description, urls
        case makerFee     = "maker_fee"
        case takerFee     = "taker_fee"
        case dateLaunched = "date_launched"
        case spotVolumeUsd = "spot_volume_usd"
    }
}

struct ExchangeURLsData: Codable {
    let website: [String]?
}

// MARK: - Mapping → Domain
extension ExchangeInfoData {
    func toDomain() -> Exchange {
        Exchange(
            id: id,
            name: name,
            logo: logo,
            slug: slug,
            description: description,
            websiteURL: urls?.website?.first,
            makerFee: makerFee.map(Self.formatFeeForDisplay),
            takerFee: takerFee.map(Self.formatFeeForDisplay),
            dateLaunched: dateLaunched,
            spotVolumeUSD: spotVolumeUsd
        )
    }

    private static func formatFeeForDisplay(_ value: Double) -> String {
        String(format: "%g", value)
    }
}
