import SwiftUI

struct SleepTopographyView: View {
    // Parámetros de la hélice
    let timePoints = 40 
    let depthPoints = 12 
    
    @State private var dragX: CGFloat? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Topografía de la Conciencia")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("Análisis de Consolidación de Memoria y Sueños")
                    .font(.caption)
                    .foregroundColor(.somTextSecondary)
            }
            .padding(.horizontal)
            
            // Contenedor del Canvas 3D (Cerebral)
            ZStack(alignment: .bottom) {
                Color.somSurface.opacity(0.3)
                    .cornerRadius(24)
                
                TimelineView(.animation) { timeline in
                    Canvas { context, size in
                        let now = timeline.date.timeIntervalSinceReferenceDate
                        drawNeuralMap(in: context, size: size, time: now)
                        
                        if let dx = dragX {
                            drawScanner(in: context, size: size, x: dx)
                        }
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            dragX = max(0, min(value.location.x, 350))
                        }
                        .onEnded { _ in
                            dragX = nil
                        }
                )
                
                // Timeline de Conciencia
                HStack {
                    Text("Vigilia").font(.system(size: 8, weight: .bold)).foregroundColor(.somAccent)
                    Spacer()
                    Text("Rem").font(.system(size: 8, weight: .bold)).foregroundColor(.purple)
                    Spacer()
                    Text("Profundo").font(.system(size: 8, weight: .bold)).foregroundColor(.indigo)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 12)
            }
            .frame(height: 220)
            .padding(.horizontal)
            
            // Neural-Insight Panel
            NeuralInsightCard(dragX: dragX, totalWidth: 350)
                .padding(.horizontal)
            
            // Cápsulas de Datos Duros: Arquitectura de Sueño
            VStack(alignment: .leading, spacing: 12) {
                Text("Arquitectura de Sueño")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.somTextSecondary)
                    .tracking(2)
                    .textCase(.uppercase)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        SleepDataCapsule(label: "Despierto", value: "15m", color: .somAccent)
                        SleepDataCapsule(label: "REM", value: "2h 10m", color: .purple)
                        SleepDataCapsule(label: "Ligero", value: "3h 45m", color: .cyan)
                        SleepDataCapsule(label: "Profundo", value: "1h 25m", color: .indigo)
                    }
                }
            }
            .padding(.horizontal)
            
            // Métricas de Consolidación
            HStack(spacing: 15) {
                statItem(label: "Consolidación", value: "88%", color: .purple)
                statItem(label: "Memoria", value: "420 pqt", color: .somAccent)
                statItem(label: "Ensueño", value: "Alta", color: .indigo)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color.somBackground)
    }
    
    private func drawScanner(in context: GraphicsContext, size: CGSize, x: CGFloat) {
        var path = Path()
        path.move(to: CGPoint(x: x, y: 20))
        path.addLine(to: CGPoint(x: x, y: size.height - 30))
        context.stroke(path, with: .color(.purple), lineWidth: 2)
        context.stroke(path, with: .color(.purple.opacity(0.3)), lineWidth: 6)
    }
    
    private func drawNeuralMap(in context: GraphicsContext, size: CGSize, time: Double) {
        let colWidth = size.width / CGFloat(timePoints - 1)
        let verticalScale: CGFloat = 80.0
        let centerY = size.height / 2
        
        let dreamColor = Color(red: 0.8, green: 0.2, blue: 1.0)
        let deepColor = Color(red: 0.2, green: 0.0, blue: 0.5)
        let memoryColor = Color(red: 1.0, green: 0.8, blue: 0.2)
        
        for row in 0..<depthPoints {
            var path = Path()
            let zOffset = CGFloat(row) * 10.0
            let rowOpacity = 1.0 - (Double(row) / Double(depthPoints))
            
            for col in 0..<timePoints {
                let xBase = CGFloat(col) * colWidth
                let sleepDepth = sin(CGFloat(col) * 0.2) * 0.5 + 0.5
                var remActivity: CGFloat = 0
                if col > 15 && col < 25 {
                    remActivity = sin(time * 3 + CGFloat(col)) * 0.15 + 0.1
                }
                let zValue = remActivity - sleepDepth
                let px = xBase + (zOffset * 0.5)
                let py = centerY + (zOffset * 0.8) - (zValue * verticalScale)
                if col == 0 { path.move(to: CGPoint(x: px, y: py)) }
                else { path.addLine(to: CGPoint(x: px, y: py)) }
                
                if row == 0 && col % 4 == 0 && remActivity > 0 {
                    let sparkSize = CGFloat.random(in: 1...3)
                    let spark = Path(ellipseIn: CGRect(x: px, y: py - 10, width: sparkSize, height: sparkSize))
                    context.fill(spark, with: .color(memoryColor.opacity(abs(sin(time + Double(col))))))
                }
            }
            context.stroke(path, with: .linearGradient(Gradient(colors: [dreamColor.opacity(rowOpacity), deepColor.opacity(rowOpacity)]), startPoint: .zero, endPoint: CGPoint(x: size.width, y: 0)), lineWidth: 1.2)
        }
    }
    
    private func statItem(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 8, weight: .bold)).foregroundColor(.somTextSecondary).textCase(.uppercase)
            Text(value).font(.system(size: 16, weight: .black, design: .rounded)).foregroundColor(color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct SleepDataCapsule: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.somTextSecondary)
            Text(value)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.somSurface))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.3), lineWidth: 1))
    }
}

struct NeuralInsightCard: View {
    let dragX: CGFloat?
    let totalWidth: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let dx = dragX {
                let data = calculateNeuralData(for: dx)
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(data.time).font(.system(.title3, design: .monospaced).bold()).foregroundColor(.purple)
                        HStack { Image(systemName: data.icon); Text(data.state) }.font(.caption.bold()).foregroundColor(.white)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(data.memoryFragments).font(.system(.title3, design: .monospaced).bold()).foregroundColor(.somAccent)
                        Text("Frag. Memoria").font(.caption2).foregroundColor(.somTextSecondary)
                    }
                }
                Divider().background(Color.white.opacity(0.1))
                Text(data.insight).font(.subheadline).foregroundColor(.somTextSecondary).lineLimit(2)
            } else {
                HStack {
                    Image(systemName: "brain.head.profile").foregroundColor(.purple)
                    Text("Explora tu arquitectura cerebral").font(.subheadline).foregroundColor(.somTextSecondary)
                }.frame(maxWidth: .infinity, minHeight: 80)
            }
        }
        .padding(20)
        .background(Color.somSurface)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(dragX != nil ? Color.purple.opacity(0.3) : Color.clear, lineWidth: 1))
    }
    
    private func calculateNeuralData(for x: CGFloat) -> NeuralData {
        let progress = x / totalWidth
        let timeStr = "03:45 AM"
        if progress > 0.4 && progress < 0.6 {
            return NeuralData(time: timeStr, state: "Sueño REM / Ensueño", icon: "sparkles", memoryFragments: "120 pqt", insight: "Máxima actividad onírica. Tu cerebro está reorganizando experiencias emocionales del día.")
        } else {
            return NeuralData(time: timeStr, state: "Sueño N3 (Profundo)", icon: "brain.fill", memoryFragments: "45 pqt", insight: "Limpieza del sistema glinfático. Consolidación de memoria declarativa y descanso motor.")
        }
    }
}

struct NeuralData {
    let time: String
    let state: String
    let icon: String
    let memoryFragments: String
    let insight: String
}

#Preview {
    ZStack {
        Color.somBackground.ignoresSafeArea()
        SleepTopographyView()
    }
}
