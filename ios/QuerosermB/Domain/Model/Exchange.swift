import Foundation

// MARK: - Domain Models (Pure Swift — sem dependência de UIKit/SwiftUI)

struct Exchange: Identifiable, Equatable, Hashable {
    let id: Int
    let name: String
    let logo: String
    let slug: String
    let description: String?
    let websiteURL: String?
    let makerFee: Double?
    let takerFee: Double?
    let dateLaunched: String?
    let spotVolumeUSD: Double?
}

/// `id` é o `crypto_id` da CMC; na lista de assets da exchange pode repetir (mesma moeda, carteiras distintas).
struct Currency: Identifiable, Equatable {
    let id: Int
    let name: String
    let symbol: String
    let priceUSD: Double?
    let balance: Double?

    init(id: Int, name: String, symbol: String, priceUSD: Double?, balance: Double?) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.priceUSD = priceUSD
        self.balance = balance
    }
}
