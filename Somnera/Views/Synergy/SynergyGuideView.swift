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
                    
                    // SLIDE 4: DIAGNÓSTICO
                    PremiumGuideSlide(
                        title: "Calidad vs Cantidad",
                        subtitle: "PUNTUACIÓN HONESTA",
                        description: "Medimos salud, no cantidad. Un 100% significa silencio absoluto. Si falta un sensor, la hélice se adapta automáticamente para darte un puntaje justo basado solo en lo medido.",
                        visual: AnyView(
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(Color.somSafe.gradient)
                        )
                    ).tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Footer con Indicadores y Botón
                VStack(spacing: 20) {
                    HStack(spacing: 8) {
                        ForEach(0..<4) { i in
                            Circle()
                                .fill(currentPage == i ? Color.somAccent : Color.white.opacity(0.2))
                                .frame(width: 6, height: 6)
                                .scaleEffect(currentPage == i ? 1.5 : 1.0)
                        }
                    }
                    
                    Button {
                        if currentPage < 3 {
                            withAnimation { currentPage += 1 }
                        } else {
                            dismiss()
                        }
                    } label: {
                        Text(currentPage < 3 ? "CONTINUAR" : "COMENZAR")
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
        ZStack {
            // Un pequeño extracto de la hélice
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let now = timeline.date.timeIntervalSinceReferenceDate
                    let centerY = size.height / 2
                    for i in 0..<30 {
                        let x = CGFloat(i) * 8 + 30
                        let angle = (Double(i) * 0.3) + (now * 2)
                        let y1 = centerY + sin(angle) * 30
                        let y2 = centerY - sin(angle) * 30
                        
                        let color: Color = abs(sin(now * 0.5)) > 0.7 ? .red : .somSafe
                        
                        context.fill(Path(ellipseIn: CGRect(x: x, y: y1, width: 4, height: 4)), with: .color(.somAccent))
                        context.fill(Path(ellipseIn: CGRect(x: x, y: y2, width: 4, height: 4)), with: .color(color))
                    }
                }
            }
        }
    }
}

struct TopographyVisualDemo: View {
    var body: some View {
        Canvas { context, size in
            let centerY = size.height / 2 + 20
            var path = Path()
            path.move(to: CGPoint(x: 50, y: centerY))
            path.addCurve(to: CGPoint(x: 150, y: centerY - 60), control1: CGPoint(x: 100, y: centerY), control2: CGPoint(x: 120, y: centerY - 60))
            path.addCurve(to: CGPoint(x: 250, y: centerY + 40), control1: CGPoint(x: 180, y: centerY - 60), control2: CGPoint(x: 220, y: centerY + 40))
            
            context.stroke(path, with: .linearGradient(Gradient(colors: [.purple, .indigo]), startPoint: .zero, endPoint: CGPoint(x: 300, y: 0)), lineWidth: 3)
            
            // Labels explicativas en el demo
            context.draw(Text("REM").font(.caption.bold()).foregroundColor(.purple), at: CGPoint(x: 150, y: centerY - 80))
            context.draw(Text("PROFUNDO").font(.caption.bold()).foregroundColor(.indigo), at: CGPoint(x: 250, y: centerY + 60))
        }
    }
}

struct SparklesVisualDemo: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            ZStack {
                ForEach(0..<15) { i in
                    Circle()
                        .fill(Color(red: 1.0, green: 0.8, blue: 0.2))
                        .frame(width: CGFloat.random(in: 2...6))
                        .offset(x: CGFloat.random(in: -100...100), y: CGFloat.random(in: -60...60))
                        .opacity(abs(sin(timeline.date.timeIntervalSinceReferenceDate * 2 + Double(i))))
                        .blur(radius: 1)
                }
                
                Image(systemName: "sparkles")
                    .font(.system(size: 50))
                    .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.2))
                    .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.2).opacity(0.5), radius: 20)
            }
        }
    }
}

#Preview {
    SynergyGuideView()
}
