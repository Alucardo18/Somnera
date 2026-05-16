import SwiftUI
import AudioToolbox
import HealthKit

struct NeuralData {
    let time: String
    let state: String
    let icon: String
    let memoryFragments: String
    let insight: String
}

// Motor de colisiones ultra-rápido sin dependencia de estado
class TopographyPhysicsEngine {
    var lastPlayedCycles: [Int: Double] = [:]
    var particleCache: [(x: CGFloat, y: CGFloat, opacity: Double, lifecycle: Double)] = []
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .heavy)
    
    init() { hapticGenerator.prepare() }
    
    func checkCollision(at x: CGFloat, time: Double, totalWidth: CGFloat) {
        for i in 0..<particleCache.count {
            let spark = particleCache[i]
            
            // Verificamos colisión con el tooltip
            if abs(x - spark.x) < 6 {
                // TRIGGER: Solo si la partícula está en fase de ESTALLIDO (Stellar Burst)
                if spark.lifecycle > 0.8 && spark.opacity > 0.1 {
                    let speed = 0.2
                    let currentCycle = floor(time * speed + Double(i) * 0.731)
                    
                    if (lastPlayedCycles[i] ?? -1) != currentCycle {
                        let pan = Float((spark.x / totalWidth) * 2.0 - 1.0)
                        
                        // Feedback Inmediato Asíncrono
                        DispatchQueue.main.async {
                            self.hapticGenerator.impactOccurred(intensity: 1.0)
                            ConsciousnessSoundManager.shared.playSparkle(pan: pan)
                        }
                        lastPlayedCycles[i] = currentCycle
                    }
                }
            }
        }
    }
}

struct SleepTopographyView: View {
    let session: SleepSession?
    let timePoints = 40 
    let depthPoints = 12 
    let totalWidth: CGFloat = 350
    
    @State private var dragX: CGFloat? = nil
    @State private var physicsEngine = TopographyPhysicsEngine()
    @State private var healthSleepSamples: [HKCategorySample] = []
    
    let goldColor = Color(red: 1.0, green: 0.84, blue: 0.0)
    let dreamColor = Color.purple
    let deepColor = Color.indigo
    
    // Pre-cálculo de intensidades para inferencia acústica
    private static let deepIntensities: [CGFloat] = (0..<40).map { col in
        let progress = Double(col) / 40.0
        return CGFloat(exp(-pow(progress - 0.2, 2) / 0.05))
    }
    private static let remIntensities: [CGFloat] = (0..<40).map { col in
        let progress = Double(col) / 40.0
        return CGFloat(exp(-pow(progress - 0.8, 2) / 0.1))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ZStack {
                Color.somSurface.opacity(0.3).cornerRadius(24)
                TimelineView(.animation) { timeline in
                    let now = timeline.date.timeIntervalSinceReferenceDate
                    let size = CGSize(width: totalWidth, height: 220)
                    
                    // Pre-calculamos fuera del Canvas
                    let _ = updatePhysics(now: now, size: size)
                    
                    Canvas { context, size in
                        drawNeuralMap(in: context, size: size, time: now)
                        if let dx = dragX { 
                            drawScanner(in: context, size: size, x: dx)
                        }
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            dragX = max(0, min(value.location.x, totalWidth))
                        }
                        .onEnded { _ in dragX = nil }
                )
                // Eje de Tiempo Real (Abajo)
                HStack {
                    Text(formatTime(session?.startDate ?? Date().addingTimeInterval(-28800)))
                    Spacer()
                    Text(formatTime(session?.endDate ?? Date()))
                }
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.somTextSecondary.opacity(0.6))
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                
                // Leyenda de Fases (Arriba)
                HStack(spacing: 16) {
                    legendItem(color: .indigo, label: "Profundo")
                    legendItem(color: .purple, label: "REM")
                    legendItem(color: .cyan, label: "Ligero")
                    legendItem(color: goldColor, label: "Memoria")
                }
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(Color.somSurface.opacity(0.8))
                .cornerRadius(20)
                .padding(.top, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .frame(height: 220).padding(.horizontal)
            NeuralInsightCard(dragX: dragX, totalWidth: totalWidth, session: session, healthSamples: healthSleepSamples).padding(.horizontal)
            VStack(alignment: .leading, spacing: 12) {
                Text("Arquitectura de Sueño").font(.system(size: 10, weight: .bold)).foregroundColor(.somTextSecondary).tracking(2).textCase(.uppercase)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        let duration = session?.duration ?? 28800
                        SleepDataCapsule(label: "Despierto", value: formatMinutes(duration * 0.1), color: .teal)
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
        .task {
            await fetchHealthData()
        }
    }
    
    private func fetchHealthData() async {
        guard let session = session else { return }
        do {
            let samples = try await HealthKitService.shared.fetchSleepStages(start: session.startDate, end: session.endDate)
            DispatchQueue.main.async {
                self.healthSleepSamples = samples
            }
        } catch {
            print("[Topography] Error fetching health data: \(error)")
        }
    }
    
    private func updatePhysics(now: Double, size: CGSize) {
        let ranges = getValidConsolidationRanges()
        physicsEngine.particleCache = (0..<10).map { 
            getSparkPos(id: $0, time: now, size: size, ranges: ranges) 
        }
        if let dx = dragX {
            physicsEngine.checkCollision(at: dx, time: now, totalWidth: totalWidth)
        }
    }
    
    private func formatMinutes(_ seconds: Double) -> String {
        let mins = Int(seconds / 60); let h = mins / 60; let m = mins % 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
    
    private func getWaveY(at x: CGFloat, size: CGSize, time: Double) -> CGFloat {
        let colWidth = size.width / CGFloat(timePoints - 1); let col = max(0, min(Int(x / colWidth), timePoints - 1))
        let centerY = size.height / 2; let zValue = calculateZValue(col: col, time: time)
        return centerY - (zValue * 80)
    }
    
    private func calculateZValue(col: Int, time: Double) -> CGFloat {
        let t = time * 0.4
        let progress = Double(col) / Double(timePoints)
        var audioBias: Double = 0
        
        // El algoritmo acústico como reforzamiento siempre aporta si hay datos
        if let timeline = session?.decibelTimeline, !timeline.isEmpty {
            let index = (col * timeline.count) / timePoints
            let db = timeline[max(0, min(index, timeline.count - 1))]
            audioBias = Double(max(0, db - 30) / 60.0) * 0.3
        }
        
        let colIdx = max(0, min(col, 39))
        var deepIntensity: Double = 0
        var remIntensity: Double = 0
        var baseIntensity: Double = 0.2
        
        if !healthSleepSamples.isEmpty, let session = session {
            // Apple Health como prioritario
            let timeAtCol = session.startDate.addingTimeInterval(session.duration * progress)
            if let sample = getBestSleepSample(at: timeAtCol, from: healthSleepSamples) {
                switch sample.value {
                case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                    deepIntensity = 1.0
                    remIntensity = 0.2
                    baseIntensity = 0.1
                case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                    deepIntensity = 0.2
                    remIntensity = 1.0
                    baseIntensity = 0.1
                case HKCategoryValueSleepAnalysis.awake.rawValue:
                    deepIntensity = 0.1
                    remIntensity = 0.1
                    baseIntensity = 0.05
                default: // asleepCore, asleepUnspecified, inBed
                    deepIntensity = 0.3
                    remIntensity = 0.4
                    baseIntensity = 0.5
                }
            } else {
                deepIntensity = 0.1
                remIntensity = 0.1
                baseIntensity = 0.2
            }
        } else {
            // Algoritmo acústico (Inferido) si no hay Apple Health
            deepIntensity = Double(Self.deepIntensities[colIdx])
            remIntensity = Double(Self.remIntensities[colIdx])
        }
        
        let deepWave = sin(Double(col) * 0.15 + t) * deepIntensity
        let remWave = sin(Double(col) * 0.6 + t * 2.0) * remIntensity
        let baseWave = sin(Double(col) * 0.3 + t) * baseIntensity
        
        return CGFloat(deepWave + remWave + baseWave + audioBias)
    }
    
    private func getValidConsolidationRanges() -> [ClosedRange<Double>] {
        var validRanges: [ClosedRange<Double>] = []
        let totalTime = session?.duration ?? 28800
        let sessionStart = session?.startDate ?? Date().addingTimeInterval(-28800)
        
        if !healthSleepSamples.isEmpty {
            for sample in healthSleepSamples {
                let val = sample.value
                if val == HKCategoryValueSleepAnalysis.asleepDeep.rawValue || val == HKCategoryValueSleepAnalysis.asleepREM.rawValue {
                    let start = max(sessionStart, sample.startDate)
                    let end = min(sessionStart.addingTimeInterval(totalTime), sample.endDate)
                    if start < end {
                        let p1 = start.timeIntervalSince(sessionStart) / totalTime
                        let p2 = end.timeIntervalSince(sessionStart) / totalTime
                        validRanges.append(p1...p2)
                    }
                }
            }
        } else {
            validRanges = [0.1...0.3, 0.6...0.85]
        }
        
        return validRanges.isEmpty ? [0.1...0.9] : validRanges
    }
    
    private func getSparkPos(id: Int, time: Double, size: CGSize, ranges: [ClosedRange<Double>]) -> (x: CGFloat, y: CGFloat, opacity: Double, lifecycle: Double) {
        let speed = 0.2 ; let lifecycle = (time * speed + Double(id) * 0.731).truncatingRemainder(dividingBy: 1.0)
        let opacity = sin(lifecycle * .pi)
        
        let cycleId = floor(time * speed + Double(id) * 0.731)
        let rawSeed = abs(sin(cycleId * 987.654 + Double(id) * 123.456)).truncatingRemainder(dividingBy: 1.0)
        
        let totalLength = ranges.reduce(0) { $0 + ($1.upperBound - $1.lowerBound) }
        var mappedProgress: Double = ranges.first?.lowerBound ?? 0.5
        var targetValue = rawSeed * totalLength
        
        for r in ranges {
            let length = r.upperBound - r.lowerBound
            if targetValue <= length {
                mappedProgress = r.lowerBound + targetValue
                break
            }
            targetValue -= length
        }
        
        let xPos = CGFloat(mappedProgress) * totalWidth
        let waveY = getWaveY(at: xPos, size: size, time: time); let v0: CGFloat = -90.0; let gravity: CGFloat = 80.0; let t = CGFloat(lifecycle); let yDisplacement = (v0 * t) + (0.5 * gravity * t * t)
        return (xPos, waveY + yDisplacement, opacity, lifecycle)
    }
    
    private func drawNeuralMap(in context: GraphicsContext, size: CGSize, time: Double) {
        let colWidth = size.width / CGFloat(timePoints - 1); let centerY = size.height / 2
        for row in 0..<depthPoints {
            var path = Path(); let zOffset = CGFloat(row) * 10.0; let rowOpacity = 1.0 - (Double(row) / Double(depthPoints))
            for col in 0..<timePoints {
                let xBase = CGFloat(col) * colWidth; let zValue = calculateZValue(col: col, time: time + Double(row) * 0.1)
                let px = xBase + (zOffset * 0.5); let py = centerY + (zOffset * 0.8) - (zValue * 60)
                if col == 0 { path.move(to: CGPoint(x: px, y: py)) }
                else { path.addLine(to: CGPoint(x: px, y: py)) }
            }
            context.stroke(path, with: .linearGradient(dynamicGradient(rowOpacity: rowOpacity), startPoint: .zero, endPoint: CGPoint(x: size.width, y: 0)), lineWidth: 1.0)
        }
        
        // Usamos las partículas del cache para dibujar
        for i in 0..<physicsEngine.particleCache.count {
            let spark = physicsEngine.particleCache[i]
            if spark.opacity > 0 {
                let opacity = spark.opacity; let lifecycle = spark.lifecycle; let isBursting = lifecycle > 0.8; var baseSize: CGFloat = 2.0; var bloomRadius: CGFloat = 0
                if isBursting {
                    let burstProgress = (lifecycle - 0.8) / 0.2; baseSize = 2.0 + (CGFloat(sin(burstProgress * .pi)) * 6.0); bloomRadius = baseSize * 2.5
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
        var path = Path(); path.move(to: CGPoint(x: x, y: 20)); path.addLine(to: CGPoint(x: x, y: size.height - 30))
        context.stroke(path, with: .color(.white.opacity(0.8)), lineWidth: 1.2)
    }
    
    private func statItem(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 8, weight: .bold)).foregroundColor(.somTextSecondary).textCase(.uppercase)
            Text(value).font(.system(size: 16, weight: .black, design: .rounded)).foregroundColor(color)
        }.padding(10).background(color.opacity(0.1)).cornerRadius(12)
    }
    
    private func dynamicGradient(rowOpacity: Double) -> Gradient {
        guard let session = session, !healthSleepSamples.isEmpty else {
            return Gradient(stops: [
                Gradient.Stop(color: Color.cyan.opacity(rowOpacity * 0.4), location: 0.0),
                Gradient.Stop(color: dreamColor.opacity(rowOpacity * 0.4), location: 0.5),
                Gradient.Stop(color: deepColor.opacity(rowOpacity * 0.4), location: 1.0)
            ])
        }
        
        var stops: [Gradient.Stop] = []
        let totalTime = session.duration
        let samplesCount = 50
        
        for i in 0...samplesCount {
            let progress = Double(i) / Double(samplesCount)
            let timeAtCol = session.startDate.addingTimeInterval(totalTime * progress)
            var stopColor = Color.cyan
            
            if let sample = getBestSleepSample(at: timeAtCol, from: healthSleepSamples) {
                switch sample.value {
                case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                    stopColor = deepColor
                case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                    stopColor = dreamColor
                case HKCategoryValueSleepAnalysis.awake.rawValue:
                    stopColor = .cyan
                default: // asleepCore, asleepUnspecified
                    stopColor = .cyan
                }
            }
            
            stops.append(Gradient.Stop(color: stopColor.opacity(rowOpacity * 0.4), location: CGFloat(progress)))
        }
        return Gradient(stops: stops)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        return formatter.string(from: date)
    }
    
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label).font(.system(size: 9, weight: .bold)).foregroundColor(.somTextSecondary).textCase(.uppercase)
        }
    }
}

fileprivate func getBestSleepSample(at time: Date, from samples: [HKCategorySample]) -> HKCategorySample? {
    let overlapping = samples.filter { time >= $0.startDate && time <= $0.endDate }
    return overlapping.max(by: { samplePriority($0.value) < samplePriority($1.value) })
}

fileprivate func samplePriority(_ value: Int) -> Int {
    switch value {
    case HKCategoryValueSleepAnalysis.awake.rawValue: return 5
    case HKCategoryValueSleepAnalysis.asleepDeep.rawValue: return 4
    case HKCategoryValueSleepAnalysis.asleepREM.rawValue: return 3
    case HKCategoryValueSleepAnalysis.asleepCore.rawValue: return 2
    case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue: return 1
    case HKCategoryValueSleepAnalysis.inBed.rawValue: return 0
    default: return -1
    }
}

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
    let dragX: CGFloat?
    let totalWidth: CGFloat
    let session: SleepSession?
    let healthSamples: [HKCategorySample]
    
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
        let progress = x / totalWidth; let duration = session?.duration ?? 28800; let startTime = session?.startDate ?? Date().addingTimeInterval(-28800); let currentTime = startTime.addingTimeInterval(duration * Double(progress))
        let formatter = DateFormatter(); formatter.dateFormat = "hh:mm a"; let timeString = formatter.string(from: currentTime)
        
        let pqt: Int
        let state: String
        let icon: String
        let insight: String
        
        if !healthSamples.isEmpty {
            if let sample = getBestSleepSample(at: currentTime, from: healthSamples) {
                switch sample.value {
                case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                    pqt = Int(Double(session?.memoryPacketsCount ?? 420) * 0.08)
                    state = "Profundo (Watch)"
                    icon = "brain.fill"
                    insight = "Recuperación física y limpieza glinfática. Ondas delta."
                case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                    pqt = Int(Double(session?.memoryPacketsCount ?? 420) * 0.15)
                    state = "REM (Watch)"
                    icon = "sparkles"
                    insight = "Consolidación emocional activa. Alta actividad talamocortical."
                case HKCategoryValueSleepAnalysis.awake.rawValue:
                    pqt = 0
                    state = "Despierto (Watch)"
                    icon = "eye.fill"
                    insight = "Interrupción del sueño detectada por Apple Watch."
                default:
                    pqt = Int(Double(session?.memoryPacketsCount ?? 420) * 0.03)
                    state = "Ligero (Watch)"
                    icon = "moon.fill"
                    insight = "Transición neuronal. Procesamiento periférico."
                }
            } else {
                pqt = Int(Double(session?.memoryPacketsCount ?? 420) * 0.03)
                state = "Sueño (Sin Datos Watch)"
                icon = "moon.fill"
                insight = "No hay datos exactos en este minuto."
            }
        } else {
            // Inferred logic
            if progress > 0.6 {
                pqt = Int(Double(session?.memoryPacketsCount ?? 420) * 0.15)
                state = "Sueño REM (Inferido)"
                icon = "sparkles"
                insight = "Consolidación emocional activa. Detectamos alta actividad talamocortical en esta fase."
            } else if progress < 0.3 {
                pqt = Int(Double(session?.memoryPacketsCount ?? 420) * 0.08)
                state = "Sueño Profundo (Inferido)"
                icon = "brain.fill"
                insight = "Recuperación física y limpieza glinfática. Ondas delta dominantes."
            } else {
                pqt = Int(Double(session?.memoryPacketsCount ?? 420) * 0.03)
                state = "Sueño Ligero (Inferido)"
                icon = "moon.fill"
                insight = "Transición neuronal. Procesamiento de información periférica."
            }
        }
        
        return NeuralData(time: timeString, state: state, icon: icon, memoryFragments: "\(pqt) pqt", insight: insight)
    }
}

#Preview {
    ZStack { Color.somBackground.ignoresSafeArea(); SleepTopographyView(session: SleepSession.mock) }
}
