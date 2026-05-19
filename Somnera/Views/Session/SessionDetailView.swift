import SwiftUI
import AVFoundation

struct SessionDetailView: View {
    let session: SleepSession
    @State private var player: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var playbackProgress: Double = 0
    @State private var playbackTime: Double = 0
    @State private var playbackTimer: Timer?
    @State private var showScoreInfo = false
    
    // AI Report Generation
    private var aiReport: SessionAnalyticsService.DiagnosticReport {
        SessionAnalyticsService.shared.generateReport(for: session)
    }

    var body: some View {
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
                VStack(spacing: 28) {
                    // Smart Summary
                    InsightCardView(session: session)
                    
                    // Main Score & Quick Stats
                    headerStats
                    
                    // PSG Medical Hypnogram
                    PSGTimelineView(
                        session: session,
                        currentTime: $playbackTime,
                        onSeek: { time in
                            player?.currentTime = time
                            playbackTime = time
                            updateProgress()
                        }
                    )
                    
                    // Audio player - MOVED HERE for better context
                    if session.audioFilePath != nil {
                        audioPlayerSection
                    }
                    
                    AirwayDigitalTwinView(
                        nasalIntensity: session.snoreEvents.first(where: { abs($0.offsetSeconds - playbackTime) < 2.0 })?.nasalIntensity ?? session.nasalIntensity,
                        palatalIntensity: session.snoreEvents.first(where: { abs($0.offsetSeconds - playbackTime) < 2.0 })?.palatalIntensity ?? session.palatalIntensity,
                        lingualIntensity: session.snoreEvents.first(where: { abs($0.offsetSeconds - playbackTime) < 2.0 })?.lingualIntensity ?? session.lingualIntensity
                    )
                    
                    
                    // Snore events summary
                    if !session.snoreEvents.isEmpty {
                        eventsSection(
                            title: "Mapa de Ronquidos",
                            icon: "waveform",
                            color: .somAccent
                        ) {
                            VStack(spacing: 16) {
                                aiInsightBox(text: aiReport.snoreInsight, color: .somAccent)
                                integratedSnoreLegend.padding(.bottom, 8)
                                
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
                                aiInsightBox(text: aiReport.apneaInsight, color: worstApneaColor)
                                integratedApneaLegend.padding(.bottom, 8)
                                
                                let grouped = groupApneaEventsByHour(session.apneaEvents)
                                ForEach(grouped.keys.sorted(), id: \.self) { hourKey in
                                    let events = grouped[hourKey] ?? []
                                    apneaHourRow(hourKey: hourKey, events: events)
                                }
                            }
                        }
                    }


                    disclaimerView.padding(.bottom, 32)
                }
                .padding()
            }
        }
        .navigationTitle(session.endDate.formatted(.dateTime.weekday(.abbreviated).day().month()))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.somBackground, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onDisappear { stopPlayback() }
    }

    // MARK: - AI Components

    private func aiInsightBox(text: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "sparkles")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
                .padding(10)
                .background(color.opacity(0.12))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text("ANÁLISIS IA")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(color)
                    .tracking(1.5)
                
                Text(text)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .lineSpacing(4)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .somGlassStyle(cornerRadius: 18)
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
        case 70...100: return .somSafe
        case 40..<70:  return .somWarning
        default:       return .somApnea
        }
    }

    // MARK: - Header Stats

    private var headerStats: some View {
        VStack(spacing: 32) {
            // Neon Score Gauge
            ZStack {
                // Outer Glow
                Circle()
                    .stroke(scoreColor.opacity(0.3), lineWidth: 18)
                    .blur(radius: 15)
                    .frame(width: 170, height: 170)
                
                Circle()
                    .stroke(Color.somSurfaceHigh.opacity(0.4), lineWidth: 14)
                    .frame(width: 170, height: 170)
                
                Circle()
                    .trim(from: 0, to: CGFloat(session.snoreScore) / 100)
                    .stroke(
                        AngularGradient(
                            colors: [scoreColor.opacity(0.6), scoreColor],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .frame(width: 170, height: 170)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: -2) {
                    HStack(spacing: 4) {
                        Text("\(session.snoreScore)")
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Button {
                            showScoreInfo = true
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.system(size: 14))
                                .foregroundColor(.somTextSecondary)
                        }
                        .offset(y: -10)
                    }
                    
                    Text("Puntos")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.somTextSecondary)
                }
            }
            .padding(.top, 10)
            .sheet(isPresented: $showScoreInfo) {
                ScoreInfoSheetView()
                    .presentationDetents([.medium])
            }
            
            // Stats Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                statTile(label: "Duración", value: session.formattedDuration, unit: "", color: .somSafe)
                statTile(label: "Roncando", value: String(format: "%.0f", session.snorePercentage), unit: "%", color: .somAccent)
                statTile(label: "Pico", value: String(format: "%.0f", session.peakDecibels), unit: "dB", color: .somWarning)
                statTile(label: "Apneas", value: "\(session.apneaEvents.count)", unit: "ev", color: .somApnea)
            }
        }
    }

    private func statTile(label: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .black))
                .foregroundColor(.somTextSecondary)
                .tracking(1)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                if !unit.isEmpty {
                    Text(unit).font(.caption2).foregroundColor(.somTextSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .somGlassStyle(cornerRadius: 18)
    }

    // MARK: - Events Section

    @ViewBuilder
    private func eventsSection<Content: View>(
        title: String, icon: String, color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: icon)
                .font(.system(size: 14, weight: .black))
                .foregroundColor(color)
                .tracking(1)

            VStack(spacing: 12) {
                content()
            }
        }
        .padding(20)
        .somGlassStyle(cornerRadius: 24)
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

    private func setupPlayer() {
        print("[Somnera] Setting up player for session: \(session.id)")
        
        let url = AudioFileService.shared.audioURL(for: session.id)
        
        // 1. Verify file exists and check size
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: url.path)
            let fileSize = attr[FileAttributeKey.size] as? UInt64 ?? 0
            print("[Somnera] 📁 File Info: Size \(fileSize) bytes | Path: \(url.path)")
            
            if fileSize == 0 {
                print("[Somnera] ❌ Error: Audio file is empty (0 bytes)")
                return
            }
        } catch {
            print("[Somnera] ❌ Error: Could not check file attributes: \(error.localizedDescription)")
            return
        }
        
        do {
            // 2. Configure session
            try AudioSessionManager.shared.switchToPlayback()
            
            // 3. Init player with fallback
            do {
                player = try AVAudioPlayer(contentsOf: url)
            } catch {
                print("[Somnera] ⚠️ URL init failed (Error -50?), trying Data fallback...")
                let data = try Data(contentsOf: url)
                player = try AVAudioPlayer(data: data)
            }
            
            player?.prepareToPlay()
            print("[Somnera] ✅ Player ready. Duration: \(player?.duration ?? 0)s")
        } catch {
            print("[Somnera] ❌ Final player failure: \(error.localizedDescription)")
        }
    }

    private func togglePlayback() {
        guard let player else {
            print("[Somnera] ❌ Player not initialized")
            setupPlayer() // Try to re-init if player is nil
            return
        }
        
        if isPlaying {
            player.pause()
            playbackTimer?.invalidate()
            print("[Somnera] ⏸ Paused at \(player.currentTime)")
        } else {
            do {
                try AudioSessionManager.shared.switchToPlayback()
                if player.play() {
                    playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                        self.updateProgress()
                    }
                    print("[Somnera] ▶️ Playing...")
                } else {
                    print("[Somnera] ❌ Player.play() returned false")
                }
            } catch {
                print("[Somnera] ❌ Session switch failed: \(error)")
            }
        }
        isPlaying.toggle()
    }

    private func updateProgress() {
        guard let p = player else { return }
        self.playbackTime = p.currentTime
        self.playbackProgress = p.currentTime / max(1, p.duration)
        
        if !p.isPlaying && isPlaying {
            self.isPlaying = false
            self.playbackTimer?.invalidate()
            print("[Somnera] ⏹ Playback finished")
        }
    }
    private func stopPlayback() { player?.stop(); playbackTimer?.invalidate() }
    private func formatTime(_ t: TimeInterval) -> String { let m = Int(t) / 60; let s = Int(t) % 60; return String(format: "%d:%02d", m, s) }
}


// MARK: - Insight Card

struct InsightCardView: View {
    let session: SleepSession
    @State private var animate = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("RESUMEN DE LA NOCHE", systemImage: "sparkles")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.somAccent)
                    .tracking(1)
                Spacer()
                Text(session.startDate.formatted(.dateTime.hour().minute()))
                    .font(.caption2)
                    .foregroundColor(.somTextSecondary)
            }
            
            Text(session.insightSummary)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .background(
            ZStack {
                Color.white.opacity(0.03)
                LinearGradient(
                    colors: [.somAccent.opacity(0.1), .clear],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [.somAccent.opacity(0.5), .clear, .white.opacity(0.1)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .somAccent.opacity(0.1), radius: 20, x: 0, y: 10)
        .scaleEffect(animate ? 1.0 : 0.98)
        .opacity(animate ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                animate = true
            }
        }
    }
}

// MARK: - Score Info Sheet

struct ScoreInfoSheetView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.somBackground.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Image(systemName: "chart.bar.doc.horizontal.fill")
                        .font(.title2)
                        .foregroundColor(.somAccent)
                    Text("Cálculo de Puntuación")
                        .font(.system(.title3, design: .rounded).bold())
                        .foregroundColor(.white)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.somTextSecondary)
                    }
                }
                
                Text("Tu puntuación Somnera mide la severidad de la noche basándose en 4 pilares clínicos:")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.somTextSecondary)
                
                ScrollView {
                    VStack(spacing: 16) {
                        scorePillar(
                            title: "PERSISTENCIA (50%)",
                            desc: "Calculado sobre el tiempo total roncando vs. tiempo en cama.",
                            icon: "clock.fill",
                            color: .somAccent
                        )
                        
                        scorePillar(
                            title: "INTENSIDAD (20%)",
                            desc: "Basado en el pico máximo de decibelios (dB) alcanzado.",
                            icon: "waveform",
                            color: .somWarning
                        )
                        
                        scorePillar(
                            title: "RIESGO RESPIRATORIO",
                            desc: "Puntos adicionales por cada pausa de aire (apnea) detectada.",
                            icon: "lungs.fill",
                            color: .somApnea
                        )
                        
                        scorePillar(
                            title: "FRECUENCIA",
                            desc: "Bonificación por la densidad de eventos detectados por hora.",
                            icon: "calendar.badge.clock",
                            color: .somSafe
                        )
                    }
                    .padding(.bottom, 20)
                }
            }
            .padding(30)
        }
    }
    
    private func scorePillar(title: String, desc: String, icon: String, color: Color) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(color)
                    .tracking(1)
                Text(desc)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.somSurface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
