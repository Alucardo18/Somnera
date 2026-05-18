import SwiftUI

struct DonationsView: View {
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("somnera_is_mecenas") private var isPatrocinador = false
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
        TotemInfo(id: "cuarzo", name: "Cuarzo de la Homeostasis", color: .somAccent, description: "Cristal bidireccional que estabiliza el ritmo circadiano y sintoniza los sensores locales. Representa el equilibrio perfecto entre CPU y batería.", mathType: .crystal),
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
        DonationTier(amount: "$264", subtitle: "Hipercubo del Silencio", name: "Tótem Tesseracto", desc: "Apoya el motor clínico y desbloquea una reliquia que aparece en tu certificado de patrocinador.", totemId: "tesseracto"),
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
                                                    Totem3DView(mathType: totems[totemIdx].mathType, color: totems[totemIdx].color, isUnlocked: true, isStatic: true)
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
            .navigationTitle("Patrocinador")
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
                SponsorRegistrationView(isPresented: $showSponsorWelcome)
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
            
            // Register patrocinador status and unlock totem
            isPatrocinador = true
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
    var isStatic: Bool = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var isAnimating = true
    
    var body: some View {
        Group {
            if isAnimating && !isStatic {
                TimelineView(.periodic(from: .now, by: 1.0 / 24.0)) { timeline in
                    TotemCanvasView(time: timeline.date.timeIntervalSinceReferenceDate)
                }
            } else {
                TotemCanvasView(time: 0)
            }
        }
        .onAppear {
            isAnimating = scenePhase == .active
        }
        .onDisappear {
            isAnimating = false
        }
        .onChange(of: scenePhase) { _, newPhase in
            isAnimating = newPhase == .active
        }
    }

    @ViewBuilder
    private func TotemCanvasView(time: Double) -> some View {
        Canvas { context, size in
            let refSize: CGFloat = 200
            let scale = min(size.width, size.height) / refSize
            
            var context = context
            // Center the coordinate system at the actual canvas center
            context.translateBy(x: size.width / 2, y: size.height / 2)
            // Scale the context based on our reference size
            context.scaleBy(x: scale, y: scale)
            
            // Draw relative to (0, 0) since we translated the center
            let midX: CGFloat = 0
            let midY: CGFloat = 0

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
    
    // CRYSTAL: Minimalist Faceted Obsidian Quartz with Soft Brand Accent Glow & Gentle Floating Drift
    private func drawCrystal(context: GraphicsContext, midX: CGFloat, midY: CGFloat, time: Double, color: Color) {
        var context = context
        
        // 1. Slow, premium levitation drift (very little movement)
        let driftY = CGFloat(sin(time * 0.8)) * 3.5
        let currentMidY = midY + driftY
        
        let width: CGFloat = 18
        let heightPoint: CGFloat = 45 // The straight column height
        let heightCap: CGFloat = 16   // The top pyramid cap height
        
        let capTip = CGPoint(x: midX, y: currentMidY - heightPoint - heightCap)
        let topCenter = CGPoint(x: midX, y: currentMidY - heightPoint)
        
        let topLeft = CGPoint(x: midX - width, y: currentMidY - heightPoint + 4)
        let topRight = CGPoint(x: midX + width, y: currentMidY - heightPoint + 4)
        
        let botLeft = CGPoint(x: midX - width, y: currentMidY + heightPoint)
        let botRight = CGPoint(x: midX + width, y: currentMidY + heightPoint)
        let botCenter = CGPoint(x: midX, y: currentMidY + heightPoint - 4)
        
        // 2. Soft Breathing Glow (Somnera brand accent aura cast behind the crystal)
        let pulseGlow = 0.7 + 0.18 * CGFloat(sin(time * 1.0))
        let glowRect = CGRect(x: midX - 55, y: currentMidY - 65, width: 110, height: 130)
        let glowShader = GraphicsContext.Shading.radialGradient(
            Gradient(colors: [color.opacity(0.20 * Double(pulseGlow)), .clear]),
            center: CGPoint(x: midX, y: currentMidY),
            startRadius: 0,
            endRadius: 50
        )
        context.fill(Path(ellipseIn: glowRect), with: glowShader)
        
        // 3. Facets styling (Rich matte obsidian black tones)
        let leftBase = Color(hex: "#06070B")
        let rightBase = Color(hex: "#0E1118")
        
        // Draw Left Facet (solid fill)
        var leftPath = Path()
        leftPath.move(to: capTip)
        leftPath.addLine(to: topCenter)
        leftPath.addLine(to: botCenter)
        leftPath.addLine(to: botLeft)
        leftPath.addLine(to: topLeft)
        leftPath.closeSubpath()
        context.fill(leftPath, with: .color(leftBase))
        
        // Draw Right Facet (solid fill)
        var rightPath = Path()
        rightPath.move(to: capTip)
        rightPath.addLine(to: topCenter)
        rightPath.addLine(to: botCenter)
        rightPath.addLine(to: botRight)
        rightPath.addLine(to: topRight)
        rightPath.closeSubpath()
        context.fill(rightPath, with: .color(rightBase))
        
        // 4. Vibrant Outer Outline & Center Ridge (Using Somnera brand accent color)
        var outline = Path()
        outline.move(to: capTip)
        outline.addLine(to: topLeft)
        outline.addLine(to: botLeft)
        outline.addLine(to: botCenter)
        outline.addLine(to: botRight)
        outline.addLine(to: topRight)
        outline.closeSubpath()
        
        context.stroke(outline, with: .color(color.opacity(0.85)), lineWidth: 1.2)
        
        // Center dividing ridge line
        var centerRidge = Path()
        centerRidge.move(to: capTip)
        centerRidge.addLine(to: topCenter)
        centerRidge.addLine(to: botCenter)
        context.stroke(centerRidge, with: .color(color.opacity(0.95)), lineWidth: 1.0)
        
        // Cap horizontal facets line
        var capJoint = Path()
        capJoint.move(to: topLeft)
        capJoint.addLine(to: topCenter)
        capJoint.addLine(to: topRight)
        context.stroke(capJoint, with: .color(color.opacity(0.55)), lineWidth: 0.8)
        
        // 5. Specular highlight for premium glossy look
        var glossPath = Path()
        glossPath.move(to: capTip)
        glossPath.addLine(to: topLeft)
        glossPath.addLine(to: botLeft)
        context.stroke(glossPath, with: .color(Color.white.opacity(0.45)), lineWidth: 0.8)
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
    
    // HELIX: Synergy Double Helix (ADN) with Winged Aura (Totem Alado)
    private func drawHelix(context: GraphicsContext, midX: CGFloat, midY: CGFloat, time: Double, color: Color) {
        let t = time * 2.0
        let steps = 11
        let amplitude: CGFloat = 24
        let totalHeight: CGFloat = 80
        
        // Draw majestic energy wings flanking the helix (Winged Totem "Totem Alado")
        let wingPulse = CGFloat(sin(time * 2.2)) * 6.0
        let ribCount = 3
        
        for j in 0..<ribCount {
            let ratio = CGFloat(j) / CGFloat(ribCount - 1)
            let yStart = midY - 15 + CGFloat(j) * 15
            
            // Left wing rib
            var wingLeft = Path()
            let startL = CGPoint(x: midX, y: yStart)
            // Symmetrical sweep outwards and upwards
            let endL = CGPoint(
                x: midX - 22 - CGFloat(j) * 12 - wingPulse * 1.2,
                y: midY - 45 + CGFloat(j) * 10 - wingPulse * 0.6
            )
            let controlL = CGPoint(
                x: midX - 35 - CGFloat(j) * 5 - wingPulse * 0.8,
                y: midY - 15 - wingPulse * 0.3
            )
            wingLeft.move(to: startL)
            wingLeft.addQuadCurve(to: endL, control: controlL)
            
            context.stroke(wingLeft, with: .color(color.opacity(0.4 - Double(j) * 0.1)), lineWidth: 1.2 - CGFloat(j) * 0.2)
            
            // Right wing rib
            var wingRight = Path()
            let startR = CGPoint(x: midX, y: yStart)
            let endR = CGPoint(
                x: midX + 22 + CGFloat(j) * 12 + wingPulse * 1.2,
                y: midY - 45 + CGFloat(j) * 10 - wingPulse * 0.6
            )
            let controlR = CGPoint(
                x: midX + 35 + CGFloat(j) * 5 + wingPulse * 0.8,
                y: midY - 15 - wingPulse * 0.3
            )
            wingRight.move(to: startR)
            wingRight.addQuadCurve(to: endR, control: controlR)
            
            context.stroke(wingRight, with: .color(color.opacity(0.4 - Double(j) * 0.1)), lineWidth: 1.2 - CGFloat(j) * 0.2)
            
            // Glowing tips of the wings
            let tipSize: CGFloat = 3.0 + CGFloat(sin(time * 3.0 + Double(j))) * 0.8
            context.fill(Circle().path(in: CGRect(x: endL.x - tipSize/2, y: endL.y - tipSize/2, width: tipSize, height: tipSize)), with: .color(color))
            context.fill(Circle().path(in: CGRect(x: endR.x - tipSize/2, y: endR.y - tipSize/2, width: tipSize, height: tipSize)), with: .color(color))
        }
        
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
    
    // RESONANCE KNOT: 3D Lissajous Harmonic Resonance Curve representing Snore Origin (Nasal, Palatal, Lingual)
    // Formerly Astrolabe. Renders a continuous glass ribbon in 3D projection rotating slowly with flowing energy pearls.
    private func drawAstrolabe(context: GraphicsContext, midX: CGFloat, midY: CGFloat, time: Double, color: Color) {
        var context = context
        
        let t = time * 0.35 // Cinematic slow rotation
        let floatY = CGFloat(sin(time * 0.75)) * 3.0 // Gentle breathing drift
        let currentMidY = midY + floatY
        
        let radiusX: CGFloat = 38
        let radiusY: CGFloat = 38
        let radiusZ: CGFloat = 20
        
        // 3D rotation angles
        let rotY = t
        let rotX = t * 0.45
        
        // Helper function to project a 3D Lissajous point to 2D screen coordinate with depth (z)
        func project(theta: Double) -> (point: CGPoint, z: CGFloat) {
            // Lissajous frequencies (a=2, b=3, c=1) producing a gorgeous infinite knot
            let x0 = sin(2.0 * theta) * Double(radiusX)
            let y0 = cos(3.0 * theta) * Double(radiusY)
            let z0 = sin(1.0 * theta) * Double(radiusZ)
            
            // Rotate around Y-axis
            let x1 = x0 * cos(rotY) - z0 * sin(rotY)
            let z1 = x0 * sin(rotY) + z0 * cos(rotY)
            
            // Rotate around X-axis
            let y2 = y0 * cos(rotX) - z1 * sin(rotX)
            let z2 = y0 * sin(rotX) + z1 * cos(rotX)
            
            return (CGPoint(x: midX + CGFloat(x1), y: currentMidY + CGFloat(y2)), CGFloat(z2))
        }
        
        // 1. Draw a soft ambient glow behind the resonance knot
        let glowRect = CGRect(x: midX - 60, y: currentMidY - 60, width: 120, height: 120)
        let glowShader = GraphicsContext.Shading.radialGradient(
            Gradient(colors: [color.opacity(0.15), .clear]),
            center: CGPoint(x: midX, y: currentMidY),
            startRadius: 0,
            endRadius: 55
        )
        context.fill(Path(ellipseIn: glowRect), with: glowShader)
        
        // 2. Generate 3D projected points
        let stepCount = 90
        var projectedPoints: [(point: CGPoint, z: CGFloat)] = []
        for i in 0...stepCount {
            let theta = Double(i) * 2.0 * .pi / Double(stepCount)
            projectedPoints.append(project(theta: theta))
        }
        
        // 3. Render the continuous 3D glass ribbon
        // We draw individual segments and map their opacity and thickness to their depth (z) to create a perfect 3D effect.
        let maxZ: CGFloat = radiusZ * 1.5
        
        for i in 0..<stepCount {
            let p1 = projectedPoints[i]
            let p2 = projectedPoints[i+1]
            
            let avgZ = (p1.z + p2.z) / 2.0
            // Normalize z to a 0.0 ... 1.0 range
            let zNorm = (avgZ + maxZ) / (2.0 * maxZ)
            let clampedZNorm = min(max(zNorm, 0.0), 1.0)
            
            let segmentOpacity = 0.18 + 0.62 * clampedZNorm
            let segmentWidth = 1.0 + 2.2 * clampedZNorm
            
            var path = Path()
            path.move(to: p1.point)
            path.addLine(to: p2.point)
            
            // Draw a wider underlying glass shadow for depth
            context.stroke(path, with: .color(color.opacity(segmentOpacity * 0.3)), lineWidth: segmentWidth * 2.0)
            // Draw the core glowing neon line
            context.stroke(path, with: .color(color.opacity(segmentOpacity)), lineWidth: segmentWidth)
        }
        
        // 4. Draw Flowing Energy Pearls (3 nodes of light representing Nasal, Palatal, Lingual pathways)
        let pearlCount = 3
        for k in 0..<pearlCount {
            let progress = time * 0.45 + Double(k) * (2.0 * .pi / Double(pearlCount))
            let wrappedProgress = progress.truncatingRemainder(dividingBy: 2.0 * .pi)
            
            let pearlProj = project(theta: wrappedProgress)
            let zNorm = (pearlProj.z + maxZ) / (2.0 * maxZ)
            let clampedZNorm = min(max(zNorm, 0.0), 1.0)
            
            let sizeGlow = 8.0 * (0.8 + 0.6 * clampedZNorm)
            let sizeCore = 3.0 * (0.8 + 0.6 * clampedZNorm)
            let pearlOpacity = 0.3 + 0.7 * clampedZNorm
            
            let pearlCenter = pearlProj.point
            
            // Outer intense glow aura
            let glowRect = CGRect(x: pearlCenter.x - sizeGlow/2, y: pearlCenter.y - sizeGlow/2, width: sizeGlow, height: sizeGlow)
            context.fill(Circle().path(in: glowRect), with: .color(color.opacity(pearlOpacity * 0.8)))
            
            // Core white light flare
            let coreRect = CGRect(x: pearlCenter.x - sizeCore/2, y: pearlCenter.y - sizeCore/2, width: sizeCore, height: sizeCore)
            context.fill(Circle().path(in: coreRect), with: .color(Color.white.opacity(pearlOpacity)))
        }
    }
    
        // SINGULARITY: 3D Flat Accretion Disk Black Hole using Somnera Brand Accent Gas and dynamic depth sorting
        private func drawSingularity(context: GraphicsContext, midX: CGFloat, midY: CGFloat, time: Double, color: Color) {
            var context = context
            let coreRadius: CGFloat = 21
            
            let clipPath = Path(ellipseIn: CGRect(x: midX - 52, y: midY - 52, width: 104, height: 104))
            context.clip(to: clipPath)
            
            let obsidian = Color(hex: "#020204")
            let gold = Color(hex: "#F5D37A")
            let goldHot = Color(hex: "#FFECA1")
            let goldEdge = Color(hex: "#FF6E14")
            let accentNebula = Color.somAccent // Somnera Accent Brand Color
            
            // 1. Draw Nebula (Somnera accent haze / space-time background)
            let drift = CGFloat(sin(time * 0.5)) * 5
            let hazeRect1 = CGRect(x: midX - 58 + drift, y: midY - 46, width: 116, height: 92)
            let nebulaShader1 = GraphicsContext.Shading.radialGradient(
                Gradient(colors: [accentNebula.opacity(0.16), .clear]),
                center: CGPoint(x: hazeRect1.midX, y: hazeRect1.midY),
                startRadius: 0,
                endRadius: hazeRect1.width * 0.5
            )
            context.fill(Path(ellipseIn: hazeRect1), with: nebulaShader1)
            
            let hazeRect2 = CGRect(x: midX - 44, y: midY - 60 + drift * 0.6, width: 88, height: 120)
            let nebulaShader2 = GraphicsContext.Shading.radialGradient(
                Gradient(colors: [accentNebula.opacity(0.08), .clear]),
                center: CGPoint(x: hazeRect2.midX, y: hazeRect2.midY),
                startRadius: 0,
                endRadius: hazeRect2.height * 0.5
            )
            context.fill(Path(ellipseIn: hazeRect2), with: nebulaShader2)
            
            // 2. Pre-calculate Orbiting 3D Golden Spheres (no wire rings, distinct planes/tilt, core-facing lighting)
            let sphereCount = 4
            var backgroundSpheres: [(point: CGPoint, size: CGFloat, dx: CGFloat, dy: CGFloat)] = []
            var foregroundSpheres: [(point: CGPoint, size: CGFloat, dx: CGFloat, dy: CGFloat)] = []
            
            for i in 0..<sphereCount {
                let phase = Double(i) * (.pi * 0.5)
                let speed = 1.0 + Double(i) * 0.15
                let angle = time * speed + phase
                
                let orbitRadius: CGFloat = 36 + CGFloat(i) * 4
                let orbitTilt: Double = -0.4 + Double(i) * 0.3
                
                // Raw 3D coordinates on flat ellipse
                let x0 = CGFloat(cos(angle)) * orbitRadius
                let y0 = CGFloat(sin(angle)) * orbitRadius * 0.28
                
                // Rotate by orbit tilt
                let cosT = CGFloat(cos(orbitTilt))
                let sinT = CGFloat(sin(orbitTilt))
                let x = midX + x0 * cosT - y0 * sinT
                let y = midY - 3 + x0 * sinT + y0 * cosT
                
                let depth = CGFloat(sin(angle))
                let baseSize: CGFloat = 7.0
                let finalSize = baseSize * (1.0 + 0.28 * depth)
                
                let dx = midX - x
                let dy = midY - y
                
                let sphereData = (point: CGPoint(x: x, y: y), size: finalSize, dx: dx, dy: dy)
                
                if depth < 0 {
                    backgroundSpheres.append(sphereData)
                } else {
                    foregroundSpheres.append(sphereData)
                }
            }
            
            // 3. Draw background spheres (behind the core and accretion disk)
            for s in backgroundSpheres {
                let sRect = CGRect(x: s.point.x - s.size * 0.5, y: s.point.y - s.size * 0.5, width: s.size, height: s.size)
                let dist = sqrt(s.dx * s.dx + s.dy * s.dy)
                let offset = s.size * 0.18
                let hx = s.point.x + (dist > 0 ? (s.dx / dist) * offset : 0)
                let hy = s.point.y + (dist > 0 ? (s.dy / dist) * offset : 0)
                
                let sphereShader = GraphicsContext.Shading.radialGradient(
                    Gradient(colors: [goldHot.opacity(0.85), gold, goldEdge.opacity(0.8), Color.black.opacity(0.7)]),
                    center: CGPoint(x: hx, y: hy),
                    startRadius: 0,
                    endRadius: s.size * 0.55
                )
                context.fill(Path(ellipseIn: sRect), with: sphereShader)
            }
            
            // 4. Geometry and Mathematics for the 3D Flat Accretion Disk (Gas Ring)
            let gasRadius: CGFloat = 32
            let gasAspect: CGFloat = 0.28
            let gasTilt: Double = -0.16 // Beautiful, matching diagonal slant
            let cosGT = CGFloat(cos(gasTilt))
            let sinGT = CGFloat(sin(gasTilt))
            
            func pointOnDisk(angle: Double) -> CGPoint {
                let rx = CGFloat(cos(angle)) * gasRadius
                let ry = CGFloat(sin(angle)) * gasRadius * gasAspect
                let x = midX + rx * cosGT - ry * sinGT
                let y = midY - 3 + rx * sinGT + ry * cosGT
                return CGPoint(x: x, y: y)
            }
            
            let steps = 64
            
            // 5. Draw BACK HALF of the Accretion Disk (depth < 0, i.e., sin(angle) < 0)
            var backDiskPath = Path()
            var firstBack = true
            for s in 0...steps {
                let a = Double(s) * (2.0 * .pi) / Double(steps)
                if sin(a) < 0 {
                    let pt = pointOnDisk(angle: a)
                    if firstBack {
                        backDiskPath.move(to: pt)
                        firstBack = false
                    } else {
                        backDiskPath.addLine(to: pt)
                    }
                }
            }
            
            // Stroke Back Gas Ring in beautiful volumetric layers
            context.stroke(backDiskPath, with: .color(accentNebula.opacity(0.12)), lineWidth: 12)
            context.stroke(backDiskPath, with: .color(accentNebula.opacity(0.38)), lineWidth: 6)
            context.stroke(backDiskPath, with: .color(Color(hex: "#E5E0FF").opacity(0.85)), lineWidth: 2)
            
            // 6. Draw Obsidian Core Event Horizon (The absolute black sphere void)
            let coreRect = CGRect(x: midX - coreRadius, y: midY - coreRadius, width: coreRadius * 2, height: coreRadius * 2)
            context.fill(Path(ellipseIn: coreRect), with: .color(obsidian))
            context.stroke(Path(ellipseIn: coreRect), with: .color(accentNebula.opacity(0.35)), lineWidth: 0.8)
            
            // 7. Draw Glass Specular Highlight on Core (Gives it a high-gloss spherical look)
            let highlightRect = CGRect(x: midX - coreRadius * 0.85, y: midY - coreRadius * 1.05, width: coreRadius * 1.3, height: coreRadius * 1.0)
            let specularShader = GraphicsContext.Shading.radialGradient(
                Gradient(colors: [Color.white.opacity(0.14), .clear]),
                center: CGPoint(x: highlightRect.midX, y: highlightRect.midY),
                startRadius: 0,
                endRadius: highlightRect.width * 0.45
            )
            context.fill(Path(ellipseIn: highlightRect), with: specularShader)
            
            // 8. Draw FRONT HALF of the Accretion Disk (depth >= 0, i.e., sin(angle) >= 0)
            var frontDiskPath = Path()
            var firstFront = true
            for s in 0...steps {
                let a = Double(s) * (2.0 * .pi) / Double(steps)
                if sin(a) >= 0 {
                    let pt = pointOnDisk(angle: a)
                    if firstFront {
                        frontDiskPath.move(to: pt)
                        firstFront = false
                    } else {
                        frontDiskPath.addLine(to: pt)
                    }
                }
            }
            
            // Stroke Front Gas Ring in matching volumetric layers (seamlessly wrapping around the core!)
            context.stroke(frontDiskPath, with: .color(accentNebula.opacity(0.12)), lineWidth: 12)
            context.stroke(frontDiskPath, with: .color(accentNebula.opacity(0.38)), lineWidth: 6)
            context.stroke(frontDiskPath, with: .color(Color(hex: "#E5E0FF").opacity(0.85)), lineWidth: 2)
            
            // 9. Draw foreground spheres (orbiting in front of the core and disk)
            for s in foregroundSpheres {
                let sRect = CGRect(x: s.point.x - s.size * 0.5, y: s.point.y - s.size * 0.5, width: s.size, height: s.size)
                let dist = sqrt(s.dx * s.dx + s.dy * s.dy)
                let offset = s.size * 0.2
                let hx = s.point.x + (dist > 0 ? (s.dx / dist) * offset : 0)
                let hy = s.point.y + (dist > 0 ? (s.dy / dist) * offset : 0)
                
                let sphereShader = GraphicsContext.Shading.radialGradient(
                    Gradient(colors: [goldHot, gold, goldEdge.opacity(0.9), Color.black.opacity(0.85)]),
                    center: CGPoint(x: hx, y: hy),
                    startRadius: 0,
                    endRadius: s.size * 0.58
                )
                context.fill(Path(ellipseIn: sRect), with: sphereShader)
            }
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
