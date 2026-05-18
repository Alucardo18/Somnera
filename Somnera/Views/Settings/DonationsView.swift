import SwiftUI

struct DonationsView: View {
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("somnera_is_mecenas") private var isMecenas = false
    @AppStorage("somnera_unlocked_totems") private var unlockedTotems = ""
    @AppStorage("somnera_equipped_totem") private var equippedTotem = "cuarzo"
    
    @State private var selectedTotem: Int = 0
    @State private var showApplePaySheet = false
    @State private var payAmount: String = ""
    @State private var payTierName: String = ""
    @State private var paymentState: PaymentState = .idle
    @State private var showSponsorWelcome = false
    @State private var newlyUnlockedTotemId: String = ""
    
    enum PaymentState {
        case idle, processing, success
    }
    
    let totems = [
        TotemInfo(id: "cuarzo", name: "Cuarzo de la Homeostasis", color: .somSafe, description: "Cristal bidireccional que estabiliza el ritmo circadiano y sintoniza los sensores locales. Representa el equilibrio perfecto entre CPU y batería.", mathType: .crystal),
        TotemInfo(id: "piramide", name: "Pirámide Delta", color: .somAccent, description: "Geometría sagrada que amplifica las ondas de sueño profundo y estabiliza el pipeline de audio. Ideal para purgar ruidos percusivos.", mathType: .pyramid),
        TotemInfo(id: "giroscopio", name: "Giroscopio Topográfico", color: .somWarning, description: "Círculos concéntricos de oro líquido que rastrean los micro-movimientos de tu sueño en tiempo real con precisión milimétrica.", mathType: .gyro),
        TotemInfo(id: "tesseracto", name: "Tesseracto del Olvido", color: .somApnea, description: "Un hipercubo tetradimensional que deforma el espacio-tiempo para encapsular las apneas obstructivas antes de que irrumpan tu descanso.", mathType: .tesseract),
        TotemInfo(id: "helice", name: "Hélice de Sinergia", color: .somSafe, description: "Doble hélice entrelazada que representa la comunión perfecta entre tus niveles de SpO2, frecuencia respiratoria y estabilidad cardiaca.", mathType: .helix),
        TotemInfo(id: "astrolabio", name: "Astrolabio de Oro", color: .somWarning, description: "Relojería astrológica calibrada para mapear tu origen de ronquido (Nasal, Palatal o Lingual) con la precisión de los astros.", mathType: .astrolabe),
        TotemInfo(id: "singularidad", name: "Singularidad Áurea", color: .somWarning, description: "Horizonte de sucesos de curvatura de luz absoluta que traga las pesadillas y emite energía pura. La pieza de colección definitiva de Somnera.", mathType: .singularity)
    ]
    
    let tiers = [
        DonationTier(amount: "$32", subtitle: "Patrocinio de Cafeína Líquida", name: "Tótem de Cuarzo", desc: "Compra el café premium que Emmanuel necesita para no quedarse dormido sobre su propio algoritmo de detección a las 3:00 AM.", totemId: "cuarzo"),
        DonationTier(amount: "$56", subtitle: "Ritual Delta", name: "Tótem Piramidal", desc: "Sostén el desarrollo independiente mientras desbloqueas una insignia que vibra junto al logotipo.", totemId: "piramide"),
        DonationTier(amount: "$128", subtitle: "Anillo Topográfico", name: "Tótem Giroscópico", desc: "Potencia el laboratorio y desbloquea una geometría dorada con memoria persistente.", totemId: "giroscopio"),
        DonationTier(amount: "$264", subtitle: "Hipercubo del Silencio", name: "Tótem Tesseracto", desc: "Apoya el motor clínico y desbloquea una reliquia que aparece en tu certificado de mecenas.", totemId: "tesseracto"),
        DonationTier(amount: "$512", subtitle: "Sinergia Viva", name: "Tótem de Hélice", desc: "Desbloquea un emblema de sinergia que acompaña tu logo y celebra tu constancia.", totemId: "helice"),
        DonationTier(amount: "$1024", subtitle: "Astrolabio Áureo", name: "Tótem del Origen", desc: "Mantiene el proyecto libre de anuncios y activa un emblema de precisión estelar.", totemId: "astrolabio"),
        DonationTier(amount: "$2048", subtitle: "Singularidad Suprema", name: "Tótem Final", desc: "El apoyo definitivo: desbloquea la pieza de colección que trasciende el plano físico.", totemId: "singularidad")
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.somBackground.ignoresSafeArea()
                
                // Stars background
                StarfieldBackground()
                    .ignoresSafeArea()
                    .opacity(0.4)
                
                ScrollView {
                    VStack(spacing: 30) {
                        
                        // Header
                        VStack(spacing: 12) {
                            Text("BÓVEDA DE TÓTEMS")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(.somAccent)
                                .tracking(4)
                            
                            Text("Sintoniza tu Sostenibilidad")
                                .font(.system(size: 32, weight: .black, design: .rounded))
                                .foregroundColor(.somTextPrimary)
                            
                            Text("Desbloquea e integra insignias místicas giroscópicas de mecenazgo junto a tu logotipo.")
                                .font(.subheadline)
                                .foregroundColor(.somTextSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                        }
                        .padding(.top, 20)
                        
                        // Totem preview + carousel selector + active tier card
                        VStack(spacing: 18) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color.somSurface.opacity(0.6))
                                    .frame(height: 260)
                                    .somGlassStyle(cornerRadius: 24)

                                ZStack {
                                    Totem3DView(
                                        mathType: totems[selectedTotem].mathType,
                                        color: totems[selectedTotem].color,
                                        isUnlocked: isTotemUnlocked(totems[selectedTotem].id)
                                    )
                                    .frame(width: 170, height: 170)

                                    if !isTotemUnlocked(totems[selectedTotem].id) {
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 28, weight: .bold))
                                            .foregroundColor(.white.opacity(0.14))
                                    }
                                }

                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        if isTotemUnlocked(totems[selectedTotem].id) {
                                            if equippedTotem == totems[selectedTotem].id {
                                                Text("EQUIPADO")
                                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                                    .foregroundColor(.somSafe)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 6)
                                                    .background(Color.somSafe.opacity(0.1))
                                                    .cornerRadius(8)
                                            } else {
                                                Button {
                                                    equippedTotem = totems[selectedTotem].id
                                                } label: {
                                                    Text("EQUIPAR")
                                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                                        .foregroundColor(.white)
                                                        .padding(.horizontal, 10)
                                                        .padding(.vertical, 6)
                                                        .background(Color.somAccent)
                                                        .cornerRadius(8)
                                                }
                                            }
                                        } else {
                                            Text("BLOQUEADO")
                                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                                .foregroundColor(.somTextSecondary)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(Color.white.opacity(0.03))
                                                .cornerRadius(8)
                                        }
                                    }
                                    .padding(16)
                                }
                            }
                            .frame(height: 260)
                            .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 26) {
                                    ForEach(Array(tiers.enumerated()), id: \.offset) { _, tier in
                                        let totemIdx = totems.firstIndex(where: { $0.id == tier.totemId }) ?? 0
                                        VStack(spacing: 10) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.white.opacity(0.02))
                                                    .overlay(
                                                        Circle()
                                                            .stroke(
                                                                totemIdx == selectedTotem ? totems[totemIdx].color.opacity(0.85) : Color.white.opacity(0.10),
                                                                lineWidth: 2
                                                            )
                                                    )
                                                    .frame(width: 76, height: 76)

                                                if isTotemUnlocked(tier.totemId) {
                                                    Totem3DView(mathType: totems[totemIdx].mathType, color: totems[totemIdx].color, isUnlocked: true)
                                                        .frame(width: 44, height: 44)
                                                } else {
                                                    Image(systemName: "lock.fill")
                                                        .font(.system(size: 22, weight: .bold))
                                                        .foregroundColor(.white.opacity(0.18))
                                                }
                                            }
                                            .contentShape(Circle())
                                            .onTapGesture {
                                                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                                    selectedTotem = totemIdx
                                                }
                                            }

                                            Text(tier.amount)
                                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                                .foregroundColor(totemIdx == selectedTotem ? totems[totemIdx].color : .somTextSecondary.opacity(0.6))
                                        }
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.bottom, 6)
                            }

                            let activeTier = tiers.first(where: { $0.totemId == totems[selectedTotem].id }) ?? tiers[0]
                            VStack(spacing: 10) {
                                Text(activeTier.name.uppercased())
                                    .font(.system(size: 28, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)

                                Text(activeTier.subtitle)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(totems[selectedTotem].color)

                                Text(activeTier.desc)
                                    .font(.system(size: 15, weight: .regular, design: .rounded))
                                    .foregroundColor(.somTextSecondary)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(5)
                                    .padding(.horizontal, 24)

                                Button {
                                    triggerMockPurchase(activeTier)
                                } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: "apple.logo")
                                            .font(.system(size: 18, weight: .bold))
                                        Text("Contribuir con \(activeTier.amount)")
                                            .font(.system(.headline, design: .rounded).bold())
                                    }
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .background(Color.white)
                                    .cornerRadius(18)
                                }
                                .padding(.horizontal, 24)
                                .padding(.top, 8)
                            }
                            .padding(.top, 8)
                        }
                        
                        // Disclaimer
                        Text("Los montos son simulaciones lúdicas de Apple Pay. Apoyas de forma directa e independiente al creador. Cada donación desbloquea permanentemente un tótem visual en tu bóveda personal.")
                            .font(.system(size: 10))
                            .foregroundColor(.somTextSecondary.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                            .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Mecenas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .foregroundColor(.somAccent)
                }
            }
            .sheet(isPresented: $showApplePaySheet) {
                mockApplePayView
                    .presentationDetents([.fraction(0.35)])
            }
            .fullScreenCover(isPresented: $showSponsorWelcome) {
                SponsorWelcomeView(isPresented: $showSponsorWelcome, autoDismissAfter: 7.0)
            }
        }
    }
    
    private func isTotemUnlocked(_ totemId: String) -> Bool {
        // Base totem is always unlocked
        if totemId == "cuarzo" { return true }
        return unlockedTotems.contains(totemId)
    }
    
    private func triggerMockPurchase(_ tier: DonationTier) {
        payAmount = tier.amount
        payTierName = tier.name
        newlyUnlockedTotemId = tier.totemId
        paymentState = .idle
        showApplePaySheet = true
    }
    
    // MARK: - Mock Apple Pay View
    private var mockApplePayView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                HStack {
                    Image(systemName: "apple.logo")
                        .foregroundColor(.white)
                        .font(.title2)
                    Text("Pay")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                if paymentState == .idle {
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("COMPRA")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.gray)
                                Text(payTierName)
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            Text(payAmount)
                                .font(.system(.title3, design: .rounded).bold())
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 24)
                        
                        Divider()
                            .background(Color.white.opacity(0.2))
                        
                        // Fake FaceID button
                        Button {
                            confirmPayment()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "faceid")
                                    .font(.title2)
                                Text("Doble Clic para Pagar")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.somAccent)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 24)
                    }
                } else if paymentState == .processing {
                    VStack(spacing: 20) {
                        ProgressView()
                            .tint(.somAccent)
                            .scaleEffect(1.5)
                        Text("Verificando con Face ID...")
                            .font(.subheadline)
                            .foregroundColor(.somTextSecondary)
                    }
                    .padding(.top, 10)
                } else if paymentState == .success {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.somSafe)
                        Text("Pago Completado")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                        Text("Has desbloqueado un nuevo Tótem de Sueño")
                            .font(.caption)
                            .foregroundColor(.somTextSecondary)
                    }
                }
                Spacer()
            }
        }
    }
    
    private func confirmPayment() {
        withAnimation {
            paymentState = .processing
        }
        
        // Simular verificación de Face ID de 1.8 segundos
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation {
                paymentState = .success
            }
            
            // Register mecenas status and unlock totem
            isMecenas = true
            if !unlockedTotems.contains(newlyUnlockedTotemId) {
                if unlockedTotems.isEmpty {
                    unlockedTotems = newlyUnlockedTotemId
                } else {
                    unlockedTotems += ",\(newlyUnlockedTotemId)"
                }
            }
            
            // Auto equip new totem
            equippedTotem = newlyUnlockedTotemId
            
            // Dismiss payment screen and show SponsorWelcome screen after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                showApplePaySheet = false
                showSponsorWelcome = true
            }
        }
    }
}

// MARK: - Supporting Data Structures

struct TotemInfo: Identifiable {
    let id: String
    let name: String
    let color: Color
    let description: String
    let mathType: TotemMathType
}

struct DonationTier: Identifiable {
    let id = UUID()
    let amount: String
    let subtitle: String
    let name: String
    let desc: String
    let totemId: String
}

enum TotemMathType {
    case crystal, pyramid, gyro, tesseract, helix, astrolabe, singularity
}

// MARK: - 3D Render Canvas Totem Engine

struct Totem3DView: View {
    let mathType: TotemMathType
    let color: Color
    let isUnlocked: Bool
    
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / 24.0)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let width = size.width
                let height = size.height
                let midX = width / 2
                let midY = height / 2
                
                // Color configuration: Locked totems render in monotone gray
                let activeColor = isUnlocked ? color : Color.somTextSecondary.opacity(0.3)
                
                switch mathType {
                case .crystal:
                    drawCrystal(context: context, midX: midX, midY: midY, time: time, color: activeColor)
                case .pyramid:
                    drawPyramid(context: context, midX: midX, midY: midY, time: time, color: activeColor)
                case .gyro:
                    drawGyro(context: context, midX: midX, midY: midY, time: time, color: activeColor)
                case .tesseract:
                    drawTesseract(context: context, midX: midX, midY: midY, time: time, color: activeColor)
                case .helix:
                    drawHelix(context: context, midX: midX, midY: midY, time: time, color: activeColor)
                case .astrolabe:
                    drawAstrolabe(context: context, midX: midX, midY: midY, time: time, color: activeColor)
                case .singularity:
                    drawSingularity(context: context, midX: midX, midY: midY, time: time, color: activeColor)
                }
            }
        }
    }
    
    // CRYSTAL: Double Pyramidal Octahedron
    private func drawCrystal(context: GraphicsContext, midX: CGFloat, midY: CGFloat, time: Double, color: Color) {
        let t = time * 0.8
        let radiusX: CGFloat = 35
        let radiusY: CGFloat = 16
        let height: CGFloat = 55
        
        let top = CGPoint(x: midX, y: midY - height)
        let bottom = CGPoint(x: midX, y: midY + height)
        
        var points: [CGPoint] = []
        for i in 0..<4 {
            let angle = t + Double(i) * .pi / 2
            let x = midX + CGFloat(cos(angle)) * radiusX
            let y = midY + CGFloat(sin(angle)) * radiusY
            points.append(CGPoint(x: x, y: y))
        }
        
        // Draw sides
        for i in 0..<4 {
            let p1 = points[i]
            let p2 = points[(i + 1) % 4]
            
            // Top pyramid face
            var pathTop = Path()
            pathTop.move(to: top)
            pathTop.addLine(to: p1)
            pathTop.addLine(to: p2)
            pathTop.closeSubpath()
            context.stroke(pathTop, with: .color(color.opacity(0.6)), lineWidth: 1.0)
            context.fill(pathTop, with: .color(color.opacity(0.08)))
            
            // Bottom pyramid face
            var pathBot = Path()
            pathBot.move(to: bottom)
            pathBot.addLine(to: p1)
            pathBot.addLine(to: p2)
            pathBot.closeSubpath()
            context.stroke(pathBot, with: .color(color.opacity(0.6)), lineWidth: 1.0)
            context.fill(pathBot, with: .color(color.opacity(0.08)))
        }
        
        // Draw equator line
        var equator = Path()
        equator.move(to: points[0])
        for p in points.dropFirst() {
            equator.addLine(to: p)
        }
        equator.closeSubpath()
        context.stroke(equator, with: .color(color), lineWidth: 1.5)
    }
    
    // PYRAMID: Delta Wave Tetrahedron
    private func drawPyramid(context: GraphicsContext, midX: CGFloat, midY: CGFloat, time: Double, color: Color) {
        let t = time * 0.7
        let radius: CGFloat = 38
        let height: CGFloat = 45
        
        let apex = CGPoint(x: midX, y: midY - height * 0.8)
        
        var basePoints: [CGPoint] = []
        for i in 0..<3 {
            let angle = t + Double(i) * 2.0 * .pi / 3.0
            let x = midX + CGFloat(cos(angle)) * radius
            let y = midY + height * 0.4 + CGFloat(sin(angle)) * (radius * 0.4)
            basePoints.append(CGPoint(x: x, y: y))
        }
        
        // Draw Base
        var base = Path()
        base.move(to: basePoints[0])
        base.addLine(to: basePoints[1])
        base.addLine(to: basePoints[2])
        base.closeSubpath()
        context.stroke(base, with: .color(color.opacity(0.8)), lineWidth: 1.2)
        context.fill(base, with: .color(color.opacity(0.05)))
        
        // Draw Faces
        for i in 0..<3 {
            let p1 = basePoints[i]
            let p2 = basePoints[(i+1)%3]
            var face = Path()
            face.move(to: apex)
            face.addLine(to: p1)
            face.addLine(to: p2)
            face.closeSubpath()
            context.stroke(face, with: .color(color), lineWidth: 1.5)
            context.fill(face, with: .color(color.opacity(0.1)))
        }
        
        // Pulse glow node at apex
        let pulseSize = 6 + CGFloat(sin(time * 3.0)) * 2
        let pulseRect = CGRect(x: apex.x - pulseSize/2, y: apex.y - pulseSize/2, width: pulseSize, height: pulseSize)
        context.fill(Circle().path(in: pulseRect), with: .color(color))
    }
    
    // GYRO: Topographic Concentric Rings
    private func drawGyro(context: GraphicsContext, midX: CGFloat, midY: CGFloat, time: Double, color: Color) {
        let t = time
        
        // Outer ring (Horizontal rotation)
        let w1 = 50 * CGFloat(abs(cos(t * 0.6)))
        let h1: CGFloat = 50
        context.stroke(Ellipse().path(in: CGRect(x: midX - w1, y: midY - h1, width: w1*2, height: h1*2)), with: .color(color.opacity(0.3)), lineWidth: 1.5)
        
        // Middle ring (Vertical rotation)
        let w2: CGFloat = 36
        let h2 = 36 * CGFloat(abs(sin(t * 0.9)))
        context.stroke(Ellipse().path(in: CGRect(x: midX - w2, y: midY - h2, width: w2*2, height: h2*2)), with: .color(color.opacity(0.6)), lineWidth: 1.5)
        
        // Inner ring (Diagonal rotation)
        let twist = t * 1.2
        let w3 = 20 * CGFloat(abs(sin(twist)))
        let h3 = 20 * CGFloat(abs(cos(twist)))
        context.stroke(Ellipse().path(in: CGRect(x: midX - w3, y: midY - h3, width: w3*2, height: h3*2)), with: .color(color), lineWidth: 2.0)
        
        // Glowing center core
        let coreRadius: CGFloat = 6 + CGFloat(sin(time * 5.0)) * 1.5
        context.fill(Circle().path(in: CGRect(x: midX - coreRadius, y: midY - coreRadius, width: coreRadius*2, height: coreRadius*2)), with: .color(.white))
    }
    
    // TESSERACT: 4D Isometric Wireframe Hypercube
    private func drawTesseract(context: GraphicsContext, midX: CGFloat, midY: CGFloat, time: Double, color: Color) {
        let t = time * 0.6
        
        // 3D vertices definition for a unit cube
        let baseVertices: [[CGFloat]] = [
            [-1, -1, -1], [1, -1, -1], [1, 1, -1], [-1, 1, -1],
            [-1, -1,  1], [1, -1,  1], [1, 1,  1], [-1, 1,  1]
        ]
        
        // Rotation angles
        let ax = t
        let ay = t * 0.7
        
        // Projection helper
        func project(_ v: [CGFloat], scale: CGFloat) -> CGPoint {
            var x = v[0]
            var y = v[1]
            var z = v[2]
            
            // Rotation Y
            let x_y = x * CGFloat(cos(ay)) - z * CGFloat(sin(ay))
            let z_y = x * CGFloat(sin(ay)) + z * CGFloat(cos(ay))
            x = x_y
            z = z_y
            
            // Rotation X
            let y_x = y * CGFloat(cos(ax)) - z * CGFloat(sin(ax))
            let z_x = y * CGFloat(sin(ax)) + z * CGFloat(cos(ax))
            y = y_x
            z = z_x
            
            // Isometric 3D to 2D projection
            let px = midX + (x - z) * scale * 0.866
            let py = midY + y * scale + (x + z) * scale * 0.5
            return CGPoint(x: px, y: py)
        }
        
        let outerScale: CGFloat = 28
        let innerScale: CGFloat = 14
        
        let outerPoints = baseVertices.map { project($0, scale: outerScale) }
        let innerPoints = baseVertices.map { project($0, scale: innerScale) }
        
        let cubeEdges = [
            (0,1), (1,2), (2,3), (3,0),
            (4,5), (5,6), (6,7), (7,4),
            (0,4), (1,5), (2,6), (3,7)
        ]
        
        // Draw Outer Cube (Thicker)
        for edge in cubeEdges {
            var outerPath = Path()
            outerPath.move(to: outerPoints[edge.0])
            outerPath.addLine(to: outerPoints[edge.1])
            context.stroke(outerPath, with: .color(color), lineWidth: 1.5)
        }
        
        // Draw Inner Cube (Finer)
        for edge in cubeEdges {
            var innerPath = Path()
            innerPath.move(to: innerPoints[edge.0])
            innerPath.addLine(to: innerPoints[edge.1])
            context.stroke(innerPath, with: .color(color.opacity(0.5)), lineWidth: 0.8)
        }
        
        // Connect Outer and Inner Cubes (Tesseract warp lines)
        for i in 0..<8 {
            var connectingPath = Path()
            connectingPath.move(to: outerPoints[i])
            connectingPath.addLine(to: innerPoints[i])
            context.stroke(connectingPath, with: .color(color.opacity(0.4)), lineWidth: 0.8)
        }
    }
    
    // HELIX: Synergy Double Helix (ADN)
    private func drawHelix(context: GraphicsContext, midX: CGFloat, midY: CGFloat, time: Double, color: Color) {
        let t = time * 2.0
        let steps = 11
        let amplitude: CGFloat = 24
        let totalHeight: CGFloat = 80
        
        var pointsA: [CGPoint] = []
        var pointsB: [CGPoint] = []
        
        for i in 0..<steps {
            let ratio = CGFloat(i) / CGFloat(steps - 1)
            let y = midY - (totalHeight/2) + ratio * totalHeight
            
            // Phase twist along y-axis
            let phase = t + Double(ratio) * .pi * 2.2
            let xA = midX + CGFloat(cos(phase)) * amplitude
            let xB = midX - CGFloat(cos(phase)) * amplitude
            
            pointsA.append(CGPoint(x: xA, y: y))
            pointsB.append(CGPoint(x: xB, y: y))
            
            // Draw horizontal rung (base pairs) with varying opacity based on depth
            let depthOpacity = 0.2 + 0.8 * (sin(phase) + 1.0) / 2.0
            var rung = Path()
            rung.move(to: CGPoint(x: xA, y: y))
            rung.addLine(to: CGPoint(x: xB, y: y))
            context.stroke(rung, with: .color(color.opacity(0.3 * depthOpacity)), lineWidth: 1.0)
            
            // Draw nodes
            let nodeSize: CGFloat = 5
            context.fill(Circle().path(in: CGRect(x: xA - nodeSize/2, y: y - nodeSize/2, width: nodeSize, height: nodeSize)), with: .color(color))
            context.fill(Circle().path(in: CGRect(x: xB - nodeSize/2, y: y - nodeSize/2, width: nodeSize, height: nodeSize)), with: .color(color.opacity(0.6)))
        }
        
        // Draw outer rails
        var railA = Path()
        railA.move(to: pointsA[0])
        for p in pointsA.dropFirst() {
            railA.addLine(to: p)
        }
        context.stroke(railA, with: .color(color), lineWidth: 1.5)
        
        var railB = Path()
        railB.move(to: pointsB[0])
        for p in pointsB.dropFirst() {
            railB.addLine(to: p)
        }
        context.stroke(railB, with: .color(color.opacity(0.5)), lineWidth: 1.2)
    }
    
    // ASTROLABE: Astrological Celestial Mechanism
    private func drawAstrolabe(context: GraphicsContext, midX: CGFloat, midY: CGFloat, time: Double, color: Color) {
        let t = time * 0.4
        let baseRadius: CGFloat = 45
        
        // 1. Outer celestial coordinate circle (Dotted ring)
        let outerRect = CGRect(x: midX - baseRadius, y: midY - baseRadius, width: baseRadius*2, height: baseRadius*2)
        context.stroke(Circle().path(in: outerRect), with: .color(color.opacity(0.2)), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
        
        // 2. Solid brass ring
        let midRect = CGRect(x: midX - baseRadius * 0.85, y: midY - baseRadius * 0.85, width: baseRadius * 1.7, height: baseRadius * 1.7)
        context.stroke(Circle().path(in: midRect), with: .color(color.opacity(0.5)), lineWidth: 1.5)
        
        // 3. Rotating coordinate lines
        let lineCount = 8
        for i in 0..<lineCount {
            let angle = t + Double(i) * .pi / Double(lineCount/2)
            let length = baseRadius * 0.85
            let endX = midX + CGFloat(cos(angle)) * length
            let endY = midY + CGFloat(sin(angle)) * length
            
            var coordLine = Path()
            coordLine.move(to: CGPoint(x: midX, y: midY))
            coordLine.addLine(to: CGPoint(x: endX, y: endY))
            context.stroke(coordLine, with: .color(color.opacity(0.25)), lineWidth: 0.8)
        }
        
        // 4. Astrolabe Reti/Pointer (Thick needle)
        let needleAngle = -t * 2.2
        let needleLen = baseRadius * 0.75
        let needleX = midX + CGFloat(cos(needleAngle)) * needleLen
        let needleY = midY + CGFloat(sin(needleAngle)) * needleLen
        
        var needle = Path()
        needle.move(to: CGPoint(x: midX, y: midY))
        needle.addLine(to: CGPoint(x: needleX, y: needleY))
        context.stroke(needle, with: .color(color), lineWidth: 2.0)
        
        // Core brass center node
        context.fill(Circle().path(in: CGRect(x: midX - 4, y: midY - 4, width: 8, height: 8)), with: .color(color))
    }
    
	    // SINGULARITY: Einsteinian Accretion Lens Black Hole
	    private func drawSingularity(context: GraphicsContext, midX: CGFloat, midY: CGFloat, time: Double, color: Color) {
	        var context = context
	        let coreRadius: CGFloat = 21
	        let orbitRadius: CGFloat = 42
	        let clipPath = Path(ellipseIn: CGRect(x: midX - 52, y: midY - 52, width: 104, height: 104))
	        context.clip(to: clipPath)
	        
	        let obsidian = Color(hex: "#050509")
	        let gold = Color(hex: "#F5D37A")
	        let accentNebula = Color.somAccent
	        
	        // Nebula (Somnera accent haze)
	        context.drawLayer { localContext in
	            localContext.addFilter(.blur(radius: 26))
	            
	            let drift = CGFloat(sin(time * 0.6)) * 6
	            let hazeRect = CGRect(x: midX - 58 + drift, y: midY - 46, width: 116, height: 92)
	            localContext.fill(
	                Path(ellipseIn: hazeRect),
	                with: .color(accentNebula.opacity(0.10))
	            )
	            
	            let hazeRect2 = CGRect(x: midX - 44, y: midY - 64 + drift * 0.6, width: 88, height: 128)
	            localContext.fill(
	                Path(ellipseIn: hazeRect2),
	                with: .color(accentNebula.opacity(0.06))
	            )
	        }
	        
	        // Subtle lens glow around the horizon
	        context.drawLayer { localContext in
	            localContext.addFilter(.blur(radius: 14))
	            let glow = coreRadius * 2.2 + CGFloat(sin(time * 1.6)) * 2
	            let rect = CGRect(x: midX - glow, y: midY - glow, width: glow * 2, height: glow * 2)
	            localContext.fill(Path(ellipseIn: rect), with: .color(accentNebula.opacity(0.18)))
	            localContext.fill(Path(ellipseIn: rect.insetBy(dx: 8, dy: 8)), with: .color(gold.opacity(0.08)))
	        }
	        
	        // Obsidian event horizon core (slight specular, faint rim)
	        let coreRect = CGRect(x: midX - coreRadius, y: midY - coreRadius, width: coreRadius * 2, height: coreRadius * 2)
	        context.fill(Path(ellipseIn: coreRect), with: .color(obsidian))
	        context.stroke(Path(ellipseIn: coreRect), with: .color(accentNebula.opacity(0.25)), lineWidth: 1)
	        
	        // Specular highlight to sell "obsidian"
	        context.drawLayer { localContext in
	            localContext.addFilter(.blur(radius: 8))
	            let highlightRect = CGRect(x: midX - coreRadius * 0.9, y: midY - coreRadius * 1.1, width: coreRadius * 1.4, height: coreRadius * 1.1)
	            localContext.fill(Path(ellipseIn: highlightRect), with: .color(Color.white.opacity(0.05)))
	        }
	        
	        // Gold particles orbiting (accretion swarm)
	        let particleCount = 16
	        for i in 0..<particleCount {
	            let phase = Double(i) * (2.0 * .pi / Double(particleCount))
	            let speed = 1.35 + Double(i % 3) * 0.18
	            let angle = time * speed + phase
	            
	            let radialWobble = CGFloat(sin(time * 0.9 + phase)) * 3
	            let rx = orbitRadius + radialWobble
	            let ry = (orbitRadius * 0.34) + radialWobble * 0.18
	            
	            let x = midX + CGFloat(cos(angle)) * rx
	            let y = midY - 5 + CGFloat(sin(angle)) * ry
	            
	            let sparkle = 1.6 + CGFloat(sin(time * 2.2 + phase)) * 0.9
	            let alpha = 0.35 + (CGFloat(cos(angle + .pi / 2)) + 1) * 0.18
	            
	            let pRect = CGRect(x: x - sparkle * 0.5, y: y - sparkle * 0.5, width: sparkle, height: sparkle)
	            context.fill(Path(ellipseIn: pRect), with: .color(gold.opacity(alpha)))
	        }
	        
	        // Golden orbit ring hint (very faint)
	        var ring = Path()
	        let ringSteps = 54
	        for s in 0...ringSteps {
	            let a = Double(s) * 2.0 * .pi / Double(ringSteps)
	            let x = midX + CGFloat(cos(a)) * orbitRadius
	            let y = midY - 5 + CGFloat(sin(a)) * orbitRadius * 0.34
	            if s == 0 { ring.move(to: .init(x: x, y: y)) } else { ring.addLine(to: .init(x: x, y: y)) }
	        }
	        context.stroke(ring, with: .color(gold.opacity(0.10)), lineWidth: 1)
	    }
	}

// Extension to allow easy CGPoint initializers
extension CGPoint {
    init(_ x: CGFloat, _ y: CGFloat) {
        self.init(x: x, y: y)
    }
}

#Preview {
    DonationsView()
}
