import SwiftUI

// MARK: - App Colors
extension Color {
    // Primárias
    static let mbGold        = Color(hex: "#F7B500")
    static let mbPrimary     = Color(hex: "#1C1C2E")   // fundo principal dark
    static let mbSurface     = Color(hex: "#252540")   // cards/surface
    static let mbSurfaceAlt  = Color(hex: "#2E2E50")   // hover/alt surface
    static let mbAccent      = Color(hex: "#7C6FFF")   // roxo accent

    // Textos
    static let mbText        = Color(hex: "#F0F0FF")
    static let mbTextSub     = Color(hex: "#9090B0")
    static let mbTextMuted   = Color(hex: "#606080")

    // Semânticas
    static let mbSuccess     = Color(hex: "#2ECC71")
    static let mbError       = Color(hex: "#E74C3C")
    static let mbWarning     = Color(hex: "#F39C12")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >>  8) & 0xFF) / 255
        let b = Double((int      ) & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Typography
extension Font {
    static let mbLargeTitle  = Font.system(size: 28, weight: .bold,   design: .rounded)
    static let mbTitle       = Font.system(size: 20, weight: .bold,   design: .rounded)
    static let mbHeadline    = Font.system(size: 16, weight: .semibold, design: .rounded)
    static let mbBody        = Font.system(size: 14, weight: .regular, design: .rounded)
    static let mbCaption     = Font.system(size: 12, weight: .medium,  design: .rounded)
    static let mbMono        = Font.system(size: 13, weight: .medium,  design: .monospaced)
}
