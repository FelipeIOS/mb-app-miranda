import UIKit

// MARK: - Colors

extension UIColor {
    static let mbPrimary    = UIColor(hex: "#1C1C2E")
    static let mbSurface    = UIColor(hex: "#252540")
    static let mbSurfaceAlt = UIColor(hex: "#2E2E50")
    static let mbGold       = UIColor(hex: "#F7B500")
    static let mbAccent     = UIColor(hex: "#7C6FFF")
    static let mbText       = UIColor(hex: "#F0F0FF")
    static let mbTextSub    = UIColor(hex: "#9090B0")
    static let mbTextMuted  = UIColor(hex: "#606080")
    static let mbSuccess    = UIColor(hex: "#2ECC71")
    static let mbError      = UIColor(hex: "#E74C3C")
    static let mbWarning    = UIColor(hex: "#F39C12")

    convenience init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s = String(s.dropFirst()) }
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        self.init(
            red:   CGFloat((rgb & 0xFF0000) >> 16) / 255,
            green: CGFloat((rgb & 0x00FF00) >> 8)  / 255,
            blue:  CGFloat(rgb & 0x0000FF)          / 255,
            alpha: 1
        )
    }
}

// MARK: - Typography

extension UIFont {
    static func mbLargeTitle() -> UIFont { .systemFont(ofSize: 28, weight: .bold) }
    static func mbTitle()      -> UIFont { .systemFont(ofSize: 20, weight: .bold) }
    static func mbHeadline()   -> UIFont { .systemFont(ofSize: 16, weight: .semibold) }
    static func mbBody()       -> UIFont { .systemFont(ofSize: 14, weight: .regular) }
    static func mbCaption()    -> UIFont { .systemFont(ofSize: 12, weight: .medium) }
    static func mbMono()       -> UIFont { .monospacedSystemFont(ofSize: 13, weight: .medium) }
}
