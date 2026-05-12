import SwiftUI

extension Color {
    // MARK: - Backgrounds
    static let somBackground   = Color(hex: "#0A0E1A")
    static let somSurface      = Color(hex: "#131929")
    static let somSurfaceHigh  = Color(hex: "#1C2540")

    // MARK: - Accent / Events
    static let somAccent       = Color(hex: "#7B6CF6")   // violeta — ronquido
    static let somApnea        = Color(hex: "#FF6B6B")   // rojo suave — apnea
    static let somSafe         = Color(hex: "#4ECDC4")   // teal — silencio normal
    static let somWarning      = Color(hex: "#FFD166")   // amarillo — alerta leve

    // MARK: - Text
    static let somTextPrimary  = Color(hex: "#F0F4FF")
    static let somTextSecondary = Color(hex: "#8892A4")

    // MARK: - Gradient
    static let somGradient     = LinearGradient(
        colors: [Color(hex: "#7B6CF6"), Color(hex: "#4A90D9")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let somRecordingGlow = LinearGradient(
        colors: [Color(hex: "#FF6B6B").opacity(0.8), Color(hex: "#FF6B6B").opacity(0.2)],
        startPoint: .top, endPoint: .bottom
    )
}

// MARK: - Hex initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch hex.count {
        case 6:
            (r, g, b, a) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
        case 8:
            (r, g, b, a) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (255, 255, 255, 255)
        }
        self.init(.sRGB,
                  red:   Double(r) / 255,
                  green: Double(g) / 255,
                  blue:  Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}
