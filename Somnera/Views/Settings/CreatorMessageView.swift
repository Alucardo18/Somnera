import SwiftUI

struct CreatorMessageView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showDonationsSheet = false
    
    var body: some View {
        ZStack {
            Color.somBackground.ignoresSafeArea()
            
            // Animated Starfield Background
            StarfieldBackground()
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Header con foto o avatar
                    ZStack {
                        Circle()
                            .fill(Color.somAccent.opacity(0.2))
                            .frame(width: 120, height: 120)
                            .blur(radius: 20)
                        
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundStyle(Color.somAccent.gradient)
                    }
                    .padding(.top, 40)
                    
                    VStack(spacing: 12) {
                        Text("Hola, soy Emmanuel González")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Creador de Somnera")
                            .font(.subheadline.bold())
                            .foregroundColor(.somAccent)
                    }
                    
                    VStack(alignment: .leading, spacing: 20) {
                        messageParagraph("Como muchas personas más, padecí apnea del sueño y sé lo terrible que se siente. La falta de energía, el riesgo constante y la incertidumbre de no saber qué pasa mientras duermes.")
                        
                        messageParagraph("Probé muchas apps y algunas eran buenas, pero extremadamente caras y carecían de un análisis profundo usando nuevas tecnologías como Machine Learning o IA, y muchas comprometían tu privacidad enviando audio a la nube.")
                        
                        messageParagraph("Es por eso que esta app es gratuita y procesa todo 100% localmente. Espero que te ayude a identificar tus patrones de sueño y ronquido para que puedas tomar acción sobre tu salud.")
                        
                        messageParagraph("Si gustas contribuir donando, me ayudarías a cubrir los costos de la licencia de la tienda y a seguir manteniendo esta aplicación gratuita para todos.")
                    }
                    .padding(.horizontal, 24)
                    
                    // Botón de Donación (Placeholder)
                    Button {
                        showDonationsSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                            Text("Apoyar el Proyecto")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.somAccent.opacity(0.5), lineWidth: 1)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 24)
                    
                    Button("Cerrar") {
                        dismiss()
                    }
                    .font(.caption)
                    .foregroundColor(.somTextSecondary)
                    .padding(.bottom, 40)
                }
            }
            .sheet(isPresented: $showDonationsSheet) {
                DonationsView()
            }
        }
    }
    
    private func messageParagraph(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15))
            .foregroundColor(.white.opacity(0.85))
            .lineSpacing(6)
            .multilineTextAlignment(.leading)
            .padding(16)
            .background(Color.white.opacity(0.03))
            .cornerRadius(12)
    }
}

// MARK: - Animated Background Components

struct StarfieldBackground: View {
    @State private var stars: [Star] = (0..<50).map { _ in Star() }
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                
                // Draw Constellation Lines first (Thicker and brighter)
                for i in 0..<stars.count {
                    for j in i+1..<stars.count {
                        let s1 = stars[i]
                        let s2 = stars[j]
                        
                        // Apply drift to positions
                        let p1 = s1.position(in: size, time: time)
                        let p2 = s2.position(in: size, time: time)
                        
                        let distance = sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2))
                        
                        if distance < 120 {
                            let opacity = (1.0 - (distance / 120)) * 0.3
                            var path = Path()
                            path.move(to: p1)
                            path.addLine(to: p2)
                            context.stroke(path, with: .color(.somAccent.opacity(opacity)), lineWidth: 0.8)
                        }
                    }
                }
                
                // Draw Stars
                for star in stars {
                    let opacity = 0.6 + (0.4 * abs(sin(time * star.twinkleSpeed + star.phase)))
                    let pos = star.position(in: size, time: time)
                    
                    context.opacity = opacity
                    let rect = CGRect(x: pos.x - star.size/2, y: pos.y - star.size/2, width: star.size, height: star.size)
                    
                    // 1. Bloom Layer (Larger)
                    context.addFilter(.blur(radius: 4))
                    context.fill(Circle().path(in: rect.insetBy(dx: -4, dy: -4)), with: .color(star.color.opacity(0.5)))
                    
                    // 2. Core
                    context.fill(Circle().path(in: rect), with: .color(.white))
                    
                    // 3. Lens Flare Cross (for large stars)
                    if star.size > 4 {
                        var crossPath = Path()
                        let flareSize = star.size * 2.5
                        crossPath.move(to: CGPoint(x: pos.x - flareSize, y: pos.y))
                        crossPath.addLine(to: CGPoint(x: pos.x + flareSize, y: pos.y))
                        crossPath.move(to: CGPoint(x: pos.x, y: pos.y - flareSize))
                        crossPath.addLine(to: CGPoint(x: pos.x, y: pos.y + flareSize))
                        context.stroke(crossPath, with: .color(.white.opacity(0.6)), lineWidth: 0.5)
                    }
                }
            }
        }
    }
}

struct Star: Identifiable {
    let id = UUID()
    let x = Double.random(in: 0...1)
    let y = Double.random(in: 0...1)
    let size = Double.random(in: 3...7)
    let twinkleSpeed = Double.random(in: 0.4...1.5)
    let phase = Double.random(in: 0...Double.pi * 2)
    let color: Color = Bool.random() ? .white : .somAccent
    let driftX = Double.random(in: -0.02...0.02)
    let driftY = Double.random(in: -0.01...0.01)
    
    func position(in size: CGSize, time: TimeInterval) -> CGPoint {
        // Subtle drift movement
        let dx = sin(time * 0.1 + phase) * 10.0
        let dy = cos(time * 0.08 + phase) * 10.0
        
        return CGPoint(
            x: (x * size.width) + dx,
            y: (y * size.height) + dy
        )
    }
}

#Preview {
    CreatorMessageView()
}
