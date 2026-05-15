import SwiftUI
import Charts

// Estructura para optimizar el renderizado en Charts
struct DecibelPoint: Identifiable {
    let id = UUID()
    let date: Date
    let db: Float
}

struct NightHeatmapView: View {
    let session: SleepSession
    
    // Navegación
    @State private var visibleRange: (start: Date, end: Date)
    @State private var selectedDate: Date? = nil
    @State private var chartData: [DecibelPoint] = []
    
    // IA Narrative
    @State private var aiNarrative: String = ""
    @State private var isAnalyzing = true
    
    init(session: SleepSession) {
        self.session = session
        let end = session.startDate.addingTimeInterval(7200)
        _visibleRange = State(initialValue: (session.startDate, end))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            headerView
            
            mainChart
                .frame(height: 160)
            
            navigatorView
                .frame(height: 50)
            
            // NUEVO: Narrativo IA
            narrativeCard
        }
        .padding(20)
        .somGlassStyle(cornerRadius: 24)
        .onAppear {
            prepareData()
            generateAIInsight()
        }
    }
    
    // MARK: - Components
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Resumen rápido de la noche")
                    .font(.system(size: 16, weight: .black))
                    .foregroundColor(.white)
                
                if let selectedDate = selectedDate, let point = findPoint(for: selectedDate) {
                    HStack(spacing: 8) {
                        Text(selectedDate.formatted(.dateTime.hour().minute().second()))
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                        Text("•")
                        Text("\(Int(point.db)) dB").font(.system(size: 12, weight: .black))
                    }
                    .foregroundColor(.somAccent)
                } else {
                    Text("Explora tu huella sonora")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.somTextSecondary)
                }
            }
            Spacer()
            Image(systemName: "waveform.path.ecg")
                .foregroundColor(.somAccent)
                .symbolEffect(.variableColor)
        }
    }
    
    private var mainChart: some View {
        Chart {
            ForEach(chartData.filter { $0.date >= visibleRange.start && $0.date <= visibleRange.end }) { point in
                BarMark(
                    x: .value("Hora", point.date),
                    y: .value("dB", point.db),
                    width: .fixed(2)
                )
                .foregroundStyle(colorForDB(point.db))
                .cornerRadius(1)
            }
            
            if let selectedDate = selectedDate {
                RuleMark(x: .value("Selección", selectedDate))
                    .foregroundStyle(.white)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [4]))
                    .annotation(position: .top, spacing: 0) {
                        scannerTooltip
                    }
            }
        }
        .chartXScale(domain: visibleRange.start...visibleRange.end)
        .chartYScale(domain: 0...90)
        .chartXAxis {
            AxisMarks(values: .stride(by: .minute, count: 15)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2])).foregroundStyle(.white.opacity(0.1))
                AxisValueLabel(format: .dateTime.hour().minute(), centered: true)
                    .foregroundStyle(Color.somTextSecondary).font(.system(size: 8, weight: .bold))
            }
        }
        .chartYAxis(.hidden)
        .chartXSelection(value: $selectedDate)
        .animation(.spring(response: 0.3), value: visibleRange.start)
    }
    
    private var scannerTooltip: some View {
        VStack(spacing: 2) {
            if let selectedDate = selectedDate, let point = findPoint(for: selectedDate) {
                Text("\(Int(point.db))").font(.system(size: 10, weight: .black))
                Text("dB").font(.system(size: 6, weight: .bold))
            }
        }
        .foregroundColor(.white).padding(6).background(Color.somAccent).clipShape(Circle())
        .shadow(color: .somAccent.opacity(0.5), radius: 10).offset(y: -10)
    }
    
    private var navigatorView: some View {
        GeometryReader { geo in
            let totalDuration = session.endDate.timeIntervalSince(session.startDate)
            let startProgress = visibleRange.start.timeIntervalSince(session.startDate) / totalDuration
            let endProgress = visibleRange.end.timeIntervalSince(session.startDate) / totalDuration
            let width = geo.size.width * (endProgress - startProgress)
            let offset = geo.size.width * startProgress
            
            ZStack(alignment: .leading) {
                Chart(chartData) { point in
                    AreaMark(x: .value("Hora", point.date), y: .value("dB", point.db))
                        .foregroundStyle(LinearGradient(colors: [Color.somAccent.opacity(0.2), .clear], startPoint: .top, endPoint: .bottom))
                }
                .chartXAxis(.hidden).chartYAxis(.hidden)
                
                // Visor Lens
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.somAccent, lineWidth: 2)
                    .background(Color.somAccent.opacity(0.1))
                    .frame(width: width)
                    .offset(x: offset)
                    .gesture(
                        DragGesture().onChanged { value in
                            let deltaProgress = value.translation.width / geo.size.width
                            updateVisibleRange(by: totalDuration * Double(deltaProgress))
                        }
                    )
            }
            .background(Color.black.opacity(0.2)).clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
    
    private var narrativeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundStyle(LinearGradient(colors: [.somAccent, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .symbolEffect(.pulse)
                
                Text("SOMNERA AI INSIGHT")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.somAccent)
            }
            
            if isAnalyzing {
                ProgressView()
                    .tint(.somAccent)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                Text(aiNarrative)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity)
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(LinearGradient(colors: [.somAccent.opacity(0.3), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                )
        }
    }
    
    // MARK: - Logic
    
    private func generateAIInsight() {
        // Simulamos un retraso de "análisis inteligente"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let maxDB = session.decibelTimeline.max() ?? 0
            let duration = session.endDate.timeIntervalSince(session.startDate) / 3600
            
            var insight = "Dormiste un total de \(String(format: "%.1f", duration)) horas. "
            
            if maxDB > 65 {
                insight += "Se detectó un pico de ronquido intenso de \(Int(maxDB))dB. "
            } else {
                insight += "Tu noche fue notablemente silenciosa. "
            }
            
            insight += "La mayor estabilidad respiratoria ocurrió en la segunda mitad de la noche, sugiriendo un descanso reparador."
            
            withAnimation {
                aiNarrative = insight
                isAnalyzing = false
            }
        }
    }
    
    private func prepareData() {
        let samples = session.decibelTimeline
        let totalDuration = session.endDate.timeIntervalSince(session.startDate)
        let interval = totalDuration / Double(samples.count)
        chartData = samples.enumerated().map { index, db in
            DecibelPoint(date: session.startDate.addingTimeInterval(interval * Double(index)), db: db)
        }
    }
    
    private func updateVisibleRange(by timeShift: TimeInterval) {
        let newStart = max(session.startDate, min(session.endDate.addingTimeInterval(-7200), visibleRange.start.addingTimeInterval(timeShift)))
        let newEnd = newStart.addingTimeInterval(7200)
        visibleRange = (newStart, newEnd)
    }
    
    private func findPoint(for date: Date) -> DecibelPoint? {
        chartData.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
    }
    
    private func colorForDB(_ db: Float) -> Color {
        switch db {
        case ..<35: return .cyan.opacity(0.4)
        case 35..<55: return .somSafe
        case 55..<70: return .somWarning
        default: return .somApnea
        }
    }
}

#Preview {
    ZStack {
        Color.somBackground.ignoresSafeArea()
        NightHeatmapView(session: .mock)
            .padding()
    }
}
