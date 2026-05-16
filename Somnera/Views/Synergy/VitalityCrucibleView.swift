import SwiftUI
import HealthKit

struct VitalityCrucibleView: View {
    let session: SleepSession?
    @State private var metrics: SynergyMetrics?
    
    @State private var particles: [CrucibleParticle] = (0..<150).map { _ in CrucibleParticle() }
    
    var body: some View {
        VStack(spacing: 25) {
            // El Crisol Gráfico
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let now = timeline.date.timeIntervalSinceReferenceDate
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    
                    // 1. Calcular Parámetros Biométricos
                    let synergy = Double(session?.snoreScore ?? 100) / 100.0
                    let o2 = (metrics?.spO2 ?? 1.0)
                    let hr = metrics?.heartRate ?? 60.0
                    let durationHours = (session?.duration ?? 28800) / 3600.0
                    
                    // Escala base según duración (8h = 1.0)
                    let baseScale = min(1.2, max(0.4, durationHours / 8.0))
                    let pulse = sin(now * (hr / 60.0) * .pi) * 5.0
                    let coreRadius = (80 * baseScale) + pulse
                    
                    // 2. Dibujar Resplandor de Fondo (Aura)
                    let auraColor = synergy > 0.7 ? Color.somSafe : (synergy > 0.4 ? Color.somAccent : Color.red)
                    context.addFilter(.blur(radius: 30))
                    context.fill(Path(ellipseIn: CGRect(x: center.x - coreRadius, y: center.y - coreRadius, width: coreRadius*2, height: coreRadius*2)), with: .color(auraColor.opacity(0.15)))
                    
                    // 3. Dibujar Partículas del Crisol
                    context.addFilter(.blur(radius: 0))
                    for i in 0..<particles.count {
                        let p = particles[i]
                        
                        // Movimiento Orbital
                        let angle = p.baseAngle + (now * p.speed * synergy)
                        let chaos = (1.0 - synergy) * 40.0
                        let individualRadius = coreRadius + p.orbitOffset + (sin(now * 2 + Double(i)) * chaos)
                        
                        let px = center.x + cos(angle) * individualRadius
                        let py = center.y + sin(angle) * individualRadius
                        
                        // Color basado en Oxígeno
                        let pColor = o2 > 0.94 ? Color.cyan : (o2 > 0.90 ? Color.somAccent : Color.orange)
                        let pOpacity = (cos(angle + now) + 1.0) / 2.0
                        
                        let rect = CGRect(x: px, y: py, width: p.size, height: p.size)
                        context.fill(Path(ellipseIn: rect), with: .color(pColor.opacity(pOpacity * 0.8)))
                        
                        // Líneas de Sinergia (Conectan partículas si la salud es alta)
                        if synergy > 0.8 && i % 15 == 0 {
                            let nextIndex = (i + 1) % particles.count
                            let nextP = particles[nextIndex]
                            let nAngle = nextP.baseAngle + (now * nextP.speed * synergy)
                            let nx = center.x + cos(nAngle) * coreRadius
                            let ny = center.y + sin(nAngle) * coreRadius
                            
                            var path = Path()
                            path.move(to: CGPoint(x: px, y: py))
                            path.addLine(to: CGPoint(x: nx, y: ny))
                            context.stroke(path, with: .color(pColor.opacity(0.1)), lineWidth: 0.5)
                        }
                    }
                    
                    // 4. El Núcleo de Consciencia
                    let innerRect = CGRect(x: center.x - 10, y: center.y - 10, width: 20, height: 20)
                    context.addFilter(.blur(radius: 5))
                    context.fill(Path(ellipseIn: innerRect), with: .color(.white.opacity(0.8)))
                }
            }
            .frame(height: 280)
            .task {
                await fetchMetrics()
            }
            
            // IA Insight Card
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.somAccent)
                    Text("ORÁCULO DE VITALIDAD")
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
                    CrucibleBadge(label: "Regeneración", value: "\(Int((session?.snoreScore ?? 100)))%", icon: "leaf.fill")
                    CrucibleBadge(label: "Estabilidad", value: metrics?.spO2 != nil ? "Alta" : "N/A", icon: "waveform.path.ecg")
                }
            }
            .padding(25)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.white.opacity(0.03))
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
    
    private func generateAISummary() -> String {
        guard let session = session else { return "Analizando hilos de consciencia..." }
        
        let snore = session.snoreScore
        let hours = session.duration / 3600.0
        let o2 = metrics?.spO2 ?? 1.0
        
        if snore > 90 && hours > 7 {
            return "Tu núcleo vital está expandido y radiante. Has logrado una noche de regeneración profunda con una arquitectura de sueño impecable."
        } else if o2 < 0.92 {
            return "El Crisol muestra turbulencia cromática. La baja saturación de oxígeno ha forzado a tu corazón a latir fuera de su ritmo de reposo."
        } else if snore < 60 {
            return "Tu núcleo está fragmentado. La intensidad acústica de los ronquidos ha impedido que las partículas de memoria se estabilicen correctamente."
        } else {
            return "Tu vitalidad se mantiene estable, aunque el volumen del Crisol sugiere que un ciclo extra de sueño habría completado la restauración celular."
        }
    }
}

struct CrucibleParticle: Identifiable {
    let id = UUID()
    let baseAngle: Double = .random(in: 0...(.pi * 2))
    let orbitOffset: CGFloat = .random(in: -20...20)
    let speed: Double = .random(in: 0.2...0.8)
    let size: CGFloat = .random(in: 1...3)
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
