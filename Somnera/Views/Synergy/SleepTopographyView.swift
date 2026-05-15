import SwiftUI

struct NeuralData {
    let time: String
    let state: String
    let icon: String
    let memoryFragments: String
    let insight: String
}

struct SleepTopographyView: View {
    // Parámetros
    let timePoints = 40 
    let depthPoints = 12 
    let totalWidth: CGFloat = 350
    
    @State private var dragX: CGFloat? = nil
    @State private var hapticTrigger = false
    
    // Colores
    let goldColor = Color(red: 1.0, green: 0.84, blue: 0.0)
    let dreamColor = Color.purple
    let deepColor = Color.indigo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Topografía de la Conciencia")
                    .font(.headline).foregroundColor(.white)
                Text("Análisis de Consolidación de Memoria y Sueños")
                    .font(.caption).foregroundColor(.somTextSecondary)
            }
            .padding(.horizontal)
            
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
                            
                            // DETECCIÓN DE COLISIÓN HÁPTICA (Sincronizada con el Motor de Entropía)
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
            
            NeuralInsightCard(dragX: dragX, totalWidth: totalWidth)
                .padding(.horizontal)
            
            // Cápsulas y Stats (Manteniendo el layout)
            VStack(alignment: .leading, spacing: 12) {
                Text("Arquitectura de Sueño").font(.system(size: 10, weight: .bold)).foregroundColor(.somTextSecondary).tracking(2).textCase(.uppercase)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        SleepDataCapsule(label: "Despierto", value: "15m", color: .somAccent)
                        SleepDataCapsule(label: "REM", value: "2h 10m", color: .purple)
                        SleepDataCapsule(label: "Ligero", value: "3h 45m", color: .cyan)
                        SleepDataCapsule(label: "Profundo", value: "1h 25m", color: .indigo)
                    }
                }
            }.padding(.horizontal)
            
            HStack(spacing: 15) {
                statItem(label: "Consolidación", value: "88%", color: .purple)
                statItem(label: "Memoria", value: "420 pqt", color: .somAccent)
                statItem(label: "Ensueño", value: "Alta", color: .indigo)
            }.padding(.horizontal)
        }
        .padding(.vertical).background(Color.somBackground)
    }
    
    // MARK: - Entropy Engine Logic
    
    private func getSparkPos(id: Int, time: Double) -> (x: CGFloat, yProgress: CGFloat, opacity: Double) {
        // Fórmula de Entropía para Spawn Points
        // Usamos una combinación de ruido basada en tiempo e ID para que sea impredecible pero consistente por frame
        let speed = 0.4
        let lifecycle = (time * speed + Double(id) * 0.731).truncatingRemainder(dividingBy: 1.0)
        let opacity = sin(lifecycle * .pi)
        
        // Solo spawneamos en la zona central de consolidación (40% al 60% del ancho)
        let zoneStart: CGFloat = totalWidth * 0.35
        let zoneEnd: CGFloat = totalWidth * 0.65
        let range = zoneEnd - zoneStart
        
        // Posición X basada en una semilla de entropía que cambia cada ciclo
        let cycleId = floor(time * speed + Double(id) * 0.731)
        let xSeed = sin(cycleId * 987.654 + Double(id) * 123.456)
        let xPos = zoneStart + range * (abs(xSeed))
        
        // Variación vertical (yProgress)
        let ySeed = cos(cycleId * 456.789 + Double(id) * 321.654)
        let yProgress = 0.5 + ySeed * 0.2
        
        // Destello suave al final
        var expansion: CGFloat = 0
        if lifecycle > 0.8 {
            expansion = CGFloat(sin((lifecycle - 0.8) / 0.2 * .pi)) * 2.5
        }
        
        return (xPos + expansion*0.1, yProgress, opacity)
    }
    
    private func checkSparkCollision(at x: CGFloat, time: Double) -> Bool {
        // Comprobar colisión con cualquiera de los 15 fragmentos activos por entropía
        for i in 0..<15 {
            let spark = getSparkPos(id: i, time: time)
            if spark.opacity > 0.5 && abs(x - spark.x) < 3 {
                return true
            }
        }
        return false
    }
    
    private func drawNeuralMap(in context: GraphicsContext, size: CGSize, time: Double) {
        let colWidth = size.width / CGFloat(timePoints - 1)
        let centerY = size.height / 2
        
        // 1. Dibujar Ondas Neuronales (Fondo)
        for row in 0..<depthPoints {
            var path = Path()
            let zOffset = CGFloat(row) * 10.0
            let rowOpacity = 1.0 - (Double(row) / Double(depthPoints))
            
            for col in 0..<timePoints {
                let xBase = CGFloat(col) * colWidth
                let sleepDepth = sin(CGFloat(col) * 0.2) * 0.5 + 0.5
                let remIntensity = (col > 15 && col < 25) ? (sin(CGFloat(col) * 0.5) * 0.5 + 0.5) : 0
                let zValue = (remIntensity * 0.2) - sleepDepth
                let px = xBase + (zOffset * 0.5)
                let py = centerY + (zOffset * 0.8) - (zValue * 80)
                
                if col == 0 { path.move(to: CGPoint(x: px, y: py)) }
                else { path.addLine(to: CGPoint(x: px, y: py)) }
            }
            context.stroke(path, with: .linearGradient(Gradient(colors: [dreamColor.opacity(rowOpacity * 0.6), deepColor.opacity(rowOpacity * 0.6)]), startPoint: .zero, endPoint: CGPoint(x: size.width, y: 0)), lineWidth: 1.0)
        }
        
        // 2. Dibujar Fragmentos de Oro (Motor de Entropía + High Glow Style)
        for i in 0..<15 {
            let sparkData = getSparkPos(id: i, time: time)
            if sparkData.opacity > 0 {
                let py = centerY - (sparkData.yProgress * 40)
                
                // Parámetros de Brillo
                let opacity = sparkData.opacity
                let baseSize: CGFloat = 2.0
                let bloomRadius = baseSize * 4.0
                
                // 1. Bloom Multicapa (Efecto Oro Efímero)
                // Capa exterior ultra-suave
                context.fill(Path(ellipseIn: CGRect(x: sparkData.x - bloomRadius, y: py - bloomRadius, width: bloomRadius*2, height: bloomRadius*2)), 
                             with: .color(goldColor.opacity(opacity * 0.15)))
                
                // Capa media de resplandor
                let midGlow = bloomRadius * 0.6
                context.fill(Path(ellipseIn: CGRect(x: sparkData.x - midGlow, y: py - midGlow, width: midGlow*2, height: midGlow*2)), 
                             with: .color(goldColor.opacity(opacity * 0.3)))
                
                // 2. Núcleo Sólido de Oro
                let coreRect = CGRect(x: sparkData.x - baseSize/2, y: py - baseSize/2, width: baseSize, height: baseSize)
                context.fill(Path(ellipseIn: coreRect), with: .color(goldColor.opacity(opacity)))
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

// MARK: - Supporting Views (Identical to before to maintain consistency)

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
    let dragX: CGFloat?; let totalWidth: CGFloat
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
        if progress > 0.4 && progress < 0.6 {
            return NeuralData(time: "03:45 AM", state: "Sueño REM", icon: "sparkles", memoryFragments: "120 pqt", insight: "Consolidación activa de fragmentos de memoria efímera detectada.")
        } else {
            return NeuralData(time: "04:20 AM", state: "Sueño Profundo", icon: "brain.fill", memoryFragments: "45 pqt", insight: "Recuperación cognitiva profunda. Estabilidad neuronal máxima.")
        }
    }
}

#Preview {
    ZStack { Color.somBackground.ignoresSafeArea(); SleepTopographyView() }
}
