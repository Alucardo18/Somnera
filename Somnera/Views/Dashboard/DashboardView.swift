import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var showRecording = false
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
                            
                            HighlightsView(session: session)
                                .padding(.horizontal)
                        } else {
                            emptyStateCard
                        }

                        if !viewModel.weeklyChartData.isEmpty {
                            WeeklyChartView(data: viewModel.weeklyChartData)
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
                RecordingView()
                    .onDisappear { viewModel.load() }
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
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 28))
                .foregroundStyle(Color.somAccent.gradient)
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
            .frame(width: 100, height: 100)

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

// MARK: - Weekly Chart

struct WeeklyChartView: View {
    let data: [DashboardViewModel.ChartData]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Tendencia Semanal")
                .font(.system(size: 14, weight: .black))
                .foregroundColor(.white)
                .tracking(1)

            HStack(alignment: .bottom, spacing: 10) {
                ForEach(data) { point in
                    VStack(spacing: 8) {
                        ZStack(alignment: .bottom) {
                            Capsule()
                                .fill(Color.somSurfaceHigh.opacity(0.3))
                                .frame(width: 24, height: 80)
                            
                            Capsule()
                                .fill(barColor(score: point.score).gradient)
                                .frame(width: 24, height: max(10, CGFloat(point.score) * 0.8))
                        }
                        
                        Text(point.label)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.somTextSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .somGlassStyle(cornerRadius: 24)
        .frame(height: 180)
    }

    private func barColor(score: Int) -> Color {
        switch score {
        case 0..<30:  return .somSafe
        case 30..<60: return .somWarning
        default:      return .somApnea
        }
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
