import SwiftUI

struct SessionListView: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color.somBackground.ignoresSafeArea()

                if viewModel.sessions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "moon.zzz")
                            .font(.system(size: 56))
                            .foregroundColor(.somAccent.opacity(0.4))
                        Text("Sin sesiones guardadas")
                            .font(.headline)
                            .foregroundColor(.somTextSecondary)
                        Text("Hasta 7 sesiones se guardan automáticamente")
                            .font(.caption)
                            .foregroundColor(.somTextSecondary.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.sessions) { session in
                                NavigationLink(destination: SessionDetailView(session: session)) {
                                    SessionRowView(session: session)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Mis Sesiones")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.somBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

// MARK: - Session Row

struct SessionRowView: View {
    let session: SleepSession

    var scoreColor: Color {
        switch session.snoreScore {
        case 0..<30:  return .somSafe
        case 30..<60: return .somWarning
        default:      return .somApnea
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            // Score indicator
            ZStack {
                Circle()
                    .fill(scoreColor.opacity(0.15))
                    .frame(width: 52, height: 52)
                Text("\(session.snoreScore)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(scoreColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(session.startDate, format: .dateTime.weekday(.wide).day().month())
                    .font(.subheadline.bold())
                    .foregroundColor(.somTextPrimary)
                HStack(spacing: 12) {
                    Label(session.formattedDuration, systemImage: "clock")
                    Label(String(format: "%.0f%%", session.snorePercentage), systemImage: "waveform")
                    if session.apneaEventCount > 0 {
                        Label("\(session.apneaEventCount)", systemImage: "lungs.fill")
                            .foregroundColor(.somApnea)
                    }
                }
                .font(.caption)
                .foregroundColor(.somTextSecondary)
                .labelStyle(.titleAndIcon)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.somTextSecondary)
        }
        .padding(SomneraConstants.Design.cardPadding)
        .background(Color.somSurface)
        .clipShape(RoundedRectangle(cornerRadius: SomneraConstants.Design.cornerRadius))
    }
}
