import Foundation

extension Double {
    /// Formata valor como moeda USD; ex: 1234567.89 → "$1,234,567.89"
    func formatAsUSD() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self)) ?? "$0.00"
    }

    /// Formata volume compacto; ex: 1_234_567_890 → "$1.23B"
    func formatAsCompactUSD() -> String {
        let absValue = abs(self)
        switch absValue {
        case 1_000_000_000...:
            return String(format: "$%.2fB", self / 1_000_000_000)
        case 1_000_000...:
            return String(format: "$%.2fM", self / 1_000_000)
        case 1_000...:
            return String(format: "$%.2fK", self / 1_000)
        default:
            return formatAsUSD()
        }
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
        out.locale = Locale(identifier: "pt_BR")
        return out.string(from: parsedDate).capitalized
    }

    /// Retorna string vazia como nil
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
