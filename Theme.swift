import SwiftUI

struct Theme {
    // Simplified Solid Palette
    static let primaryTeal = Color(hex: "3D8D7A")
    static let lightGreen = Color(hex: "B3D8A8")
    static let softTeal = Color(hex: "A3D1C6")
    static let coral = Color(hex: "FF7777")
    static let softPink = Color(hex: "FFAAAA")
    static let vibrantRed = Color(hex: "FF5555")
    static let deepOrange = Color(hex: "FF3F33")
    static let amber = Color(hex: "FFC107")
    static let burntOrange = Color(hex: "EC5228")
    
    // Backgrounds
    static let pureWhite = Color.white
    static let offWhite = Color(hex: "F8F9FA")

    // Use solid colors instead of gradients for simplification
    static let primaryAccent = primaryTeal
    static let successAccent = lightGreen
    static let warningAccent = amber
    static let dangerAccent = vibrantRed
    
    // Deprecated Gradients - Redirected to solid colors
    static var primaryGradient: Color { primaryAccent }
    static var successGradient: Color { successAccent }
    static var warningGradient: Color { warningAccent }
    static var dangerGradient: Color { dangerAccent }
    static var tertiaryGradient: Color { softTeal }
    
    // Glassmorphism and Card Styles
    static var glassBackground: some View {
        #if os(macOS)
        return VisualEffectView(material: .contentBackground, blendingMode: .withinWindow)
            .background(Color.white.opacity(0.5))
        #else
        return Color.white.opacity(0.7).background(.ultraThinMaterial)
        #endif
    }

    static let cardShadow = Color.black.opacity(0.04)
    static let cardBorder = Color.black.opacity(0.06)
    
    // Typography Spacing
    static let cardCornerRadius: CGFloat = 24
    static let standardPadding: CGFloat = 20
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#if os(macOS)
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
#endif
