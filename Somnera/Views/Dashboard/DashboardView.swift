import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var showRecording = false
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            ZStack {
                Color.somBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection

                        // Last night score
                        if let session = viewModel.lastSession {
                            ScoreCardView(session: session)
                                .padding(.horizontal)
                        } else {
                            emptyStateCard
                        }

                        // Weekly chart
                        if viewModel.sessions.count > 1 {
                            WeeklyChartView(scores: viewModel.weeklyScores)
                                .padding(.horizontal)
                        }

                        // Start button
                        startButton
                            .padding(.horizontal)
                            .padding(.bottom, 32)
                    }
                    .padding(.top, 8)
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
        RoundedRectangle(cornerRadius: SomneraConstants.Design.cornerRadius)
            .fill(Color.somSurface)
            .frame(height: 180)
            .overlay(
                VStack(spacing: 12) {
                    Image(systemName: "moon.stars")
                        .font(.system(size: 40))
                        .foregroundColor(.somAccent.opacity(0.6))
                    Text("Sin sesiones aún")
                        .font(.headline)
                        .foregroundColor(.somTextSecondary)
                    Text("Inicia tu primera sesión esta noche")
                        .font(.caption)
                        .foregroundColor(.somTextSecondary.opacity(0.7))
                }
            )
            .padding(.horizontal)
    }

    private var startButton: some View {
        Button {
            showRecording = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "record.circle.fill")
                    .font(.title2)
                Text("Iniciar Sesión Nocturna")
                    .font(.system(.title3, design: .rounded, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color.somGradient)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: SomneraConstants.Design.cornerRadius))
            .shadow(color: Color.somAccent.opacity(0.4), radius: 16, y: 6)
        }
        .scaleEffect(appState.isRecording ? 0.97 : 1.0)
        .animation(.spring(response: 0.3), value: appState.isRecording)
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
        RoundedRectangle(cornerRadius: SomneraConstants.Design.cornerRadius)
            .fill(Color.somSurface)
            .overlay(
                HStack(spacing: 24) {
                    // Score circle
                    ZStack {
                        Circle()
                            .stroke(scoreColor.opacity(0.2), lineWidth: 8)
                        Circle()
                            .trim(from: 0, to: CGFloat(session.snoreScore) / 100)
                            .stroke(scoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        VStack(spacing: 2) {
                            Text("\(session.snoreScore)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.somTextPrimary)
                            Text("Score")
                                .font(.caption2)
                                .foregroundColor(.somTextSecondary)
                        }
                    }
                    .frame(width: 110, height: 110)

                    // Stats
                    VStack(alignment: .leading, spacing: 10) {
                        statRow(icon: "timer", label: "Duración", value: session.formattedDuration)
                        statRow(icon: "waveform", label: "Roncando", value: String(format: "%.0f%%", session.snorePercentage))
                        statRow(icon: "lungs.fill", label: "Apneas", value: "\(session.apneaEventCount)",
                                color: session.apneaEventCount > 0 ? .somApnea : .somSafe)
                        statRow(icon: "speaker.wave.3.fill", label: "Pico dB", value: String(format: "%.0f dB", session.peakDecibels))
                    }

                    Spacer()
                }
                .padding(SomneraConstants.Design.cardPadding)
            )
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
    let scores: [Int]

    private let dayLabels = ["L", "M", "X", "J", "V", "S", "D"]

    var body: some View {
        RoundedRectangle(cornerRadius: SomneraConstants.Design.cornerRadius)
            .fill(Color.somSurface)
            .overlay(
                VStack(alignment: .leading, spacing: 16) {
                    Text("Últimas \(scores.count) noches")
                        .font(.subheadline.bold())
                        .foregroundColor(.somTextPrimary)

                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(Array(scores.enumerated()), id: \.offset) { i, score in
                            VStack(spacing: 6) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(barColor(score: score))
                                    .frame(width: 28, height: max(8, CGFloat(score) * 1.2))
                                Text(dayLabels[i % 7])
                                    .font(.system(size: 10))
                                    .foregroundColor(.somTextSecondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(SomneraConstants.Design.cardPadding)
            )
            .frame(height: 160)
    }

    private func barColor(score: Int) -> Color {
        switch score {
        case 0..<30:  return .somSafe
        case 30..<60: return .somWarning
        default:      return .somApnea
        }
    }
}
