import SwiftUI
import HealthKit

struct VitalityCrucibleView: View {
    let session: SleepSession?
    @State private var metrics: SynergyMetrics?
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 25) {
            // Biosfera de Homeostasis: Giroscopio 3D Vectorial (Ligero, Rápido y GPU-Acelerado)
            ZStack {
                // Resplandor de fondo sutil
                Circle()
                    .fill(Color.somAccent.opacity(0.03))
                    .frame(width: 180, height: 180)
                    .blur(radius: 25)
                
                // Órbita Ecuatorial (Eje Y) - Salud Respiratoria / Cian
                Circle()
                    .stroke(
                        LinearGradient(colors: [.cyan, .cyan.opacity(0.15)], startPoint: .top, endPoint: .bottom),
                        lineWidth: 1.5
                    )
                    .frame(width: 150, height: 150)
                    .rotation3DEffect(.degrees(isAnimating ? 360 : 0), axis: (x: 0, y: 1, z: 0))
                    .animation(.linear(duration: 6).repeatForever(autoreverses: false), value: isAnimating)
                
                // Órbita Polar (Eje X) - Sinergia de Sueño / Naranja
                Circle()
                    .stroke(
                        LinearGradient(colors: [.somAccent, .somAccent.opacity(0.15)], startPoint: .leading, endPoint: .trailing),
                        lineWidth: 1.5
                    )
                    .frame(width: 150, height: 150)
                    .rotation3DEffect(.degrees(isAnimating ? 360 : 0), axis: (x: 1, y: 0, z: 0))
                    .animation(.linear(duration: 9).repeatForever(autoreverses: false), value: isAnimating)
                
                // Órbita Diagonal (Eje Inclinado) - Ritmo Cardíaco / Púrpura
                Circle()
                    .stroke(
                        LinearGradient(colors: [.purple, .purple.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1.5
                    )
                    .frame(width: 150, height: 150)
                    .rotation3DEffect(.degrees(isAnimating ? -360 : 0), axis: (x: 1, y: 1, z: 0))
                    .animation(.linear(duration: 12).repeatForever(autoreverses: false), value: isAnimating)
                
                // Núcleo de Energía Pulsante (Homeostasis Activa)
                Circle()
                    .fill(Color.somAccent.gradient)
                    .frame(width: 28, height: 28)
                    .scaleEffect(isAnimating ? 1.15 : 0.85)
                    .shadow(color: .somAccent.opacity(0.5), radius: 12)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
            }
            .frame(height: 220)
            .onAppear {
                isAnimating = true
            }
            .task {
                await fetchMetrics()
            }
            
            // IA Insight Card
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "circle.hexagonpath")
                        .foregroundColor(.somAccent)
                    Text("ANÁLISIS DE HOMEOSTASIS 3D")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(2)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Text(generateAISummary())
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack {
                    CrucibleBadge(label: "Homeostasis", value: "\(Int(calculateHomeostasis()))%", icon: "circle.hexagonpath.fill")
                }
            }
            .padding(25)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.somSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
            )
            .padding(.horizontal)
        }
    }
    
    private func fetchMetrics() async {
        guard let session = session else { return }
        let snoreScore = Double(session.snoreScore)
        var m = SynergyMetrics(snoreScore: snoreScore)
        
        let start = session.startDate
        let end = session.endDate
        
        m.heartRate = try? await HealthKitService.shared.fetchAverageQuantity(for: .heartRate, start: start, end: end, unit: HKUnit(from: "count/min"))
        m.spO2 = try? await HealthKitService.shared.fetchAverageQuantity(for: .oxygenSaturation, start: start, end: end, unit: .percent())
        m.respiratoryRate = try? await HealthKitService.shared.fetchAverageQuantity(for: .respiratoryRate, start: start, end: end, unit: HKUnit(from: "count/min"))
        
        await MainActor.run {
            self.metrics = m
        }
    }
    
    private func calculateHomeostasis() -> Double {
        var totalWeight = 0.0
        var scoreAcc = 0.0
        
        // 1. Duración del Sueño (Siempre presente)
        let durationHours = (session?.duration ?? 28800) / 3600.0
        var durationScore = 0.0
        if durationHours >= 7.5 && durationHours <= 9.0 { durationScore = 100.0 }
        else if durationHours >= 6.0 { durationScore = 80.0 }
        else if durationHours >= 5.0 { durationScore = 50.0 }
        else { durationScore = 30.0 }
        
        scoreAcc += durationScore * 0.40
        totalWeight += 0.40
        
        // 2. Salud Acústica / Ronquido (Siempre presente)
        let snoreScore = Double(session?.snoreScore ?? 100)
        scoreAcc += snoreScore * 0.30
        totalWeight += 0.30
        
        // 3. Frecuencia Cardíaca (Opcional)
        if let hr = metrics?.heartRate {
            var hrScore = 0.0
            if hr >= 40 && hr <= 65 { hrScore = 100.0 }
            else if hr > 65 && hr <= 75 { hrScore = 75.0 }
            else { hrScore = 40.0 }
            scoreAcc += hrScore * 0.15
            totalWeight += 0.15
        }
        
        // 4. Oxigenación SpO2 (Opcional)
        if let spo2 = metrics?.spO2 {
            let val = spo2 > 1.0 ? spo2 : spo2 * 100.0
            var o2Score = 0.0
            if val >= 95 { o2Score = 100.0 }
            else if val >= 92 { o2Score = 60.0 }
            else { o2Score = 30.0 }
            scoreAcc += o2Score * 0.15
            totalWeight += 0.15
        }
        
        return totalWeight > 0 ? (scoreAcc / totalWeight) : snoreScore
    }
    
    private func generateAISummary() -> String {
        guard let session = session else { return "Mapeando geometría cuántica..." }
        
        let homeostasis = calculateHomeostasis()
        let o2 = metrics?.spO2 ?? 1.0
        let hours = session.duration / 3600.0
        
        if homeostasis > 90 {
            return "Biosfera en balance perfecto. La homeostasis del sueño se ha mantenido intacta, indicando una recuperación fisiológica óptima."
        } else if hours < 6.0 {
            return "Contracción esférica. La biosfera no alcanzó su diámetro máximo debido a una severa falta de horas de descanso (\(String(format: "%.1f", hours))h), generando una deuda de sueño."
        } else if o2 < 0.92 {
            return "El polo de la biosfera muestra distorsión térmica. La reducción sostenida de oxígeno ha generado estrés cardiovascular, alterando el equilibrio."
        } else if homeostasis < 70 {
            return "Biosfera fragmentada. La inestabilidad de los eventos respiratorios ha roto la contención simétrica, interrumpiendo el ciclo reparador."
        } else {
            return "Estabilidad fisiológica parcial. La biosfera mantiene su cohesión estructural, aunque la carga alostática sugiere que un ciclo extra de sueño optimizaría la homeostasis."
        }
    }
}

struct CrucibleBadge: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(.somAccent)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.4))
            Text(value)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Capsule().fill(Color.white.opacity(0.05)))
    }
}
