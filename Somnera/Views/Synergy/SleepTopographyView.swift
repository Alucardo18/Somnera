import SwiftUI

struct NeuralData {
    let time: String
    let state: String
    let icon: String
    let memoryFragments: String
    let insight: String
}

struct SleepTopographyView: View {
    let session: SleepSession?
    
    // Parámetros
    let timePoints = 40 
    let depthPoints = 12 
    let totalWidth: CGFloat = 350
    
    @State private var dragX: CGFloat? = nil
    @State private var hapticTrigger = false
    
    // Colores
    let goldColor = Color(red: 1.0, green: 0.84, blue: 0.0) // Oro Real
    let dreamColor = Color.purple
    let deepColor = Color.indigo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ZStack(alignment: .bottom) {
                Color.somSurface.opacity(0.3).cornerRadius(24)
                
                TimelineView(.animation) { timeline in
                    Canvas { context, size in
                        let now = timeline.date.timeIntervalSinceReferenceDate
                        drawNeuralMap(in: context, size: size, time: now)
                        if let dx = dragX { drawScanner(in: context, size: size, x: dx) }
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let newX = max(0, min(value.location.x, totalWidth))
                            let now = Date().timeIntervalSinceReferenceDate
                            if checkSparkCollision(at: newX, time: now) {
                                hapticTrigger.toggle()
                            }
                            dragX = newX
                        }
                        .onEnded { _ in dragX = nil }
                )
                .sensoryFeedback(.impact(weight: .light, intensity: 0.4), trigger: hapticTrigger)
                
                // Timeline
                HStack {
                    Text("Vigilia").font(.system(size: 8, weight: .bold)).foregroundColor(.somAccent)
                    Spacer()
                    Text("Rem").font(.system(size: 8, weight: .bold)).foregroundColor(.purple)
                    Spacer()
                    Text("Profundo").font(.system(size: 8, weight: .bold)).foregroundColor(.indigo)
                }
                .padding(.horizontal, 30).padding(.bottom, 12)
            }
            .frame(height: 220).padding(.horizontal)
            
            NeuralInsightCard(dragX: dragX, totalWidth: totalWidth, session: session)
                .padding(.horizontal)
            
            // Cápsulas y Stats DInámicas
            VStack(alignment: .leading, spacing: 12) {
                Text("Arquitectura de Sueño").font(.system(size: 10, weight: .bold)).foregroundColor(.somTextSecondary).tracking(2).textCase(.uppercase)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        let duration = session?.duration ?? 28800
                        SleepDataCapsule(label: "Despierto", value: formatMinutes(duration * 0.1), color: .somAccent)
                        SleepDataCapsule(label: "REM", value: formatMinutes(duration * 0.25), color: .purple)
                        SleepDataCapsule(label: "Ligero", value: formatMinutes(duration * 0.45), color: .cyan)
                        SleepDataCapsule(label: "Profundo", value: formatMinutes(duration * 0.20), color: .indigo)
                    }
                }
            }.padding(.horizontal)
            
            HStack(spacing: 15) {
                statItem(label: "Consolidación", value: "\(session?.snoreScore ?? 88)%", color: .purple)
                statItem(label: "Memoria", value: "\(session?.memoryPacketsCount ?? 420) pqt", color: .somAccent)
                statItem(label: "Ensueño", value: (session?.duration ?? 28800) > 21600 ? "Alta" : "Media", color: .indigo)
            }.padding(.horizontal)
        }
        .padding(.vertical).background(Color.somBackground)
    }
    
    private func formatMinutes(_ seconds: Double) -> String {
        let mins = Int(seconds / 60)
        let h = mins / 60
        let m = mins % 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
    
    // MARK: - Neural & Physics Engine (Sin cambios en lógica visual)
    
    private func getWaveY(at x: CGFloat, size: CGSize) -> CGFloat {
        let colWidth = size.width / CGFloat(timePoints - 1)
        let col = max(0, min(Int(x / colWidth), timePoints - 1))
        let centerY = size.height / 2
        let remIntensity = (col > 15 && col < 25) ? (sin(CGFloat(col) * 0.5) * 0.5 + 0.5) : 0
        let sleepDepth = sin(CGFloat(col) * 0.2) * 0.5 + 0.5
        let zValue = (remIntensity * 0.2) - sleepDepth
        return centerY - (zValue * 80)
    }
    
    private func getSparkPos(id: Int, time: Double, size: CGSize) -> (x: CGFloat, y: CGFloat, opacity: Double, lifecycle: Double) {
        let speed = 0.2 
        let lifecycle = (time * speed + Double(id) * 0.731).truncatingRemainder(dividingBy: 1.0)
        let opacity = sin(lifecycle * .pi)
        let zoneStart: CGFloat = totalWidth * 0.35
        let zoneEnd: CGFloat = totalWidth * 0.65
        let range = zoneEnd - zoneStart
        let cycleId = floor(time * speed + Double(id) * 0.731)
        let xSeed = sin(cycleId * 987.654 + Double(id) * 123.456)
        let xPos = zoneStart + range * (abs(xSeed))
        let waveY = getWaveY(at: xPos, size: size)
        let v0: CGFloat = -90.0
        let gravity: CGFloat = 80.0
        let t = CGFloat(lifecycle)
        let yDisplacement = (v0 * t) + (0.5 * gravity * t * t)
        return (xPos, waveY + yDisplacement, opacity, lifecycle)
    }
    
    private func checkSparkCollision(at x: CGFloat, time: Double) -> Bool {
        let dummySize = CGSize(width: totalWidth, height: 220)
        for i in 0..<10 {
            let spark = getSparkPos(id: i, time: time, size: dummySize)
            if spark.opacity > 0.3 && abs(x - spark.x) < 3 { return true }
        }
        return false
    }
    
    private func drawNeuralMap(in context: GraphicsContext, size: CGSize, time: Double) {
        let colWidth = size.width / CGFloat(timePoints - 1)
        let centerY = size.height / 2
        for row in 0..<depthPoints {
            var path = Path()
            let zOffset = CGFloat(row) * 10.0
            let rowOpacity = 1.0 - (Double(row) / Double(depthPoints))
            for col in 0..<timePoints {
                let xBase = CGFloat(col) * colWidth
                let remIntensity = (col > 15 && col < 25) ? (sin(CGFloat(col) * 0.5) * 0.5 + 0.5) : 0
                let sleepDepth = sin(CGFloat(col) * 0.2) * 0.5 + 0.5
                let zValue = (remIntensity * 0.2) - sleepDepth
                let px = xBase + (zOffset * 0.5)
                let py = centerY + (zOffset * 0.8) - (zValue * 80)
                if col == 0 { path.move(to: CGPoint(x: px, y: py)) }
                else { path.addLine(to: CGPoint(x: px, y: py)) }
            }
            context.stroke(path, with: .linearGradient(Gradient(colors: [dreamColor.opacity(rowOpacity * 0.4), deepColor.opacity(rowOpacity * 0.4)]), startPoint: .zero, endPoint: CGPoint(x: size.width, y: 0)), lineWidth: 1.0)
        }
        for i in 0..<10 {
            let spark = getSparkPos(id: i, time: time, size: size)
            if spark.opacity > 0 {
                let opacity = spark.opacity
                let lifecycle = spark.lifecycle
                let isBursting = lifecycle > 0.8
                var baseSize: CGFloat = 2.0
                var bloomRadius: CGFloat = 0
                if isBursting {
                    let burstProgress = (lifecycle - 0.8) / 0.2
                    baseSize = 2.0 + (CGFloat(sin(burstProgress * .pi)) * 6.0)
                    bloomRadius = baseSize * 2.5
                }
                if isBursting {
                    context.fill(Path(ellipseIn: CGRect(x: spark.x - bloomRadius, y: spark.y - bloomRadius, width: bloomRadius*2, height: bloomRadius*2)), with: .color(goldColor.opacity(opacity * 0.25)))
                    let midGlow = bloomRadius * 0.6
                    context.fill(Path(ellipseIn: CGRect(x: spark.x - midGlow, y: spark.y - midGlow, width: midGlow*2, height: midGlow*2)), with: .color(goldColor.opacity(opacity * 0.4)))
                }
                let coreSize = isBursting ? baseSize * 0.5 : baseSize
                context.fill(Path(ellipseIn: CGRect(x: spark.x - coreSize/2, y: spark.y - coreSize/2, width: coreSize, height: coreSize)), with: .color(goldColor.opacity(opacity)))
            }
        }
    }
    
    private func drawScanner(in context: GraphicsContext, size: CGSize, x: CGFloat) {
        var path = Path()
        path.move(to: CGPoint(x: x, y: 20))
        path.addLine(to: CGPoint(x: x, y: size.height - 30))
        context.stroke(path, with: .color(.white.opacity(0.8)), lineWidth: 1.2)
    }
    
    private func statItem(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 8, weight: .bold)).foregroundColor(.somTextSecondary).textCase(.uppercase)
            Text(value).font(.system(size: 16, weight: .black, design: .rounded)).foregroundColor(color)
        }.padding(10).background(color.opacity(0.1)).cornerRadius(12)
    }
}

// MARK: - Subviews

struct SleepDataCapsule: View {
    let label: String; let value: String; let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 9, weight: .bold)).foregroundColor(.somTextSecondary)
            Text(value).font(.system(size: 14, weight: .black, design: .rounded)).foregroundColor(.white)
        }.padding(.horizontal, 16).padding(.vertical, 10).background(RoundedRectangle(cornerRadius: 16).fill(Color.somSurface)).overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.3), lineWidth: 1))
    }
}

struct NeuralInsightCard: View {
    let dragX: CGFloat?; let totalWidth: CGFloat; let session: SleepSession?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let dx = dragX {
                let data = calculateNeuralData(for: dx)
                HStack {
                    VStack(alignment: .leading) {
                        Text(data.time).font(.system(.title3, design: .monospaced).bold()).foregroundColor(.purple)
                        Label(data.state, systemImage: data.icon).font(.caption.bold()).foregroundColor(.white)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(data.memoryFragments).font(.system(.title3, design: .monospaced).bold()).foregroundColor(.somAccent)
                        Text("Frag. Memoria").font(.caption2).foregroundColor(.somTextSecondary)
                    }
                }
                Divider().background(Color.white.opacity(0.1))
                Text(data.insight).font(.subheadline).foregroundColor(.somTextSecondary).lineLimit(2)
            } else {
                Label("Explora tu arquitectura cerebral", systemImage: "brain.head.profile").font(.subheadline).foregroundColor(.somTextSecondary).frame(maxWidth: .infinity, minHeight: 80)
            }
        }.padding(20).background(Color.somSurface).cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(dragX != nil ? Color.purple.opacity(0.3) : Color.clear, lineWidth: 1))
    }
    
    private func calculateNeuralData(for x: CGFloat) -> NeuralData {
        let progress = x / totalWidth
        let duration = session?.duration ?? 28800
        let startTime = session?.startDate ?? Date().addingTimeInterval(-28800)
        let currentTime = startTime.addingTimeInterval(duration * Double(progress))
        
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        let timeString = formatter.string(from: currentTime)
        
        if progress > 0.35 && progress < 0.65 {
            let pqt = Int(Double(session?.memoryPacketsCount ?? 420) * 0.15)
            return NeuralData(time: timeString, state: "Sueño REM", icon: "sparkles", memoryFragments: "\(pqt) pqt", insight: "Consolidación de memoria activa. Los fragmentos brotan de las ondas neuronales dominantes.")
        } else {
            let pqt = Int(Double(session?.memoryPacketsCount ?? 420) * 0.05)
            return NeuralData(time: timeString, state: "Sueño Profundo", icon: "brain.fill", memoryFragments: "\(pqt) pqt", insight: "Recuperación cognitiva. Estabilidad en las ondas de frecuencia baja.")
        }
    }
}

#Preview {
    ZStack { Color.somBackground.ignoresSafeArea(); SleepTopographyView(session: SleepSession.mock) }
}
