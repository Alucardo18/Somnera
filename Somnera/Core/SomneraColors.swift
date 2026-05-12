import SwiftUI

extension Color {
    // MARK: - Backgrounds
    static let somBackground   = Color(hex: "#0A0E1A")
    static let somSurface      = Color(hex: "#131929")
    static let somSurfaceHigh  = Color(hex: "#1C2540")

    // MARK: - Accent / Events
    static let somAccent       = Color(hex: "#8E7DFF")   // violeta neón
    static let somApnea        = Color(hex: "#FF4D4D")   // rojo vibrante
    static let somSafe         = Color(hex: "#00F5FF")   // cian neón
    static let somWarning      = Color(hex: "#FFD166")   // amarillo oro
    static let somInfo         = Color(hex: "#20A4F3")   // azul información

    // MARK: - Text
    static let somTextPrimary  = Color(hex: "#F0F4FF")
    static let somTextSecondary = Color(hex: "#8892A4")

    // MARK: - Mesh Background
    static let somMesh1        = Color(hex: "#0F172A")
    static let somMesh2        = Color(hex: "#1E293B")
    static let somMesh3        = Color(hex: "#312E81")

    // MARK: - Gradient
    static let somGradient     = LinearGradient(
        colors: [Color(hex: "#8E7DFF"), Color(hex: "#00F5FF")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

// MARK: - Premium UI Modifiers
struct SomGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.3), .clear, .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func somGlassStyle(cornerRadius: CGFloat = 20) -> some View {
        self.modifier(SomGlassModifier(cornerRadius: cornerRadius))
    }
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
