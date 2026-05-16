import SwiftUI
import HealthKit

struct VitalityCrucibleView: View {
    let session: SleepSession?
    @State private var metrics: SynergyMetrics?
    
    // Lista de partículas pre-calculadas en 3D
    @State private var baseParticles: [Particle3D] = []
    
    var body: some View {
        VStack(spacing: 25) {
            // Biosfera de Homeostasis: Esfera Holográfica 3D (Alta Precisión)
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let now = timeline.date.timeIntervalSinceReferenceDate
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    
                    // 1. Cargar datos reales
                    let synergy = Double(session?.snoreScore ?? 100) / 100.0
                    let o2 = (metrics?.spO2 ?? 1.0)
                    let hr = metrics?.heartRate ?? 60.0
                    let durationHours = (session?.duration ?? 28800) / 3600.0
                    
                    // Escala base por duración y pulso
                    let baseScale = min(1.2, max(0.5, durationHours / 8.0))
                    let pulse = sin(now * (hr / 60.0) * Double.pi * 2.0) * 4.0
                    let sphereRadius = (70.0 * baseScale) + pulse
                    
                    // Frecuencia de onda según respiración
                    let waveFreq = 4.0 + (metrics?.respiratoryRate ?? 15.0) / 5.0
                    let waveAmp = (1.0 - synergy) * 0.2
                    
                    // Ángulos de rotación continua
                    let rotY = now * 0.4
                    let rotX = sin(now * 0.1) * 0.2
                    
                    // 2. Transformar, Deformar y Proyectar Partículas
                    var projected: [ProjectedParticle] = baseParticles.map { p in
                        let lat = asin(p.y)
                        let ripple = sin(lat * waveFreq + now * 3.0) * waveAmp
                        let r = 1.0 + ripple
                        
                        let px = p.x * r
                        let py = p.y * r
                        let pz = p.z * r
                        
                        let x1 = px * cos(rotY) - pz * sin(rotY)
                        let z1 = px * sin(rotY) + pz * cos(rotY)
                        
                        let y1 = py * cos(rotX) - z1 * sin(rotX)
                        let z2 = py * sin(rotX) + z1 * cos(rotX)
                        
                        let d = 2.5
                        let scaleFactor = d / (d + z2)
                        
                        let screenX = center.x + CGFloat(x1 * sphereRadius * scaleFactor)
                        let screenY = center.y + CGFloat(y1 * sphereRadius * scaleFactor)
                        
                        return ProjectedParticle(
                            x: screenX,
                            y: screenY,
                            z: z2,
                            scale: scaleFactor,
                            colorIndex: p.colorIndex
                        )
                    }
                    
                    // 3. Z-Sorting
                    projected.sort { $0.z > $1.z }
                    
                    // 4. Dibujar
                    for p in projected {
                        let baseColor = o2 > 0.94 ? Color.cyan : (o2 > 0.90 ? Color.somAccent : Color.orange)
                        let opacity = max(0.15, min(0.9, (1.2 - p.z) / 2.0))
                        let size = max(1.5, min(5.0, 3.5 * p.scale))
                        
                        let rect = CGRect(x: p.x - size/2, y: p.y - size/2, width: size, height: size)
                        context.fill(Path(ellipseIn: rect), with: .color(baseColor.opacity(opacity)))
                        
                        if synergy > 0.75 && p.z < -0.2 && p.colorIndex % 12 == 0 {
                            let glowRect = rect.insetBy(dx: -1.5, dy: -1.5)
                            context.stroke(Path(ellipseIn: glowRect), with: .color(.white.opacity(0.3)), lineWidth: 0.5)
                        }
                    }
                }
            }
            .frame(height: 280)
            .task {
                generateBaseParticles()
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
    
    private func generateBaseParticles() {
        var temp: [Particle3D] = []
        let N = 200
        let goldenRatio = (1.0 + sqrt(5.0)) / 2.0
        
        for i in 0..<N {
            let y = 1.0 - (Double(i) / Double(N - 1)) * 2.0
            let radius = sqrt(1.0 - y * y)
            let theta = 2.0 * Double.pi * Double(i) / goldenRatio
            
            let x = cos(theta) * radius
            let z = sin(theta) * radius
            
            temp.append(Particle3D(x: x, y: y, z: z, colorIndex: i))
        }
        self.baseParticles = temp
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
        
        // 1. Duración del Sueño (Siempre presente, penalización estricta)
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
            if hr >= 40 && hr <= 65 { hrScore = 100.0 } // Reposo profundo
            else if hr > 65 && hr <= 75 { hrScore = 75.0 }
            else { hrScore = 40.0 }
            scoreAcc += hrScore * 0.15
            totalWeight += 0.15
        }
        
        // 4. Oxigenación SpO2 (Opcional, penalización severa por hipoxia)
        if let spo2 = metrics?.spO2 {
            let val = spo2 > 1.0 ? spo2 : spo2 * 100.0
            var o2Score = 0.0
            if val >= 95 { o2Score = 100.0 }
            else if val >= 92 { o2Score = 60.0 }
            else { o2Score = 30.0 }
            scoreAcc += o2Score * 0.15
            totalWeight += 0.15
        }
        
        // Cálculo adaptativo basado en sensores disponibles
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

struct Particle3D {
    let x: Double
    let y: Double
    let z: Double
    let colorIndex: Int
}

struct ProjectedParticle {
    let x: CGFloat
    let y: CGFloat
    let z: Double
    let scale: Double
    let colorIndex: Int
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
