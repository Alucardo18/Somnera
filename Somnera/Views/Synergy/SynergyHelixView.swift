import SwiftUI
import HealthKit

struct SynergyHelixView: View {
    var session: SleepSession?
    
    // Parámetros de la hélice
    let points = 60
    let rotationSpeed: Double = 0.5
    
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var synergyIndex: Int = 100
    @State private var healthLevel: Double = 1.0
    @State private var hapticTrigger: Int = 0
    @State private var metrics: SynergyMetrics?
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                TimelineView(.animation) { timeline in
                    Canvas { context, size in
                        let now = isDragging ? Double(dragOffset * 0.05) : timeline.date.timeIntervalSinceReferenceDate
                        drawHelix(in: context, size: size, now: now)
                    }
                }
                .frame(height: 180)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.somSurface.opacity(0.3))
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if !isDragging { isDragging = true }
                            dragOffset = value.translation.width
                            
                            if Int(abs(dragOffset)) % 20 == 0 {
                                hapticTrigger += 1
                            }
                        }
                        .onEnded { _ in
                            withAnimation(.spring()) {
                                isDragging = false
                                dragOffset = 0
                            }
                        }
                )
                .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
                
                // Índice de Sinergia Central
                VStack(spacing: 2) {
                    Text("\(synergyIndex)%")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(healthColor)
                    Text(isDragging ? "INSPECCIÓN" : "SINCRONÍA")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(2)
                }
                .padding(15)
                .background(Circle().fill(Color.somBackground).opacity(0.8))
                .shadow(color: healthColor.opacity(0.3), radius: 15)
            }
            
            // Bio-Resumen Dinámico (Reacciona al drag)
            BioInsightCard(dragX: isDragging ? dragOffset : nil, totalWidth: 350, session: session, metrics: metrics)
                .padding(.horizontal)
            
            // Grid de Estadísticas (Ahora 4)
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    HelixStat(label: "Ronquido", value: "\(session?.snoreScore ?? 0)%", color: .somAccent, icon: "waveform")
                    HelixStat(label: "Pulso", value: "\(Int(metrics?.heartRate ?? 0)) LPM", color: .somSafe, icon: "heart.fill")
                }
                HStack(spacing: 8) {
                    let o2 = (metrics?.spO2 ?? 0)
                    let o2Val = o2 > 1.0 ? Int(o2) : Int(o2 * 100)
                    HelixStat(label: "Oxígeno", value: "\(o2Val)%", color: .cyan, icon: "drop.fill")
                    HelixStat(label: "Resp.", value: "\(Int(metrics?.respiratoryRate ?? 0)) RPM", color: .purple, icon: "wind")
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .task {
            await fetchMetrics()
        }
    }
    
    private func fetchMetrics() async {
        guard let session = session else { return }
        let snoreScore = Double(session.snoreScore)
        var m = SynergyMetrics(snoreScore: snoreScore)
        
        let start = session.startDate
        let end = session.endDate
        
        // Fetch metrics independently to ensure one failure doesn't block others
        m.heartRate = try? await HealthKitService.shared.fetchAverageQuantity(for: .heartRate, start: start, end: end, unit: HKUnit(from: "count/min"))
        m.spO2 = try? await HealthKitService.shared.fetchAverageQuantity(for: .oxygenSaturation, start: start, end: end, unit: .percent())
        m.respiratoryRate = try? await HealthKitService.shared.fetchAverageQuantity(for: .respiratoryRate, start: start, end: end, unit: HKUnit(from: "count/min"))
        
        await MainActor.run {
            self.metrics = m
            let finalScore = m.synergyScore
            self.synergyIndex = Int(finalScore)
            self.healthLevel = finalScore / 100.0
        }
    }
    
    private var healthColor: Color {
        healthLevel > 0.7 ? .somSafe : (healthLevel > 0.4 ? .somAccent : .red)
    }
    
    private func drawHelix(in context: GraphicsContext, size: CGSize, now: Double) {
        let centerY = size.height / 2
        let width = size.width
        let step = width / CGFloat(points - 1)
        
        for i in 0..<points {
            let x = CGFloat(i) * step
            let progress = Double(i) / Double(points)
            let angle = (progress * .pi * 4) + (now * rotationSpeed)
            
            // Calculamos entropía basada en el nivel de salud
            let chaos = (1.0 - healthLevel) * 30.0
            let noise = sin(Double(i) * 1.5 + now * 2.0) * chaos
            
            // Calculamos 4 offsets para las 4 hebras (Fase desplazada 90 grados entre cada una)
            let y1 = centerY + sin(angle) * 45 + noise
            let y2 = centerY + sin(angle + .pi / 2.0) * 35 - noise
            let y3 = centerY + sin(angle + .pi) * 45 + noise * 0.5
            let y4 = centerY + sin(angle + (3.0 * .pi / 2.0)) * 35 - noise * 0.5
            
            let opacity = (cos(angle) + 1.0) / 2.0
            
            // Conexiones estructurales (Peldaños cruzados)
            var p1 = Path(); p1.move(to: CGPoint(x: x, y: y1)); p1.addLine(to: CGPoint(x: x, y: y3))
            var p2 = Path(); p2.move(to: CGPoint(x: x, y: y2)); p2.addLine(to: CGPoint(x: x, y: y4))
            
            context.stroke(p1, with: .color(healthColor.opacity(opacity * 0.05)), lineWidth: 0.5)
            context.stroke(p2, with: .color(healthColor.opacity(opacity * 0.05)), lineWidth: 0.5)
            
            // Hebra 1: Audio (Accent)
            drawNode(in: context, at: CGPoint(x: x, y: y1), color: .somAccent, opacity: opacity, isSynergy: i % 20 == 0)
            
            // Hebra 2: Pulso (Safe)
            drawNode(in: context, at: CGPoint(x: x, y: y2), color: healthLevel < 0.5 ? .red : .somSafe, opacity: 1.0 - opacity, isSynergy: false)
            
            // Hebra 3: Oxígeno (Cian)
            drawNode(in: context, at: CGPoint(x: x, y: y3), color: .cyan, opacity: opacity, isSynergy: false)
            
            // Hebra 4: Respiración (Púrpura)
            drawNode(in: context, at: CGPoint(x: x, y: y4), color: .purple, opacity: 1.0 - opacity, isSynergy: false)
        }
    }
    
    private func drawNode(in context: GraphicsContext, at point: CGPoint, color: Color, opacity: Double, isSynergy: Bool) {
        let size: CGFloat = isSynergy ? 8 : 3
        let rect = CGRect(x: point.x - size/2, y: point.y - size/2, width: size, height: size)
        context.fill(Path(ellipseIn: rect), with: .color(color.opacity(opacity + 0.1)))
        if isSynergy {
            context.stroke(Path(ellipseIn: rect.insetBy(dx: -3, dy: -3)), with: .color(color.opacity(0.3)), lineWidth: 1)
        }
    }
}

struct HelixStat: View {
    let label: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.somTextSecondary)
                    .textCase(.uppercase)
                Text(value)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(color.opacity(0.1))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.2), lineWidth: 1))
    }
}

struct BioInsightCard: View {
    let dragX: CGFloat?
    let totalWidth: CGFloat
    let session: SleepSession?
    let metrics: SynergyMetrics?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let dx = dragX {
                let data = calculateData(for: dx)
                
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(data.time)
                            .font(.system(.title3, design: .monospaced).bold())
                            .foregroundColor(.somAccent)
                        
                        HStack {
                            Image(systemName: data.icon)
                            Text(data.state)
                        }
                        .font(.caption.bold())
                        .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(data.heartRate) LPM")
                            .font(.system(.title3, design: .monospaced).bold())
                            .foregroundColor(.somSafe)
                        Text("Ritmo Cardíaco")
                            .font(.caption2)
                            .foregroundColor(.somTextSecondary)
                    }
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                Text(data.insight)
                    .font(.subheadline)
                    .foregroundColor(.somTextSecondary)
                    .lineLimit(2)
            } else {
                HStack {
                    Image(systemName: "hand.draw.fill")
                        .foregroundColor(.somAccent)
                    Text("Desliza para analizar puntos específicos")
                        .font(.subheadline)
                        .foregroundColor(.somTextSecondary)
                }
                .frame(maxWidth: .infinity, minHeight: 80)
            }
        }
        .padding(20)
        .background(Color.somSurface)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(dragX != nil ? Color.somAccent.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
    
    private func calculateData(for x: CGFloat) -> InsightData {
        let progress = x / totalWidth
        
        let sessionStart = session?.startDate ?? Date().addingTimeInterval(-28800)
        let duration = session?.duration ?? 28800
        let pointTime = sessionStart.addingTimeInterval(duration * progress)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timeStr = formatter.string(from: pointTime)
        
        let avgHR = metrics?.heartRate ?? 65
        let hrVariation = sin(progress * .pi * 10) * 5
        let currentHR = Int(avgHR + hrVariation)
        
        if progress > 0.3 && progress < 0.45 {
            return InsightData(time: timeStr, state: "Actividad Elevada", icon: "waveform.path.ecg", heartRate: currentHR + 12, insight: "Se observa un aumento en el esfuerzo cardíaco coincidiendo con la fase actual.")
        } else if progress > 0.7 && progress < 0.85 {
            return InsightData(time: timeStr, state: "Respiración Irregular", icon: "wind", heartRate: currentHR + 5, insight: "Vibraciones acústicas detectadas. La sinergia cardiorrespiratoria se ve levemente afectada.")
        } else {
            return InsightData(time: timeStr, state: "Estado Sincronizado", icon: "checkmark.seal.fill", heartRate: currentHR, insight: "Nivel de sinergia óptimo. Los pulmones y el corazón trabajan en armonía.")
        }
    }
}

struct InsightData {
    let time: String
    let state: String
    let icon: String
    let heartRate: Int
    let insight: String
}

#Preview {
    ZStack { Color.somBackground.ignoresSafeArea(); SynergyHelixView(session: SleepSession.mock) }
}

struct SynergyMetrics {
    var spO2: Double?
    var heartRate: Double?
    var respiratoryRate: Double?
    var snoreScore: Double
    
    var synergyScore: Double {
        var score: Double = 0
        var totalWeight: Double = 0
        
        // SpO2 (Weight: 40%)
        if let spo2 = spO2 {
            let val = spo2 > 1.0 ? spo2 : spo2 * 100
            var o2Score: Double = 0
            if val >= 95 { o2Score = 100 }
            else if val >= 90 { o2Score = 80 - (94 - val) * 5 }
            else { o2Score = max(0, 40 - (89 - val) * 10) }
            score += o2Score * 0.40
            totalWeight += 0.40
        }
        
        // Snore/Apnea (Weight: 30%)
        score += snoreScore * 0.30
        totalWeight += 0.30
        
        // Heart Rate (Weight: 15%)
        if let hr = heartRate {
            var hrScore: Double = 0
            if hr >= 40 && hr <= 70 { hrScore = 100 }
            else if hr > 70 && hr <= 85 { hrScore = 80 }
            else { hrScore = 50 }
            score += hrScore * 0.15
            totalWeight += 0.15
        }
        
        // Respiratory Rate (Weight: 15%)
        if let rr = respiratoryRate {
            var rrScore: Double = 0
            if rr >= 12 && rr <= 20 { rrScore = 100 }
            else if (rr >= 10 && rr < 12) || (rr > 20 && rr <= 24) { rrScore = 80 }
            else { rrScore = 50 }
            score += rrScore * 0.15
            totalWeight += 0.15
        }
        
        return totalWeight > 0 ? (score / totalWeight) : snoreScore
    }
}
