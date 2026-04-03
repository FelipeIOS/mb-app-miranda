import Foundation

extension Double {
    private static let usdCurrencyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.locale = Locale(identifier: "pt_BR")
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 12
        f.roundingMode = .halfEven
        return f
    }()

    private static let compactScaledFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "pt_BR")
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 6
        f.roundingMode = .halfEven
        return f
    }()

    /// Preço em USD (ex.: `price_usd` da API). Mantém casas decimais necessárias (até 12), sem forçar só 2 casas.
    func formatAsUSD() -> String {
        Self.usdCurrencyFormatter.string(from: NSNumber(value: self)) ?? String(self)
    }

    /// Volume em USD compacto (lista / cards). Escala B/M/K com mais casas que o antigo `%.2f`.
    func formatAsCompactUSD() -> String {
        let absValue = abs(self)
        let scaled: Double
        let suffix: String
        switch absValue {
        case 1_000_000_000_000...:
            scaled = self / 1_000_000_000_000
            suffix = " T"
        case 1_000_000_000...:
            scaled = self / 1_000_000_000
            suffix = " B"
        case 1_000_000...:
            scaled = self / 1_000_000
            suffix = " M"
        case 1_000...:
            scaled = self / 1_000
            suffix = " K"
        default:
            return formatAsUSD()
        }
        let numberPart = Self.compactScaledFormatter.string(from: NSNumber(value: scaled)) ?? String(scaled)
        return "US$ \(numberPart)\(suffix)"
    }

    /// Taxas e valores decimais vindos da API (ex. `maker_fee`) sem usar `%g`, que pode arredondar.
    func formattedDecimal(minFractionDigits: Int = 2, maxFractionDigits: Int = 12) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale.current
        f.minimumFractionDigits = minFractionDigits
        f.maximumFractionDigits = maxFractionDigits
        f.roundingMode = .halfEven
        f.usesGroupingSeparator = true
        return f.string(from: NSNumber(value: self)) ?? String(self)
    }
}

extension String {
    /// Converte string ISO8601 em data legível; ex: "2013-01-01T00:00:00.000Z" → "Jan 2013"
    func formatAsMonthYear() -> String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var date: Date?
        date = iso.date(from: self)

        if date == nil {
            let fallback = DateFormatter()
            fallback.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            date = fallback.date(from: self)
        }

        guard let parsedDate = date else { return self }

        let out = DateFormatter()
        out.dateFormat = "MMM yyyy"
        out.locale = Locale.current
        return out.string(from: parsedDate).capitalized
    }

    /// Retorna string vazia como nil
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
