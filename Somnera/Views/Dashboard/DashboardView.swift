import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var showRecording = false
    @State private var showCreatorMessage = false
    @EnvironmentObject var appState: AppState

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
                Text("Somnera")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(LinearGradient(
                        colors: [.somAccent, Color(hex: "#4A90D9")],
                        startPoint: .leading, endPoint: .trailing
                    ))
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

// MARK: - Creator Message (Easter Egg)

struct CreatorMessageView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.somBackground.ignoresSafeArea()
            
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
                        
                        messageParagraph("Si gustas contribuir donando, me ayudarías a seguir dándole soporte y poder pagar la licencia anual de Apple que no es nada barata.")
                    }
                    .padding(.horizontal, 24)
                    
                    // Botón de Donación (Placeholder)
                    Button {
                        // Acción de donación futura
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

// MARK: - Score Card

struct ScoreCardView: View {
    let session: SleepSession
    @State private var showExplanation = false

    var scoreColor: Color {
        switch session.snoreScore {
        case 0..<30:  return .somSafe
        case 30..<60: return .somWarning
        default:      return .somApnea
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
                statRow(icon: "waveform", label: "Roncando", value: String(format: "%.0f%%", session.snorePercentage))
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
                    
                    Text("Una puntuación baja indica una noche tranquila, mientras que una alta sugiere ronquidos persistentes o muy ruidosos.")
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
    private let safeThreshold: Int = 30
    private let warningThreshold: Int = 60

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tendencia Semanal")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.white)
                    Text("Ronquido vs Apneas")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.somTextSecondary)
                        .tracking(1)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    legend(label: "Ronquido", color: .somAccent)
                    legend(label: "Apnea", color: .somApnea)
                }
            }

            ZStack(alignment: .bottom) {
                // 1. Background Zones
                GeometryReader { geo in
                    VStack(spacing: 0) {
                        Color.somApnea.opacity(0.03).frame(height: geo.size.height * 0.4) // 60-100
                        Color.somWarning.opacity(0.03).frame(height: geo.size.height * 0.3) // 30-60
                        Color.somSafe.opacity(0.03).frame(height: geo.size.height * 0.3) // 0-30
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                
                // 2. Apnea Spikes (Background)
                GeometryReader { geo in
                    let width = geo.size.width
                    let stepX = width / CGFloat(max(1, data.count - 1))
                    
                    Path { path in
                        for i in 0..<data.count {
                            let x = CGFloat(i) * stepX
                            let count = data[i].apneaCount
                            if count > 0 {
                                // Spike height based on apnea count
                                let h = min(CGFloat(count) * 10, chartHeight)
                                path.move(to: CGPoint(x: x, y: chartHeight))
                                path.addLine(to: CGPoint(x: x, y: chartHeight - h))
                            }
                        }
                    }
                    .stroke(Color.somApnea.opacity(0.4), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                }
                
                // 3. Reference Line
                Path { path in
                    let y = yPosition(for: safeThreshold)
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: 350, y: y))
                }
                .stroke(Color.somSafe.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                
                GeometryReader { geo in
                    let width = geo.size.width
                    let stepX = width / CGFloat(max(1, data.count - 1))
                    
                    // 4. Area under the curve
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: chartHeight))
                        for i in 0..<data.count {
                            let x = CGFloat(i) * stepX
                            let y = yPosition(for: data[i].score)
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                        path.addLine(to: CGPoint(x: width, y: chartHeight))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [Color.somAccent.opacity(0.15), .clear],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    
                    // 5. The Glow Line
                    Path { path in
                        for i in 0..<data.count {
                            let x = CGFloat(i) * stepX
                            let y = yPosition(for: data[i].score)
                            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                            else { path.addLine(to: CGPoint(x: x, y: y)) }
                        }
                    }
                    .trim(from: 0, to: appear ? 1 : 0)
                    .stroke(
                        LinearGradient(colors: [.somSafe, .somWarning, .somApnea], startPoint: .bottom, endPoint: .top),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                    )
                    .shadow(color: .somAccent.opacity(0.4), radius: 6)
                }
                .frame(height: chartHeight)
            }
            .padding(.top, 10)

            HStack(spacing: 0) {
                ForEach(data) { point in
                    Text(point.label)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.somTextSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 8)
            
            // 6. Anatomical Insight Card
            anatomicalInsight(analysis: analysis)
        }
        .padding(24)
        .somGlassStyle(cornerRadius: 24)
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) { appear = true }
        }
    }

    // Removed the simulated private property

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
