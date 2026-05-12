import SwiftUI

enum Theme {
    // MARK: - Colors
    static let background   = Color(hex: "#0B0B0B")
    static let surface      = Color(hex: "#141414")
    static let surfaceHigh  = Color(hex: "#1C1C1E")
    static let accent       = Color(hex: "#4CAF72")   // muted green
    static let gold         = Color(hex: "#C9A84C")
    static let textPrimary  = Color(hex: "#F5F5F5")
    static let textSecondary = Color(hex: "#8E8E93")
    static let textTertiary = Color(hex: "#48484A")
    static let separator    = Color(hex: "#2C2C2E")
    static let danger       = Color(hex: "#FF453A")
    static let warning      = Color(hex: "#FF9F0A")

    // MARK: - Workout type colors
    static let bjjColor      = Color(hex: "#4CAF72")
    static let strengthColor = Color(hex: "#C9A84C")
    static let restColor     = Color(hex: "#48484A")

    // MARK: - Gradients
    static let accentGradient = LinearGradient(
        colors: [Color(hex: "#4CAF72"), Color(hex: "#2D8B52")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let goldGradient = LinearGradient(
        colors: [Color(hex: "#C9A84C"), Color(hex: "#A07830")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let darkGradient = LinearGradient(
        colors: [Color(hex: "#1C1C1E"), Color(hex: "#0B0B0B")],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - Shadows
    static let cardShadow = Color.black.opacity(0.4)

    // MARK: - Corner radii
    static let radiusSmall:  CGFloat = 8
    static let radiusMedium: CGFloat = 14
    static let radiusLarge:  CGFloat = 20
    static let radiusXL:     CGFloat = 28

    // MARK: - Spacing
    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 16
    static let spacingLG: CGFloat = 24
    static let spacingXL: CGFloat = 32
}

// MARK: - Color hex init
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Text styles
extension Font {
    static let displayLarge  = Font.system(size: 40, weight: .black, design: .default)
    static let displayMedium = Font.system(size: 32, weight: .bold,  design: .default)
    static let titleLarge    = Font.system(size: 24, weight: .bold,  design: .default)
    static let titleMedium   = Font.system(size: 18, weight: .semibold, design: .default)
    static let bodyLarge     = Font.system(size: 16, weight: .regular, design: .default)
    static let bodyMedium    = Font.system(size: 14, weight: .regular, design: .default)
    static let labelLarge    = Font.system(size: 13, weight: .semibold, design: .default)
    static let labelSmall    = Font.system(size: 11, weight: .medium,   design: .default)
    static let caption       = Font.system(size: 11, weight: .regular,  design: .default)
}
