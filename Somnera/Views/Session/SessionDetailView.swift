import SwiftUI
import AVFoundation

struct SessionDetailView: View {
    let session: SleepSession
    @State private var player: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var playbackProgress: Double = 0
    @State private var playbackTime: Double = 0
    @State private var playbackTimer: Timer?
    
    // AI Report Generation
    private var aiReport: SessionAnalyticsService.DiagnosticReport {
        SessionAnalyticsService.shared.generateReport(for: session)
    }

    var body: some View {
        ZStack {
            Color.somBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Header stats
                    headerStats

                    // Snore events summary
                    if !session.snoreEvents.isEmpty {
                        eventsSection(
                            title: "Mapa de Ronquidos",
                            icon: "waveform",
                            color: .somAccent
                        ) {
                            VStack(spacing: 16) {
                                // AI Insight for Snores
                                aiInsightBox(text: aiReport.snoreInsight, color: .somAccent)
                                
                                integratedSnoreLegend
                                    .padding(.bottom, 8)
                                
                                let grouped = groupSnoreEventsByHour(session.snoreEvents)
                                ForEach(grouped.keys.sorted(), id: \.self) { hourKey in
                                    let events = grouped[hourKey] ?? []
                                    snoreHourRow(hourKey: hourKey, events: events)
                                }
                            }
                        }
                    }

                    // Apnea events summary
                    if !session.apneaEvents.isEmpty {
                        eventsSection(
                            title: "Análisis de Apneas",
                            icon: "lungs.fill",
                            color: worstApneaColor
                        ) {
                            VStack(spacing: 16) {
                                // AI Insight for Apneas
                                aiInsightBox(text: aiReport.apneaInsight, color: worstApneaColor)
                                
                                integratedApneaLegend
                                    .padding(.bottom, 8)
                                
                                let grouped = groupApneaEventsByHour(session.apneaEvents)
                                ForEach(grouped.keys.sorted(), id: \.self) { hourKey in
                                    let events = grouped[hourKey] ?? []
                                    apneaHourRow(hourKey: hourKey, events: events)
                                }
                            }
                        }
                    }

                    // Audio player
                    if session.audioFilePath != nil {
                        audioPlayerSection
                    }

                    // Medical disclaimer
                    disclaimerView
                        .padding(.bottom, 32)
                }
                .padding()
            }
        }
        .navigationTitle(session.startDate.formatted(.dateTime.weekday(.abbreviated).day().month()))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.somBackground, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onDisappear { stopPlayback() }
    }

    // MARK: - AI Components

    private func aiInsightBox(text: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
                .padding(8)
                .background(color.opacity(0.15))
                .clipShape(Circle())
                .shadow(color: color.opacity(0.3), radius: 5)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("ANÁLISIS IA")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(color)
                    .tracking(1)
                
                Text(text)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.somTextPrimary)
                    .lineSpacing(2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                Color.somSurfaceHigh.opacity(0.3)
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        LinearGradient(colors: [color.opacity(0.5), color.opacity(0.1)], 
                                       startPoint: .topLeading, 
                                       endPoint: .bottomTrailing), 
                        lineWidth: 1
                    )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Computed Colors

    private var worstApneaColor: Color {
        if session.apneaEvents.contains(where: { $0.severity == .severe }) {
            return .somApnea
        } else if session.apneaEvents.contains(where: { $0.severity == .moderate }) {
            return .somWarning
        } else {
            return .somSafe
        }
    }

    private var scoreColor: Color {
        switch session.snoreScore {
        case 0..<30:  return .somSafe
        case 30..<60: return .somWarning
        default:      return .somApnea
        }
    }

    // MARK: - Header Stats

    private var headerStats: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statTile(label: "Score", value: "\(session.snoreScore)", unit: "/100", color: scoreColor)
            statTile(label: "Duración", value: session.formattedDuration, unit: "", color: .somTextPrimary)
            statTile(label: "Roncando", value: String(format: "%.0f", session.snorePercentage), unit: "%", color: .somAccent)
            statTile(label: "Pico", value: String(format: "%.0f", session.peakDecibels), unit: "dB", color: .somWarning)
        }
    }

    private func statTile(label: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.somTextSecondary)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                if !unit.isEmpty {
                    Text(unit).font(.caption).foregroundColor(.somTextSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.somSurface)
        .clipShape(RoundedRectangle(cornerRadius: SomneraConstants.Design.cornerRadius))
    }

    // MARK: - Events Section

    @ViewBuilder
    private func eventsSection<Content: View>(
        title: String, icon: String, color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.subheadline.bold())
                .foregroundColor(color)

            VStack(spacing: 8) {
                content()
            }
        }
        .padding(SomneraConstants.Design.cardPadding)
        .background(Color.somSurface)
        .clipShape(RoundedRectangle(cornerRadius: SomneraConstants.Design.cornerRadius))
    }

    // MARK: - Snore Rows

    private func snoreHourRow(hourKey: Int, events: [SnoreEvent]) -> some View {
        DisclosureGroup {
            VStack(spacing: 12) {
                let subGroups = groupSnoreEventsByInterval(events, minutes: 10)
                ForEach(subGroups.keys.sorted(), id: \.self) { intervalKey in
                    let subEvents = subGroups[intervalKey] ?? []
                    let avgML = subEvents.map { Double($0.peakDecibels) }.reduce(0, +) / Double(max(1, subEvents.count))
                    let avgConf = subEvents.map { $0.confidence }.reduce(0, +) / Double(max(1, subEvents.count))
                    let timeRange = formatIntervalRange(hourKey: hourKey, intervalKey: intervalKey)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(timeRange)
                                .font(.system(.caption, design: .monospaced, weight: .bold))
                                .foregroundColor(.somAccent)
                            Text("\(subEvents.count) ronc.")
                                .font(.caption2)
                                .foregroundColor(.somTextSecondary)
                        }
                        HStack(spacing: 12) {
                            metricSmall(label: "Sonido (Machine Learning)", value: Int(avgML), icon: "waveform")
                            metricSmall(label: "Confirmación", value: Int(avgConf * 100), icon: "checkmark.shield.fill")
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        } label: {
            hourHeader(hourKey: hourKey, count: events.count, color: .somAccent)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Apnea Rows

    private func apneaHourRow(hourKey: Int, events: [ApneaEvent]) -> some View {
        DisclosureGroup {
            VStack(spacing: 12) {
                ForEach(events) { event in
                    apneaRow(event: event)
                }
            }
            .padding(.vertical, 12)
        } label: {
            hourHeader(hourKey: hourKey, count: events.count, color: worstApneaColor)
        }
        .padding(.vertical, 4)
    }

    private func apneaRow(event: ApneaEvent) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(formatAbsoluteTime(event.offsetSeconds))
                    .font(.system(.caption, design: .monospaced, weight: .bold))
                    .foregroundColor(event.severity.color)
                Text(event.severity.label)
                    .font(.system(size: 9))
                    .foregroundColor(.somTextSecondary)
                    .textCase(.uppercase)
            }
            .frame(width: 80, alignment: .leading)
            
            Spacer()
            
            Text(event.formattedDuration)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundColor(.somTextPrimary)
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 10))
                Text("\(Int(event.confidence * 100))%")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
            }
            .foregroundColor(event.severity.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(event.severity.color.opacity(0.12))
            .clipShape(Capsule())
        }
    }

    private func hourHeader(hourKey: Int, count: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(formatAbsoluteHour(hourKey))
                    .font(.subheadline.bold())
                    .foregroundColor(.somTextPrimary)
                Spacer()
                Text("\(count) eventos")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.15))
                    .foregroundColor(color)
                    .clipShape(Capsule())
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.somTextSecondary.opacity(0.05))
                    RoundedRectangle(cornerRadius: 3).fill(color).frame(width: geo.size.width * min(1.0, Double(count) / 40.0))
                }
            }
            .frame(height: 6)
        }
    }

    private func metricSmall(label: String, value: Int, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 8)).foregroundColor(.somTextSecondary)
            Text("\(label):").font(.system(size: 10)).foregroundColor(.somTextSecondary)
            Text("\(value)%").font(.system(size: 10, weight: .bold)).foregroundColor(.somTextPrimary)
        }
    }

    // MARK: - Legends

    private var integratedSnoreLegend: some View {
        HStack(spacing: 12) {
            legendItem(label: "Sonido (ML)", desc: "Claridad", icon: "waveform", customColor: .somAccent)
            legendItem(label: "Confirmación", desc: "Movimiento", icon: "checkmark.shield.fill", customColor: .somAccent)
        }
        .padding(10).background(Color.somBackground.opacity(0.5)).clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var integratedApneaLegend: some View {
        HStack(spacing: 15) {
            legendItem(label: "Leve", desc: "<15s", icon: "circle.fill", customColor: .somSafe)
            legendItem(label: "Mod.", desc: "15-30s", icon: "circle.fill", customColor: .somWarning)
            legendItem(label: "Crit.", desc: ">30s", icon: "circle.fill", customColor: .somApnea)
        }
        .padding(10).background(Color.somBackground.opacity(0.5)).clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func legendItem(label: String, desc: String, icon: String, customColor: Color? = nil) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 10)).foregroundColor(customColor ?? .somAccent)
            VStack(alignment: .leading, spacing: 0) {
                Text(label).font(.system(size: 10, weight: .bold)).foregroundColor(.somTextPrimary)
                Text(desc).font(.system(size: 8)).foregroundColor(.somTextSecondary)
            }
        }
    }

    // MARK: - Helpers

    private func formatAbsoluteHour(_ hourKey: Int) -> String {
        let calendar = Calendar.current
        if let hourDate = calendar.date(byAdding: .hour, value: hourKey, to: session.startDate) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:00 a"
            return formatter.string(from: hourDate)
        }
        return "\(hourKey):00"
    }

    private func formatAbsoluteTime(_ offset: Double) -> String {
        let date = session.startDate.addingTimeInterval(offset)
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm:ss a"
        return formatter.string(from: date)
    }
    
    private func formatIntervalRange(hourKey: Int, intervalKey: Int) -> String {
        let calendar = Calendar.current
        let startMinutes = intervalKey * 10
        if let baseDate = calendar.date(byAdding: .hour, value: hourKey, to: session.startDate),
           let intervalDate = calendar.date(byAdding: .minute, value: startMinutes, to: baseDate) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: intervalDate)
        }
        return ":\(startMinutes)"
    }

    private func groupSnoreEventsByHour(_ events: [SnoreEvent]) -> [Int: [SnoreEvent]] {
        Dictionary(grouping: events) { event in
            Calendar.current.dateComponents([.hour], from: session.startDate, to: session.startDate.addingTimeInterval(event.offsetSeconds)).hour ?? 0
        }
    }

    private func groupApneaEventsByHour(_ events: [ApneaEvent]) -> [Int: [ApneaEvent]] {
        Dictionary(grouping: events) { event in
            Calendar.current.dateComponents([.hour], from: session.startDate, to: session.startDate.addingTimeInterval(event.offsetSeconds)).hour ?? 0
        }
    }
    
    private func groupSnoreEventsByInterval(_ events: [SnoreEvent], minutes: Int) -> [Int: [SnoreEvent]] {
        Dictionary(grouping: events) { event in
            Calendar.current.component(.minute, from: session.startDate.addingTimeInterval(event.offsetSeconds)) / minutes
        }
    }

    // MARK: - Audio Player Component

    private var audioPlayerSection: some View {
        VStack(spacing: 16) {
            Label("Grabación de Audio", systemImage: "headphones")
                .font(.subheadline.bold())
                .foregroundColor(scoreColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            SleepTimelineView(
                session: session,
                currentTime: $playbackTime,
                onSeek: { time in
                    player?.currentTime = time
                    playbackTime = time
                    updateProgress()
                }
            )
            .padding(.bottom, 8)

            HStack {
                Text(formatTime(player?.currentTime ?? 0)).font(.system(.caption, design: .monospaced)).foregroundColor(.somTextSecondary)
                Spacer()
                Button { togglePlayback() } label: { Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill").font(.system(size: 44)).foregroundStyle(Color.somGradient) }
                Spacer()
                Text(formatTime(player?.duration ?? 0)).font(.system(.caption, design: .monospaced)).foregroundColor(.somTextSecondary)
            }
        }
        .padding(SomneraConstants.Design.cardPadding)
        .background(Color.somSurface)
        .clipShape(RoundedRectangle(cornerRadius: SomneraConstants.Design.cornerRadius))
        .onAppear { setupPlayer() }
    }

    private var disclaimerView: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill").foregroundColor(.somTextSecondary).font(.caption).padding(.top, 1)
            Text("Somnera es una herramienta de monitorización personal. No es un dispositivo médico certificado. Si sospechas que tienes apnea del sueño, consulta a un especialista.").font(.caption2).foregroundColor(.somTextSecondary).multilineTextAlignment(.leading)
        }.padding(12).background(Color.somSurface.opacity(0.5)).clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func setupPlayer() { guard let path = session.audioFilePath else { return }; let url = URL(fileURLWithPath: path); try? AudioSessionManager.shared.switchToPlayback(); player = try? AVAudioPlayer(contentsOf: url); player?.prepareToPlay() }
    private func togglePlayback() { guard let player else { return }; if isPlaying { player.pause(); playbackTimer?.invalidate() } else { player.play(); playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in self.updateProgress() } }; isPlaying.toggle() }
    private func updateProgress() { guard let p = player else { return }; self.playbackTime = p.currentTime; self.playbackProgress = p.currentTime / max(1, p.duration); if !p.isPlaying && isPlaying { self.isPlaying = false; self.playbackTimer?.invalidate() } }
    private func stopPlayback() { player?.stop(); playbackTimer?.invalidate() }
    private func formatTime(_ t: TimeInterval) -> String { let m = Int(t) / 60; let s = Int(t) % 60; return String(format: "%d:%02d", m, s) }
}
