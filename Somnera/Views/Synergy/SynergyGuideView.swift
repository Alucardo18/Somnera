import SwiftUI

struct SynergyGuideView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            // Fondo Profundo
            LinearGradient(colors: [Color.somBackground, Color(red: 0.05, green: 0.05, blue: 0.15)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack {
                // Header Minimalista
                HStack {
                    Text("MANUAL DE INTERPRETACIÓN")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(3)
                        .foregroundColor(.white.opacity(0.5))
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                }
                .padding(.horizontal, 25)
                .padding(.top, 20)
                
                TabView(selection: $currentPage) {
                    // SLIDE 1: TOPOGRAFÍA
                    PremiumGuideSlide(
                        title: "Topografía Biológica",
                        subtitle: "PAISAJE DE LA CONSCIENCIA",
                        description: "Este mapa traza tu actividad cerebral nocturna. Los picos y valles se modulan con el ruido de tu entorno y la profundidad de tu sueño, creando un relieve único de tu descanso.",
                        visual: AnyView(TopographyVisualDemo())
                    ).tag(0)
                    
                    // SLIDE 2: MEMORIA
                    PremiumGuideSlide(
                        title: "Consolidación Neural",
                        subtitle: "STELLAR BURSTS",
                        description: "Los destellos dorados ocurren solo en sueño profundo y REM. Representan la fijación de recuerdos; a mayor estabilidad respiratoria, mayor es la densidad de consolidación neuronal.",
                        visual: AnyView(SparklesVisualDemo())
                    ).tag(1)
                    
                    // SLIDE 3: HÉLICE
                    PremiumGuideSlide(
                        title: "Hélice de Sinergia",
                        subtitle: "EL ADN DE TU SALUD",
                        description: "Una visualización que entrelaza tus signos. Si usas Apple Watch, verás cómo tu pulso y oxígeno bailan en sincronía. El paralelismo entre las hebras indica una recuperación biológica óptima.",
                        visual: AnyView(HelixVisualDemo())
                    ).tag(2)
                    
                    // SLIDE 4: HOMEOSTASIS (NUEVO)
                    PremiumGuideSlide(
                        title: "Homeostasis",
                        subtitle: "EL BALANCE VITAL",
                        description: "Tu puntuación no es solo silencio, es un equilibrio médico estricto. La Biosfera 3D evalúa tu duración de sueño (40%) y la calidad de tus signos vitales (60%). Si duermes poco, o hay estrés respiratorio, la esfera se fractura indicando deuda de sueño.",
                        visual: AnyView(BiosphereVisualDemo())
                    ).tag(3)
                    
                    // SLIDE 5: DIAGNÓSTICO
                    PremiumGuideSlide(
                        title: "Calidad vs Cantidad",
                        subtitle: "PUNTUACIÓN HONESTA",
                        description: "Medimos salud de forma dinámica y justa. Si falta un sensor como el Apple Watch, el algoritmo se recalibra automáticamente para evaluarte con máxima rigurosidad solo en base a los sensores activos.",
                        visual: AnyView(
                            ZStack {
                                Circle()
                                    .fill(Color.somSafe.opacity(0.12))
                                    .frame(width: 130, height: 130)
                                    .blur(radius: 20)
                                
                                Image(systemName: "checkmark.shield.fill")
                                    .font(.system(size: 70))
                                    .foregroundStyle(Color.somSafe.gradient)
                                    .shadow(color: .somSafe.opacity(0.4), radius: 15)
                            }
                        )
                    ).tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Footer con Indicadores y Botón
                VStack(spacing: 20) {
                    HStack(spacing: 8) {
                        ForEach(0..<5) { i in
                            Circle()
                                .fill(currentPage == i ? Color.somAccent : Color.white.opacity(0.2))
                                .frame(width: 6, height: 6)
                                .scaleEffect(currentPage == i ? 1.5 : 1.0)
                        }
                    }
                    
                    Button {
                        if currentPage < 4 {
                            withAnimation { currentPage += 1 }
                        } else {
                            dismiss()
                        }
                    } label: {
                        Text(currentPage < 4 ? "CONTINUAR" : "COMENZAR")
                            .font(.system(size: 14, weight: .black))
                            .tracking(2)
                            .foregroundColor(.somBackground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color.white)
                            .cornerRadius(20)
                            .shadow(color: .white.opacity(0.2), radius: 20)
                    }
                }
                .padding(30)
            }
        }
    }
}

struct PremiumGuideSlide: View {
    let title: String
    let subtitle: String
    let description: String
    let visual: AnyView
    
    var body: some View {
        VStack(spacing: 40) {
            // Visual Demo Area
            ZStack {
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.white.opacity(0.03))
                    .frame(height: 250)
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
                
                visual
            }
            .padding(.horizontal, 25)
            
            // Text Content
            VStack(spacing: 12) {
                Text(subtitle)
                    .font(.system(size: 12, weight: .bold))
                    .tracking(4)
                    .foregroundColor(.somAccent)
                
                Text(title)
                    .font(.system(size: 32, weight: .black))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 16))
                    .foregroundColor(.somTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .lineSpacing(6)
            }
            
            Spacer()
        }
        .padding(.top, 40)
    }
}

// --- VISUAL DEMOS ---

struct HelixVisualDemo: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                let centerY = size.height / 2
                let centerX = size.width / 2
                
                let numDots = 24
                let spacing: CGFloat = 8
                let totalWidth = CGFloat(numDots - 1) * spacing
                let startX = centerX - totalWidth / 2
                
                for i in 0..<numDots {
                    let x = startX + CGFloat(i) * spacing
                    let angle = (Double(i) * 0.25) + (now * 2.5)
                    let y1 = centerY + sin(angle) * 35
                    let y2 = centerY - sin(angle) * 35
                    
                    // Draw hebra 1
                    let rect1 = CGRect(x: x - 2, y: y1 - 2, width: 4, height: 4)
                    context.fill(Path(ellipseIn: rect1), with: .color(.somAccent))
                    
                    // Draw hebra 2
                    let rect2 = CGRect(x: x - 2, y: y2 - 2, width: 4, height: 4)
                    context.fill(Path(ellipseIn: rect2), with: .color(.cyan))
                }
            }
        }
    }
}

struct TopographyVisualDemo: View {
    var body: some View {
        Canvas { context, size in
            let centerY = size.height / 2
            let centerX = size.width / 2
            
            var path = Path()
            let width: CGFloat = 200
            let startX = centerX - width / 2
            
            path.move(to: CGPoint(x: startX, y: centerY))
            path.addCurve(
                to: CGPoint(x: centerX, y: centerY - 40),
                control1: CGPoint(x: startX + 50, y: centerY),
                control2: CGPoint(x: startX + 50, y: centerY - 40)
            )
            path.addCurve(
                to: CGPoint(x: centerX + width / 2, y: centerY + 40),
                control1: CGPoint(x: centerX + 50, y: centerY - 40),
                control2: CGPoint(x: centerX + 50, y: centerY + 40)
            )
            
            context.stroke(
                path,
                with: .linearGradient(
                    Gradient(colors: [.somAccent, .somMesh3]),
                    startPoint: CGPoint(x: startX, y: centerY),
                    endPoint: CGPoint(x: startX + width, y: centerY)
                ),
                lineWidth: 4
            )
            
            // Labels explicativas en el demo
            context.draw(
                Text("REM").font(.system(size: 10, weight: .bold, design: .rounded)).foregroundColor(.somAccent),
                at: CGPoint(x: centerX - 30, y: centerY - 65)
            )
            context.draw(
                Text("SUEÑO PROFUNDO").font(.system(size: 10, weight: .bold, design: .rounded)).foregroundColor(.somMesh3),
                at: CGPoint(x: centerX + 40, y: centerY + 65)
            )
        }
    }
}

struct SparklesVisualDemo: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            ZStack {
                Circle()
                    .fill(Color.somAccent.opacity(0.12))
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)
                
                ForEach(0..<12) { i in
                    let angle = Double(i) * (2 * Double.pi / 12)
                    let radius: CGFloat = 45 + sin(timeline.date.timeIntervalSinceReferenceDate * 2 + Double(i)) * 10
                    let x = cos(angle) * radius
                    let y = sin(angle) * radius
                    
                    Circle()
                        .fill(Color.somAccent)
                        .frame(width: 4)
                        .offset(x: x, y: y)
                        .blur(radius: 0.5)
                }
                
                Image(systemName: "sparkles")
                    .font(.system(size: 55))
                    .foregroundColor(.somAccent)
                    .shadow(color: .somAccent.opacity(0.4), radius: 10)
            }
        }
    }
}

struct BiosphereVisualDemo: View {
    @State private var particles: [Particle3D] = []
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                
                let sphereRadius = 55.0 + sin(now * 2.5) * 1.5
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
                    let opacity = max(0.15, min(0.9, (1.2 - p.z) / 2.0))
                    let size = max(1.5, min(5.0, 3.0 * p.scale))
                    let color: Color = p.colorIndex % 3 == 0 ? .cyan : (p.colorIndex % 3 == 1 ? .somAccent : .somMesh3)
                    
                    let rect = CGRect(x: p.x - size/2, y: p.y - size/2, width: size, height: size)
                    context.fill(Path(ellipseIn: rect), with: .color(color.opacity(opacity)))
                }
            }
        }
        .onAppear {
            generateParticles()
        }
    }
    
    private func generateParticles() {
        var temp: [Particle3D] = []
        let N = 35
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
}

#Preview {
    SynergyGuideView()
}
