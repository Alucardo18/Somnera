import SwiftUI

/// A professional 3D-styled visualization of the human airway with dynamic blueprint callouts.
struct AirwayDigitalTwinView: View {
    var nasalIntensity: Double = 0.2
    var palatalIntensity: Double = 0.8
    var lingualIntensity: Double = 0.4
    
    @State private var animate = false
    @State private var showDisclaimer = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            
            ZStack {
                // Background Callout Lines (Blueprint effect)
                CalloutLinesShape(
                    nasalIntensity: nasalIntensity,
                    palatalIntensity: palatalIntensity,
                    lingualIntensity: lingualIntensity
                )
                .stroke(
                    LinearGradient(
                        colors: [.somAccent.opacity(0.1), .somAccent.opacity(0.3), .somAccent.opacity(0.1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 0.5, dash: [2, 4])
                )
                .opacity(animate ? 1 : 0.5)
                
                HStack(alignment: .center, spacing: 0) {
                    // Left Metrics
                    VStack(alignment: .leading, spacing: 22) {
                        legendRow(label: "Nasal", intensity: nasalIntensity, color: .somSafe, description: "Vía Superior")
                        legendRow(label: "Palatal", intensity: palatalIntensity, color: .somAccent, description: "Obstrucción Media")
                        legendRow(label: "Lingual", intensity: lingualIntensity, color: .somApnea, description: "Base Garganta")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Right 3D Model
                    ZStack {
                        // Shadow glow for the model
                        Circle()
                            .fill(currentCriticalColor.opacity(0.1))
                            .frame(width: 150, height: 150)
                            .blur(radius: 30)
                        
                        Image("digital_twin_3d")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 140, height: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                            )
                        
                        // Hotspots on the image
                        Group {
                            hotspot(at: CGPoint(x: 48, y: 62), intensity: nasalIntensity, color: .somSafe)
                            hotspot(at: CGPoint(x: 60, y: 72), intensity: palatalIntensity, color: .somAccent)
                            hotspot(at: CGPoint(x: 62, y: 92), intensity: lingualIntensity, color: .somApnea)
                        }
                        .frame(width: 140, height: 140)
                    }
                    .frame(width: 150)
                }
            }
            
            footer
        }
        .padding(20)
        .somGlassStyle(cornerRadius: 24)
        .alert("Información Médica", isPresented: $showDisclaimer) {
            Button("Entendido", role: .cancel) { }
        } message: {
            Text("Esta es una representación visual estimada mediante modelos matemáticos y análisis de frecuencia acústica (FFT). Somnera no es un dispositivo médico y esta información no sustituye un estudio de sueño clínico (Polisomnografía) ni un diagnóstico médico profesional.")
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
    
    // MARK: - Subviews
    
    private var header: some View {
        HStack {
            Image(systemName: "view.3d")
                .foregroundColor(.somAccent)
            Text("Digital Twin: Análisis 3D")
                .font(.system(size: 14, weight: .black))
                .foregroundColor(.white)
                .tracking(1)
            Spacer()
            
            HStack(spacing: 8) {
                Text("VISUAL REPRESENTATION")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.somTextSecondary.opacity(0.8))
                
                Button {
                    showDisclaimer = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12))
                        .foregroundColor(.somAccent)
                }
            }
        }
    }
    
    private var footer: some View {
        Text("Basado en el análisis espectral de frecuencia (FFT) de la última sesión.")
            .font(.system(size: 8))
            .foregroundColor(.somTextSecondary.opacity(0.6))
            .padding(.top, 4)
    }
    
    private var currentCriticalColor: Color {
        if lingualIntensity > 0.6 { return .somApnea }
        if palatalIntensity > 0.6 { return .somAccent }
        return .somSafe
    }
    
    private func hotspot(at position: CGPoint, intensity: Double, color: Color) -> some View {
        ZStack {
            // Pulse
            Circle()
                .stroke(color.opacity(0.3), lineWidth: 1)
                .frame(width: 24, height: 24)
                .scaleEffect(animate ? 1.5 : 1.0)
                .opacity(animate ? 0 : 0.8)
            
            // Fixed glow
            Circle()
                .fill(color.opacity(intensity * 0.4))
                .frame(width: 12, height: 12)
                .blur(radius: 4)
            
            // Center
            Circle()
                .fill(color)
                .frame(width: 4, height: 4)
                .shadow(color: color, radius: 2)
        }
        .position(position)
    }
    
    private func legendRow(label: String, intensity: Double, color: Color, description: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text("\(Int(intensity * 100))%")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundColor(color)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.somSurfaceHigh.opacity(0.4))
                        .frame(height: 4)
                    
                    Capsule()
                        .fill(color.gradient)
                        .frame(width: geo.size.width * CGFloat(intensity), height: 4)
                }
            }
            .frame(height: 4)
        }
        .frame(maxWidth: 120) // Limit width to leave space for callouts
    }
}

// MARK: - Shapes

struct CalloutLinesShape: Shape {
    var nasalIntensity: Double
    var palatalIntensity: Double
    var lingualIntensity: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let leftX = rect.width * 0.35 // Start of lines (from labels)
        let rightX = rect.width * 0.73 // End of lines (to hotspots)
        
        // Horizontal centers of the rows (approx based on VStack spacing)
        let yNasal = rect.height * 0.22
        let yPalatal = rect.height * 0.48
        let yLingual = rect.height * 0.74
        
        // Hotspot Y offsets (relative to center)
        let hNasalY = rect.height * 0.42
        let hPalatalY = rect.height * 0.52
        let hLingualY = rect.height * 0.65
        
        // Draw Nasal Line
        drawLine(path: &path, start: CGPoint(x: leftX, y: yNasal), end: CGPoint(x: rightX, y: hNasalY))
        
        // Draw Palatal Line
        drawLine(path: &path, start: CGPoint(x: leftX, y: yPalatal), end: CGPoint(x: rightX, y: hPalatalY))
        
        // Draw Lingual Line
        drawLine(path: &path, start: CGPoint(x: leftX, y: yLingual), end: CGPoint(x: rightX, y: hLingualY))
        
        return path
    }
    
    private func drawLine(path: inout Path, start: CGPoint, end: CGPoint) {
        path.move(to: start)
        // Elbow line for technical feel
        let midX = start.x + (end.x - start.x) * 0.5
        path.addLine(to: CGPoint(x: midX, y: start.y))
        path.addLine(to: end)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.somBackground.ignoresSafeArea()
        AirwayDigitalTwinView(
            nasalIntensity: 0.15,
            palatalIntensity: 0.85,
            lingualIntensity: 0.45
        )
        .padding()
    }
}
