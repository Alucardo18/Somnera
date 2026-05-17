import SwiftUI
import HealthKit

// Estructuras de datos 3D compartidas y eficientes
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
    let scale: CGFloat
    let colorIndex: Int
}

struct VitalityCrucibleView: View {
    let session: SleepSession?
    @State private var metrics: SynergyMetrics?
    @State private var particles: [Particle3D] = []
    
    var body: some View {
        VStack(spacing: 25) {
            // Biosfera de Homeostasis: Esfera de Partículas 3D Dinámica
            VStack(spacing: 15) {
                TimelineView(.animation) { timeline in
                    Canvas { context, size in
                        let now = timeline.date.timeIntervalSinceReferenceDate
                        let center = CGPoint(x: size.width / 2, y: size.height / 2)
                        
                        let baseRadius = 65.0
                        let pulse = sin(now * 3.0) * 1.5
                        let sphereRadius = baseRadius + pulse
                        
                        // Rotación constante
                        let rotY = now * 0.4
                        let rotX = sin(now * 0.2) * 0.3
                        
                        let cosY = cos(rotY)
                        let sinY = sin(rotY)
                        let cosX = cos(rotX)
                        let sinX = sin(rotX)
                        
                        var projected: [ProjectedParticle] = particles.map { p in
                            let x1 = p.x * cosY - p.z * sinY
                            let z1 = p.x * sinY + p.z * cosY
                            
                            let y1 = p.y * cosX - z1 * sinX
                            let z2 = p.y * sinX + z1 * cosX
                            
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
                        
                        projected.sort { $0.z > $1.z }
                        
                        for p in projected {
                            let isFront = p.z < 0
                            let opacity = max(0.15, min(0.9, (1.2 - p.z) / 2.0))
                            let size = max(2.0, min(6.5, 4.0 * p.scale))
                            
                            // COLORES DINÁMICOS BASADOS EN VARIABLES BIOMÉTRICAS REALES:
                            var color: Color = .cyan
                            
                            if p.colorIndex % 3 == 0 {
                                // 1. Partículas de Oxigenación (Cian) -> Rojo si hay hipoxia
                                if let spo2 = metrics?.spO2 {
                                    let val = spo2 > 1.0 ? spo2 : spo2 * 100.0
                                    color = val >= 92 ? .cyan : .red
                                } else {
                                    color = .cyan
                                }
                            } else if p.colorIndex % 3 == 1 {
                                // 2. Partículas de Silencio (Naranja) -> Rojo si roncó mucho
                                let snore = Double(session?.snoreScore ?? 100)
                                color = snore >= 75 ? .somAccent : .red.opacity(0.8)
                            } else {
                                // 3. Partículas de Pulso (Púrpura) -> Rojo/Magenta si hay taquicardia o estrés
                                if let hr = metrics?.heartRate {
                                    color = hr <= 75 ? .purple : Color(red: 1.0, green: 0.2, blue: 0.6)
                                } else {
                                    color = .purple
                                }
                            }
                            
                            let rect = CGRect(x: p.x - size/2, y: p.y - size/2, width: size, height: size)
                            context.fill(Path(ellipseIn: rect), with: .color(color.opacity(opacity)))
                            
                            if isFront && p.colorIndex % 5 == 0 {
                                let glowRect = rect.insetBy(dx: -2.0, dy: -2.0)
                                context.fill(Path(ellipseIn: glowRect), with: .color(color.opacity(opacity * 0.3)))
                            }
                        }
                    }
                }
                .frame(height: 200)
                
                // Leyenda Biométrica: Indica qué variable controla cada color de la Biosfera
                HStack(spacing: 20) {
                    LegendItem(color: metrics?.spO2 != nil && (metrics?.spO2 ?? 1.0) * 100 < 92 ? .red : .cyan, label: "SpO2 (Oxígeno)")
                    LegendItem(color: Double(session?.snoreScore ?? 100) >= 75 ? .somAccent : .red, label: "Silencio")
                    LegendItem(color: metrics?.heartRate != nil && (metrics?.heartRate ?? 60) > 75 ? Color(red: 1.0, green: 0.2, blue: 0.6) : .purple, label: "Pulso")
                }
                .padding(.top, -10)
            }
            .onAppear {
                generateParticles()
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
                
                // Puntuación de Homeostasis con Clasificación Médica Clara y Semáforo de Estado
                HStack(spacing: 10) {
                    CrucibleBadge(
                        label: "Homeostasis",
                        value: "\(Int(calculateHomeostasis()))%",
                        icon: "circle.hexagonpath.fill",
                        statusColor: getHomeostasisStatus().color
                    )
                    
                    // Etiqueta Médica de Diagnóstico
                    Text(getHomeostasisStatus().text)
                        .font(.system(size: 10, weight: .black))
                        .tracking(2)
                        .foregroundColor(.somBackground)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(getHomeostasisStatus().color)
                        .cornerRadius(8)
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
    
    private func generateParticles() {
        var temp: [Particle3D] = []
        let N = 45
        let goldenRatio = (1.0 + sqrt(5.0)) / 2.0
        
        for i in 0..<N {
            let y = 1.0 - (Double(i) / Double(N - 1)) * 2.0
            let radius = sqrt(1.0 - y * y)
            let theta = 2.0 * Double.pi * Double(i) / goldenRatio
            
            let x = cos(theta) * radius
            let z = sin(theta) * radius
            
            temp.append(Particle3D(x: x, y: y, z: z, colorIndex: i))
        }
        self.particles = temp
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
    
    private func getHomeostasisStatus() -> (text: String, color: Color) {
        let score = calculateHomeostasis()
        if score >= 90 { return ("ÓPTIMA", .somSafe) }
        if score >= 75 { return ("ADECUADA", .somAccent) }
        return ("COMPROMETIDA", .red)
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

// Leyenda Biométrica Auxiliar
struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

struct CrucibleBadge: View {
    let label: String
    let value: String
    let icon: String
    var statusColor: Color = .somAccent
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(statusColor)
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
