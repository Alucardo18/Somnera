import SwiftUI

struct SessionListView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var selectedSession: SleepSession? = nil
    @State private var isCalendarExpanded = false
    @State private var currentMonth = Date()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.somBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 1. Collapsible Calendar Navigator
                    CalendarNavigatorView(
                        sessions: viewModel.sessions,
                        isExpanded: $isCalendarExpanded,
                        currentMonth: $currentMonth
                    )
                    .padding(.top, 8)
                    
                    if viewModel.sessions.isEmpty {
                        Spacer()
                        emptyState
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 32) {
                                // 1. THE SLEEP GALAXY (Visual Explorer)
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Explorador Estelar")
                                        .font(.system(size: 12, weight: .black))
                                        .foregroundColor(.somAccent)
                                        .tracking(2)
                                        .padding(.horizontal)
                                    
                                    bubbleCloud
                                        .padding(.vertical, 10)
                                }
                                
                                // 2. WEEKLY SUMMARY CARD
                                weeklySummaryCard
                                    .padding(.horizontal)
                                
                                // 3. VISUAL INSIGHT GALLERY
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Análisis Reciente")
                                        .font(.system(size: 14, weight: .black))
                                        .foregroundColor(.white)
                                        .tracking(1)
                                        .padding(.horizontal)
                                    
                                    VStack(spacing: 16) {
                                        ForEach(viewModel.sessions.prefix(5)) { session in
                                            NavigationLink(destination: SessionDetailView(session: session)) {
                                                SessionInsightCard(session: session)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                }
            }
            .navigationTitle("Mis Sesiones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.somBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "circle.grid.3x3.fill")
                .font(.system(size: 60))
                .foregroundColor(.somAccent.opacity(0.3))
            Text("No hay sesiones aún")
                .font(.headline)
                .foregroundColor(.somTextSecondary)
        }
    }
    
    private var bubbleCloud: some View {
        // We arrange bubbles in a dynamic flow
        // To make it look like a "cloud", we use a simple ZStack with offsets
        // or a custom wrapping layout. For simplicity and robustness, 
        // we'll use a dynamic HStack/VStack grouping.
        
        VStack(spacing: 40) {
            let chunks = viewModel.sessions.chunked(into: 3)
            ForEach(0..<chunks.count, id: \.self) { rowIndex in
                HStack(spacing: rowIndex % 2 == 0 ? 30 : 50) {
                    ForEach(chunks[rowIndex]) { session in
                        NavigationLink(destination: SessionDetailView(session: session)) {
                            SessionBubbleView(session: session)
                        }
                    }
                }
                .offset(x: rowIndex % 2 == 0 ? 20 : -20)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var weeklySummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("RESUMEN SEMANAL")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.somAccent)
                    Text("Tendencia de Mejora")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                Spacer()
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.somSafe)
                    .font(.title2)
            }
            
            Text("Tus niveles de obstrucción nasal han bajado un 12% respecto a la semana pasada. Mantén tu posición lateral para mejores resultados.")
                .font(.system(size: 12))
                .foregroundColor(.somTextSecondary)
                .lineSpacing(4)
        }
        .padding(20)
        .background(
            ZStack {
                Color.somAccent.opacity(0.05)
                LinearGradient(colors: [.somAccent.opacity(0.1), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        )
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.somAccent.opacity(0.2), lineWidth: 1)
        )
    }
}

/// A premium circular bubble representing a sleep session.
struct SessionBubbleView: View {
    let session: SleepSession
    @State private var isAnimating = false
    
    var scoreColor: Color {
        switch session.snoreScore {
        case 0..<30:  return .somSafe
        case 30..<60: return .somWarning
        default:      return .somApnea
        }
    }
    
    // Size based on duration (from 80 to 130)
    var bubbleSize: CGFloat {
        let hours = session.duration / 3600
        return CGFloat(80 + min(50, hours * 6))
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Outer Glow
                Circle()
                    .fill(scoreColor.opacity(0.2))
                    .frame(width: bubbleSize + 15, height: bubbleSize + 15)
                    .blur(radius: isAnimating ? 15 : 5)
                
                // Glass Bubble
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: bubbleSize, height: bubbleSize)
                    .overlay(
                        Circle()
                            .stroke(scoreColor.opacity(0.4), lineWidth: 2)
                    )
                
                VStack(spacing: 2) {
                    Text("\(session.snoreScore)")
                        .font(.system(size: bubbleSize * 0.3, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(session.startDate.formatted(.dateTime.day().month()))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.somTextSecondary)
                }
            }
            .scaleEffect(isAnimating ? 1.05 : 1.0)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

struct SessionInsightCard: View {
    let session: SleepSession
    
    var scoreColor: Color {
        switch session.snoreScore {
        case 0..<30:  return .somSafe
        case 30..<60: return .somWarning
        default:      return .somApnea
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Left: Score & Date
            VStack(alignment: .leading, spacing: 4) {
                Text(session.startDate.formatted(.dateTime.weekday(.abbreviated).day().month()))
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.somTextSecondary)
                    .textCase(.uppercase)
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(session.snoreScore)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("pts")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.somTextSecondary)
                }
            }
            .frame(width: 80, alignment: .leading)
            
            // Middle: Sparkline Hypnogram
            GeometryReader { geo in
                Path { path in
                    let count = session.decibelTimeline.count
                    guard count > 1 else { return }
                    let stepX = geo.size.width / CGFloat(count - 1)
                    path.move(to: CGPoint(x: 0, y: geo.size.height))
                    
                    for (index, db) in session.decibelTimeline.enumerated() {
                        let normalized = db < 0 ? (db + 60) / 50 : (db - 30) / 50
                        let y = geo.size.height - (CGFloat(max(0.1, min(1.0, normalized))) * geo.size.height * 0.6)
                        path.addLine(to: CGPoint(x: CGFloat(index) * stepX, y: y))
                    }
                }
                .stroke(scoreColor.gradient, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
            .frame(height: 40)
            .padding(.horizontal, 10)
            
            // Right: Anatomical Quick View
            HStack(spacing: 8) {
                anatomicalMiniDot(label: "N", intensity: session.nasalIntensity)
                anatomicalMiniDot(label: "P", intensity: session.palatalIntensity)
                anatomicalMiniDot(label: "L", intensity: session.lingualIntensity)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }
    
    private func anatomicalMiniDot(label: String, intensity: Double) -> some View {
        VStack(spacing: 4) {
            Circle()
                .fill(intensity > 0.4 ? Color.somApnea : (intensity > 0.1 ? Color.somWarning : Color.somSafe))
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.somTextSecondary)
        }
    }
}

// Helper for chunking arrays
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Calendar Navigator

struct CalendarNavigatorView: View {
    let sessions: [SleepSession]
    @Binding var isExpanded: Bool
    @Binding var currentMonth: Date
    
    let calendar = Calendar.current
    let daysOfWeek = ["D", "L", "M", "M", "J", "V", "S"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(currentMonth.formatted(.dateTime.month(.wide).year()))
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button {
                    withAnimation(.spring()) { isExpanded.toggle() }
                } label: {
                    HStack {
                        Text(isExpanded ? "Cerrar" : "Calendario")
                        Image(systemName: isExpanded ? "chevron.up" : "calendar")
                    }
                    .font(.caption.bold())
                    .foregroundColor(.somAccent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.somAccent.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
            
            if isExpanded {
                monthGrid
                    .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .top)), removal: .opacity))
            } else {
                weekStrip
            }
        }
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.03))
        .overlay(Divider().background(Color.white.opacity(0.1)), alignment: .bottom)
    }
    
    private var monthGrid: some View {
        VStack(spacing: 16) {
            // Days of week
            HStack {
                ForEach(daysOfWeek.indices, id: \.self) { index in
                    Text(daysOfWeek[index])
                        .font(.caption2.bold())
                        .foregroundColor(.somTextSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            let days = generateDaysForMonth()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                ForEach(0..<days.count, id: \.self) { index in
                    if let date = days[index] {
                        dayCell(for: date)
                    } else {
                        Color.clear.frame(height: 32)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 10)
    }
    
    private var weekStrip: some View {
        HStack(spacing: 0) {
            ForEach(last7Days(), id: \.self) { date in
                dayCell(for: date, compact: true)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
    }
    
    private func dayCell(for date: Date, compact: Bool = false) -> some View {
        let sessionsOnDay = sessions.filter { calendar.isDate($0.startDate, inSameDayAs: date) }
        let hasSession = !sessionsOnDay.isEmpty
        let isToday = calendar.isDateInToday(date)
        
        // Color based on the worst score of the day
        let worstScore = sessionsOnDay.map { $0.snoreScore }.max() ?? 0
        let statusColor: Color = {
            if !hasSession { return .clear }
            if worstScore < 30 { return .somSafe }
            if worstScore < 60 { return .somWarning }
            return .somApnea
        }()
        
        return VStack(spacing: 4) {
            if !compact {
                Text(date.formatted(.dateTime.day()))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(isToday ? .somAccent : .white)
            } else {
                Text(date.formatted(.dateTime.weekday(.narrow)))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.somTextSecondary)
            }
            
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 28, height: 28)
                
                if hasSession {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                        .shadow(color: statusColor, radius: 4)
                } else if isToday {
                    Circle()
                        .stroke(Color.somAccent, lineWidth: 1)
                        .frame(width: 8, height: 8)
                }
                
                if compact {
                    Text(date.formatted(.dateTime.day()))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isToday ? .somAccent : .white)
                        .offset(y: -15)
                }
            }
        }
    }
    
    // Helpers
    private func generateDaysForMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else { return [] }
        let firstDayOfMonth = monthInterval.start
        let weekdayOfFirst = calendar.component(.weekday, from: firstDayOfMonth)
        
        var days: [Date?] = Array(repeating: nil, count: weekdayOfFirst - 1)
        
        let range = calendar.range(of: .day, in: .month, for: currentMonth)!
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(date)
            }
        }
        return days
    }
    
    private func last7Days() -> [Date] {
        let today = calendar.startOfDay(for: Date())
        return (0..<7).compactMap { day in
            calendar.date(byAdding: .day, value: -day, to: today)
        }.reversed()
    }
}
