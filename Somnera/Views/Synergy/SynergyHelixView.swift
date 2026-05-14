import SwiftUI

struct SynergyHelixView: View {
    // Parámetros de la hélice
    let points = 60
    let rotationSpeed: Double = 0.5
    
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var synergyIndex: Int = 94
    @State private var healthLevel: Double = 1.0
    @State private var hapticTrigger: Int = 0
    
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
                            
                            updateStatsForDrag(offset: dragOffset)
                        }
                        .onEnded { _ in
                            withAnimation(.spring()) {
                                isDragging = false
                                dragOffset = 0
                                healthLevel = 1.0
                                synergyIndex = 94
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
            BioInsightCard(dragX: isDragging ? dragOffset : nil, totalWidth: 350)
                .padding(.horizontal)
            
            // Grid de Estadísticas (Ahora 4)
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    HelixStat(label: "Audio", color: .somAccent, icon: "waveform")
                    HelixStat(label: "Pulso", color: .somSafe, icon: "heart.fill")
                }
                HStack(spacing: 8) {
                    HelixStat(label: "Oxígeno", color: .cyan, icon: "drop.fill")
                    HelixStat(label: "Resp.", color: .purple, icon: "wind")
                }
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    private func updateStatsForDrag(offset: CGFloat) {
        let absOffset = abs(offset)
        if absOffset > 100 && absOffset < 200 {
            healthLevel = 0.4
            synergyIndex = 65
        } else {
            healthLevel = 1.0
            synergyIndex = 94
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
            
            // Calculamos 4 offsets para las 4 hebras (Fase desplazada 90 grados entre cada una)
            let y1 = centerY + sin(angle) * 45
            let y2 = centerY + sin(angle + .pi / 2.0) * 35
            let y3 = centerY + sin(angle + .pi) * 45
            let y4 = centerY + sin(angle + (3.0 * .pi / 2.0)) * 35
            
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
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 10, weight: .black))
                .foregroundColor(.white)
                .textCase(.uppercase)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct BioInsightCard: View {
    let dragX: CGFloat?
    let totalWidth: CGFloat
    
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
        let timeStr = "02:30 AM" // Simulado
        
        if progress > 0.4 && progress < 0.6 {
            return InsightData(time: timeStr, state: "Ronquido Detectado", icon: "megaphone.fill", heartRate: 82, insight: "Se detectó una obstrucción parcial. Tu oxigenación bajó al 92% temporalmente.")
        } else {
            return InsightData(time: timeStr, state: "Ritmo Estable", icon: "checkmark.circle.fill", heartRate: 62, insight: "Sinergia perfecta detectada entre el flujo de aire y tu ritmo cardíaco.")
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
    ZStack {
        Color.somBackground.ignoresSafeArea()
        SynergyHelixView()
    }
}
