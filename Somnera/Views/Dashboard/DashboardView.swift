import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var showRecording = false
    @State private var showCreatorMessage = false
    @EnvironmentObject var appState: AppState
    @AppStorage("somnera_is_mecenas") private var isMecenas = false
    @AppStorage("somnera_equipped_totem") private var equippedTotem = "cuarzo"

    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Premium Mesh Background
                Color.somBackground.ignoresSafeArea()
                
                ZStack {
                    Circle()
                        .fill(Color.somMesh3.opacity(0.3))
                        .frame(width: 400, height: 400)
                        .blur(radius: 80)
                        .offset(x: -150, y: -200)
                    
                    Circle()
                        .fill(Color.somAccent.opacity(0.12))
                        .frame(width: 300, height: 300)
                        .blur(radius: 60)
                        .offset(x: 150, y: 100)
                }
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        headerSection
                        
                        startButton
                            .padding(.horizontal)
                        

                        if let session = viewModel.lastSession {
                            ScoreCardView(session: session)
                                .padding(.horizontal)
                            
                            NightHeatmapView(session: session)
                                .padding(.horizontal)
                            
                            AirwayDigitalTwinView(
                                nasalIntensity: session.nasalIntensity,
                                palatalIntensity: session.palatalIntensity,
                                lingualIntensity: session.lingualIntensity
                            )
                            .padding(.horizontal)
                            
                            HighlightsView(session: session) { session, event, feedback in
                                viewModel.updateFeedback(for: session, event: event, feedback: feedback)
                            }
                            .padding(.horizontal)
                        }

                        if !viewModel.weeklyChartData.isEmpty {
                            WeeklyChartView(
                                data: viewModel.weeklyChartData,
                                analysis: viewModel.weeklyAnatomicalAnalysis
                            )
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showRecording) {
                RecordingView(dashboardVM: viewModel)
                    .onDisappear { viewModel.load() }
            }
            .sheet(isPresented: $showCreatorMessage) {
                CreatorMessageView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .navigationDestination(item: $viewModel.sessionToNavigate) { session in
                SessionDetailView(session: session)
            }
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 10) {
                    Text("Somnera")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(LinearGradient(
                            colors: [.somAccent, Color(hex: "#4A90D9")],
                            startPoint: .leading, endPoint: .trailing
                        ))

                    if isMecenas {
                        TotemBadgeView(totemId: equippedTotem)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                Text(Date().formatted(.dateTime.weekday(.wide).day().month()))
                    .font(.subheadline)
                    .foregroundColor(.somTextSecondary)
            }
            Spacer()
            
            Button {
                showCreatorMessage = true
            } label: {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.somAccent.gradient)
                    .shadow(color: Color.somAccent.opacity(0.4), radius: 10)
            }
        }
        .padding(.horizontal)
        .padding(.top, 16)
    }

    private var emptyStateCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.somAccent.gradient)
            
            VStack(spacing: 4) {
                Text("Sin sesiones aún")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("Inicia tu primera sesión esta noche")
                    .font(.caption)
                    .foregroundColor(.somTextSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .somGlassStyle(cornerRadius: 24)
        .padding(.horizontal)
    }

    private var startButton: some View {
        Button {
            showRecording = true
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "record.circle.fill")
                    .font(.title2)
                Text("Iniciar Sesión Nocturna")
                    .font(.system(.title3, design: .rounded, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .background(Color.somGradient)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .shadow(color: Color.somAccent.opacity(0.5), radius: 20, y: 10)
        }
        .scaleEffect(appState.isRecording ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: appState.isRecording)
    }

}

// MARK: - Score Card

struct ScoreCardView: View {
    let session: SleepSession
    @State private var showExplanation = false

    var scoreColor: Color {
        switch session.snoreScore {
        case 70...100: return .somSafe
        case 40..<70:  return .somWarning
        default:       return .somApnea
        }
    }

    var body: some View {
        HStack(spacing: 24) {
            // Score circle with glow
            Button {
                showExplanation = true
            } label: {
                ZStack {
                    Circle()
                        .stroke(scoreColor.opacity(0.3), lineWidth: 8)
                        .blur(radius: 8)
                    
                    Circle()
                        .stroke(Color.somSurfaceHigh.opacity(0.5), lineWidth: 6)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(session.snoreScore) / 100)
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 0) {
                        Text("\(session.snoreScore)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Puntos")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.somTextSecondary)
                    }
                }
            }
            .frame(width: 100, height: 100)
            .sheet(isPresented: $showExplanation) {
                ScoreExplanationView()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }

            // Stats
            VStack(alignment: .leading, spacing: 10) {
                statRow(icon: "timer", label: "Duración", value: session.formattedDuration)
                statRow(icon: "waveform", label: "Roncando", value: String(format: "%.1f%%", session.snorePercentage))
                statRow(icon: "number", label: "Eventos", value: "\(session.snoreEvents.count)")
                statRow(icon: "lungs.fill", label: "Apneas", value: "\(session.apneaEventCount)",
                        color: session.apneaEventCount > 0 ? .somApnea : .somSafe)
            }

            Spacer()
        }
        .padding(20)
        .somGlassStyle(cornerRadius: 24)
        .frame(height: 160)
    }

    private func statRow(icon: String, label: String, value: String, color: Color = .somTextPrimary) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.somAccent)
                .frame(width: 16)
            Text(label)
                .font(.caption)
                .foregroundColor(.somTextSecondary)
            Spacer()
            Text(value)
                .font(.caption.bold())
                .foregroundColor(color)
        }
    }
}

private struct TotemBadgeView: View {
    let totemId: String

    private var color: Color {
        switch totemId {
        case "cuarzo": return .somSafe
        case "piramide": return .somAccent
        case "giroscopio": return .somWarning
        case "tesseracto": return .somApnea
        case "helice": return .somSafe
        case "astrolabio": return .somWarning
        case "singularidad": return .somWarning
        default: return .somAccent
        }
    }

    private var mathType: TotemMathType {
        switch totemId {
        case "cuarzo": return .crystal
        case "piramide": return .pyramid
        case "giroscopio": return .gyro
        case "tesseracto": return .tesseract
        case "helice": return .helix
        case "astrolabio": return .astrolabe
        case "singularidad": return .singularity
        default: return .crystal
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.12))
            Circle()
                .stroke(color.opacity(0.45), lineWidth: 1)

            Totem3DView(mathType: mathType, color: color, isUnlocked: true)
                // Keep the exact same animation as the equipped totem renderer; only scale it down.
                .frame(width: 34, height: 34)
                .scaleEffect(0.86)
        }
        .frame(width: 44, height: 44)
        .accessibilityLabel("Insignia de mecenas")
    }
}

// MARK: - Score Explanation View

struct ScoreExplanationView: View {
    var body: some View {
        ZStack {
            Color.somBackground.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 30) {
                    VStack(spacing: 12) {
                        Text("Puntuación de Ronquido")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("¿Cómo calculamos tu noche?")
                            .font(.subheadline)
                            .foregroundColor(.somTextSecondary)
                    }
                    
                    VStack(spacing: 20) {
                        explanationRow(
                            icon: "clock.fill",
                            title: "Persistencia (50%)",
                            description: "Porcentaje de tiempo que estuviste roncando respecto al total de la noche."
                        )
                        
                        explanationRow(
                            icon: "speaker.wave.3.fill",
                            title: "Intensidad (20%)",
                            description: "Nivel de volumen máximo alcanzado. Ronquidos más fuertes indican más esfuerzo respiratorio."
                        )
                        
                        explanationRow(
                            icon: "lungs.fill",
                            title: "Eventos Respiratorios",
                            description: "Analizamos la duración de cada pausa. Las apneas de más de 30 segundos tienen una penalización mayor por su riesgo cardiaco."
                        )
                        
                        explanationRow(
                            icon: "brain.head.profile",
                            title: "Validación por IA",
                            description: "La red neuronal filtra ruidos externos para asegurar que solo los ronquidos reales cuenten."
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    Text("Una puntuación alta indica una respiración eficiente y silenciosa, mientras que una baja sugiere ronquidos persistentes o interrupciones respiratorias.")
                        .font(.system(size: 13))
                        .foregroundColor(.somTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 30)
                }
                .padding(.top, 40)
            }
        }
    }
    
    private func explanationRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.somAccent)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.somTextSecondary)
                    .lineSpacing(4)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

// MARK: - Weekly Chart

struct WeeklyChartView: View {
    let data: [DashboardViewModel.ChartData]
    let analysis: (type: String, description: String, icon: String)
    @State private var appear = false

    private let chartHeight: CGFloat = 100
    private let safeThreshold: Int = 70

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tendencia Semanal")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.white)
                    Text("Puntos de Salud Respiratoria")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.somTextSecondary)
                        .tracking(1)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    legend(label: "Sinergia", color: .somSafe)
                    legend(label: "Apnea", color: .somApnea)
                }
            }

            ZStack(alignment: .bottom) {
                // 1. Background Zones
                GeometryReader { geo in
                    VStack(spacing: 0) {
                        Color.somSafe.opacity(0.05).frame(height: geo.size.height * 0.3)
                        Color.somWarning.opacity(0.05).frame(height: geo.size.height * 0.3)
                        Color.somApnea.opacity(0.05).frame(height: geo.size.height * 0.4)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // 2. Apnea Spikes (Background)
                GeometryReader { geo in
                    let stepX = geo.size.width / CGFloat(max(1, data.count - 1))
                    Path { path in
                        for i in 0..<data.count {
                            let count = data[i].apneaCount
                            if count > 0 {
                                let x = CGFloat(i) * stepX
                                let h = min(CGFloat(count) * 15, chartHeight)
                                path.move(to: CGPoint(x: x, y: chartHeight))
                                path.addLine(to: CGPoint(x: x, y: chartHeight - h))
                            }
                        }
                    }
                    .stroke(Color.somApnea.opacity(0.4), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                }
                
                // 3. The Trend Line (Smoothed)
                GeometryReader { geo in
                    let width = geo.size.width
                    let stepX = width / CGFloat(max(1, data.count - 1))
                    let validPoints = data.enumerated().compactMap { i, point -> (CGPoint, Int)? in
                        guard let score = point.score else { return nil }
                        return (CGPoint(x: CGFloat(i) * stepX, y: yPosition(for: score)), i)
                    }
                    
                    if !validPoints.isEmpty {
                        // Area Fill
                        Path { path in
                            if let first = validPoints.first {
                                path.move(to: CGPoint(x: first.0.x, y: chartHeight))
                                path.addLine(to: first.0)
                                
                                for j in 1..<validPoints.count {
                                    let current = validPoints[j].0
                                    let previous = validPoints[j-1].0
                                    let midX = (previous.x + current.x) / 2
                                    path.addCurve(to: current, control1: CGPoint(x: midX, y: previous.y), control2: CGPoint(x: midX, y: current.y))
                                }
                                
                                if let last = validPoints.last {
                                    path.addLine(to: CGPoint(x: last.0.x, y: chartHeight))
                                }
                                path.closeSubpath()
                            }
                        }
                        .fill(
                            LinearGradient(
                                colors: [Color.somSafe.opacity(0.15), .clear],
                                startPoint: .top, endPoint: .bottom
                            )
                        )

                        // Main Glow Line
                        Path { path in
                            if let first = validPoints.first {
                                path.move(to: first.0)
                                for j in 1..<validPoints.count {
                                    let current = validPoints[j].0
                                    let previous = validPoints[j-1].0
                                    let midX = (previous.x + current.x) / 2
                                    path.addCurve(to: current, control1: CGPoint(x: midX, y: previous.y), control2: CGPoint(x: midX, y: current.y))
                                }
                            }
                        }
                        .trim(from: 0, to: appear ? 1 : 0)
                        .stroke(
                            LinearGradient(colors: [.somApnea, .somWarning, .somSafe], startPoint: .bottom, endPoint: .top),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                        )
                        .shadow(color: .somSafe.opacity(0.4), radius: 6)

                        // Data Points
                        ForEach(validPoints, id: \.1) { point, _ in
                            Circle()
                                .fill(Color.white)
                                .frame(width: 4, height: 4)
                                .position(point)
                                .opacity(appear ? 1 : 0)
                        }
                    }
                }
                .frame(height: chartHeight)
            }
            .padding(.top, 10)

            HStack(spacing: 0) {
                ForEach(data) { point in
                    Text(point.label)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(point.score != nil ? .white : .somTextSecondary.opacity(0.5))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 8)
            
            anatomicalInsight(analysis: analysis)
        }
        .padding(24)
        .somGlassStyle(cornerRadius: 24)
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) { appear = true }
        }
    }

    private func anatomicalInsight(analysis: (type: String, description: String, icon: String)) -> some View {
        HStack(spacing: 12) {
            Image(systemName: analysis.icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.somAccent)
                .padding(8)
                .background(Color.somAccent.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text("PATRÓN PREDOMINANTE: \(analysis.type.uppercased())")
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(.somAccent)
                
                Text(analysis.description)
                    .font(.system(size: 10))
                    .foregroundColor(.somTextSecondary)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .cornerRadius(16)
    }

    private func legend(label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label).font(.system(size: 9, weight: .bold)).foregroundColor(.somTextSecondary)
        }
    }

    private func yPosition(for score: Int) -> CGFloat {
        let normalizedScore = CGFloat(min(100, max(0, score)))
        return chartHeight - (normalizedScore / 100 * chartHeight)
    }
}



#Preview {
    DashboardView(viewModel: {
        let vm = DashboardViewModel()
        vm.sessions = [.mock]
        return vm
    }())
    .environmentObject(AppState())
}
