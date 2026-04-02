import Foundation

// MARK: - Domain Models (Pure Swift — sem dependência de UIKit/SwiftUI)

struct Exchange: Identifiable, Equatable {
    let id: Int
    let name: String
    let logo: String
    let slug: String
    let description: String?
    let websiteURL: String?
    let makerFee: String?
    let takerFee: String?
    let dateLaunched: String?
    let spotVolumeUSD: Double?
}

struct Currency: Identifiable, Equatable {
    let id: UUID
    let name: String
    let symbol: String
    let priceUSD: Double?
    let balance: Double?

    init(name: String, symbol: String, priceUSD: Double?, balance: Double?) {
        self.id = UUID()
        self.name = name
        self.symbol = symbol
        self.priceUSD = priceUSD
        self.balance = balance
    }
}
