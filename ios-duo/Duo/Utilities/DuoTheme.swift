import SwiftUI

/// Design tokens for the strict, matte-black premium studio look.
enum DuoTheme {
    static let canvas = Color(hex: 0x0C0C0D)
    static let surface = Color(hex: 0x151517)
    static let surfaceSecondary = Color(hex: 0x1E1E21)
    static let textPrimary = Color(hex: 0xF4F2EE)
    static let textSecondary = Color(hex: 0x8A8A90)
    static let hairline = Color(hex: 0x2A2A2E)
    static let accent = Color(hex: 0xC9B58A)
    static let record = Color(hex: 0xB3261E)

    static let hairlineWidth: CGFloat = 1
    static let cornerRadius: CGFloat = 10
}

extension Color {
    /// Creates an opaque color from a 24-bit RGB hex value.
    nonisolated init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }
}

extension InstrumentFamily {
    /// Muted, desaturated track shade for regions and headers.
    var tint: Color {
        switch self {
        case .drums: Color(hex: 0x7C8594)
        case .bass: Color(hex: 0x5F7391)
        case .guitar: Color(hex: 0xA8956A)
        case .keys: Color(hex: 0x6F8C7C)
        case .brass: Color(hex: 0x8B6E86)
        }
    }

    var symbol: String {
        switch self {
        case .guitar: "guitars"
        case .bass: "guitars.fill"
        case .drums: "circle.hexagongrid"
        case .keys: "pianokeys"
        case .brass: "music.note"
        }
    }
}
