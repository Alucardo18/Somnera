import SwiftUI
import HealthKit

struct VitalityCrucibleView: View {
    let session: SleepSession?
    @State private var metrics: SynergyMetrics?
    
    // Nodos de energía rápidos
    @State private var energyNodes: [EnergyNode] = (0..<12).map { _ in EnergyNode() }
    
    var body: some View {
        VStack(spacing: 25) {
            // El Reactor de Fusión Gráfico (Alta Definición)
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let now = timeline.date.timeIntervalSinceReferenceDate
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    
                    // 1. Obtener Datos Reales
                    let synergy = Double(session?.snoreScore ?? 100) / 100.0
                    let o2 = (metrics?.spO2 ?? 1.0)
                    let hr = metrics?.heartRate ?? 60.0
                    let durationHours = (session?.duration ?? 28800) / 3600.0
                    
                    // Escala base según horas
                    let baseScale = min(1.2, max(0.5, durationHours / 8.0))
                    let pulse = sin(now * (hr / 60.0) * Double.pi * 2.0) * 4.0
                    let R = (50 * baseScale) + pulse
                    
                    // Colores de Alta Definición
                    let coreColor = synergy > 0.7 ? Color.somSafe : (synergy > 0.4 ? Color.somAccent : Color.red)
                    let plasmaColor = o2 > 0.94 ? Color.cyan : (o2 > 0.90 ? Color.somAccent : Color.orange)
                    
                    // 2. Aura de Fondo (Sutil, muy controlada)
                    context.addFilter(.blur(radius: 15))
                    context.fill(Path(ellipseIn: CGRect(x: center.x - R, y: center.y - R, width: R*2, height: R*2)), with: .color(coreColor.opacity(0.1)))
                    context.addFilter(.blur(radius: 0)) // Limpiar filtro para dibujo sharp
                    
                    // 3. Dibujar Líneas de Campo Magnético (Bucles Polares)
                    let fieldSpans = 5
                    let chaos = (1.0 - synergy) * 25.0
                    
                    for j in 0..<fieldSpans {
                        let expansion = 45.0 + sin(now * 3.0 + Double(j)) * (5.0 + chaos)
                        
                        var pLeft = Path()
                        pLeft.move(to: CGPoint(x: center.x, y: center.y - R))
                        pLeft.addCurve(
                            to: CGPoint(x: center.x, y: center.y + R),
                            control1: CGPoint(x: center.x - expansion, y: center.y - R/2),
                            control2: CGPoint(x: center.x - expansion, y: center.y + R/2)
                        )
                        
                        var pRight = Path()
                        pRight.move(to: CGPoint(x: center.x, y: center.y - R))
                        pRight.addCurve(
                            to: CGPoint(x: center.x, y: center.y + R),
                            control1: CGPoint(x: center.x + expansion, y: center.y - R/2),
                            control2: CGPoint(x: center.x + expansion, y: center.y + R/2)
                        )
                        
                        context.stroke(pLeft, with: .color(coreColor.opacity(0.12)), lineWidth: 1.0)
                        context.stroke(pRight, with: .color(coreColor.opacity(0.12)), lineWidth: 1.0)
                    }
                    
                    // 4. Anillos Orbitales Sólidos (Simulación de 3 Ejes Rotativos)
                    let axes = [
                        (angle: 0.0, a: 110.0, b: 35.0, color: plasmaColor),      // Ring Ecuatorial (O2)
                        (angle: Double.pi / 3.0, a: 95.0, b: 30.0, color: coreColor),  // Ring 1 (Sinergia)
                        (angle: -Double.pi / 3.0, a: 95.0, b: 30.0, color: .purple)    // Ring 2 (Respiración)
                    ]
                    
                    for (index, axis) in axes.enumerated() {
                        let path = Path { p in
                            for step in 0...100 {
                                let t = (Double(step) / 100.0) * 2.0 * Double.pi
                                let rx = axis.a * cos(t)
                                let ry = axis.b * sin(t)
                                
                                let x = center.x + rx * cos(axis.angle) - ry * sin(axis.angle)
                                let y = center.y + rx * sin(axis.angle) + ry * cos(axis.angle)
                                
                                if step == 0 { p.move(to: CGPoint(x: x, y: y)) }
                                else { p.addLine(to: CGPoint(x: x, y: y)) }
                            }
                        }
                        context.stroke(path, with: .color(axis.color.opacity(0.25)), lineWidth: 1.5)
                        
                        // 5. Nodos de Energía Rápidos
                        let node = energyNodes[index]
                        let tNode = node.baseOffset + (now * node.speed)
                        
                        let nx = center.x + axis.a * cos(tNode) * cos(axis.angle) - axis.b * sin(tNode) * sin(axis.angle)
                        let ny = center.y + axis.a * cos(tNode) * sin(axis.angle) + axis.b * sin(tNode) * cos(axis.angle)
                        
                        let size: CGFloat = 6.0
                        let rect = CGRect(x: nx - size/2, y: ny - size/2, width: size, height: size)
                        context.fill(Path(ellipseIn: rect), with: .color(.white))
                        context.stroke(Path(ellipseIn: rect.insetBy(dx: -2, dy: -2)), with: .color(axis.color), lineWidth: 1.5)
                    }
                    
                    // 6. Núcleo Sólido (Horizonte de Singularidad)
                    let coreRect = CGRect(x: center.x - R/2.5, y: center.y - R/2.5, width: (R/2.5)*2, height: (R/2.5)*2)
                    context.fill(Path(ellipseIn: coreRect), with: .color(.black))
                    context.stroke(Path(ellipseIn: coreRect), with: .color(.white.opacity(0.8)), lineWidth: 2.0)
                    
                    let activeRect = CGRect(x: center.x - R/4, y: center.y - R/4, width: (R/4)*2, height: (R/4)*2)
                    context.fill(Path(ellipseIn: activeRect), with: .color(coreColor))
                }
            }
            .frame(height: 280)
            .task {
                await fetchMetrics()
            }
            
            // IA Insight Card
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "bolt.shield.fill")
                        .foregroundColor(.somAccent)
                    Text("MONITOR DE FUSIÓN BIOMÉTRICA")
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
                    CrucibleBadge(label: "Estabilidad Fusión", value: "\(Int((session?.snoreScore ?? 100)))%", icon: "leaf.fill")
                    CrucibleBadge(label: "Saturación", value: metrics?.spO2 != nil ? "\(Int((metrics?.spO2 ?? 1.0) * 100))%" : "N/A", icon: "waveform.path.ecg")
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
    
    private func generateAISummary() -> String {
        guard let session = session else { return "Inicializando reactores..." }
        
        let snore = session.snoreScore
        let hours = session.duration / 3600.0
        let o2 = metrics?.spO2 ?? 1.0
        
        if snore > 90 && hours > 7 {
            return "Reactor estable. Las órbitas biométricas muestran una sincronía perfecta. Has alcanzado el nivel óptimo de consolidación celular y respiratoria."
        } else if o2 < 0.92 {
            return "Fluctuación en el núcleo. La caída del anillo de oxígeno ha inducido resistencia magnética, forzando un esfuerzo cardíaco compensatorio."
        } else if snore < 60 {
            return "Corte de contención. La inestabilidad respiratoria y la turbulencia acústica fragmentaron el flujo magnético de consolidación cerebral."
        } else {
            return "Reactor en equilibrio. La contención magnética es firme, aunque la energía acumulada sugiere que una órbita de sueño más larga habría completado la carga vital."
        }
    }
}

struct EnergyNode: Identifiable {
    let id = UUID()
    let baseOffset: Double = .random(in: 0...(Double.pi * 2))
    let speed: Double = .random(in: 1.5...3.0)
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
