import SwiftUI

struct NightHeatmapView: View {
    let session: SleepSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Análisis de la Noche")
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(.white)
                    .tracking(1)
                
                Spacer()
                
                Text(session.startDate.formatted(.dateTime.hour().minute()))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.somTextSecondary)
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 8))
                    .foregroundColor(.somTextSecondary)
                
                Text(session.endDate.formatted(.dateTime.hour().minute()))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.somTextSecondary)
            }
            
            ZStack {
                // Fondo oscuro para resaltar los neones
                Color.black.opacity(0.2)
                
                Canvas { context, size in
                    let samples = session.decibelTimeline
                    guard !samples.isEmpty else { return }
                    
                    let widthPerSample = size.width / CGFloat(samples.count)
                    
                    for (index, db) in samples.enumerated() {
                        // Escalamos el dB (0-90) al alto del gráfico (80)
                        let normalizedHeight = CGFloat(db) * (size.height / 90)
                        let barHeight = max(4, normalizedHeight) // Al menos 4px para que se vea
                        
                        let rect = CGRect(
                            x: CGFloat(index) * widthPerSample,
                            y: size.height - barHeight,
                            width: widthPerSample + 0.2,
                            height: barHeight
                        )
                        context.fill(Path(rect), with: .color(colorForDB(db)))
                    }
                }
            }
            .frame(height: 80)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            
            // Legend
            HStack(spacing: 12) {
                legendItem(label: "Silencio", color: .somSurfaceHigh.opacity(0.3))
                legendItem(label: "Leve", color: .somSafe)
                legendItem(label: "Ronquido", color: .somWarning)
                legendItem(label: "Intenso", color: .somApnea)
            }
        }
        .padding(20)
        .somGlassStyle(cornerRadius: 24)
    }
    
    private func heatmapCanvas(size: CGSize) -> some View {
        Canvas { context, size in
            let samples = session.decibelTimeline
            guard !samples.isEmpty else { return }
            
            let widthPerSample = size.width / CGFloat(samples.count)
            
            for (index, db) in samples.enumerated() {
                let rect = CGRect(
                    x: CGFloat(index) * widthPerSample,
                    y: 0,
                    width: widthPerSample + 0.5, // Small overlap to avoid gaps
                    height: size.height
                )
                
                context.fill(Path(rect), with: .color(colorForDB(db)))
            }
        }
    }
    
    private func legendItem(label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.somTextSecondary)
        }
    }
    
    private func colorForDB(_ db: Float) -> Color {
        // Our scale is 0 to 90 dB (approx)
        switch db {
        case ..<35:  return .cyan.opacity(0.4)           // Silencio (ahora más visible)
        case 35..<50: return .somSafe                    // Ruido leve
        case 50..<65: return .somWarning                 // Ronquido moderado
        default:      return .somApnea                   // Ronquido fuerte
        }
    }
}
#Preview {
    ZStack {
        Color.somBackground.ignoresSafeArea()
        NightHeatmapView(session: .mock)
            .padding()
    }
}
