import Foundation
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {

    @Published var sessions: [SleepSession] = []
    @Published var isLoading: Bool = false
    @Published var sessionToNavigate: SleepSession? = nil // Nueva propiedad para auto-navegación

    private let storageService = SessionStorageService()
    private let healthKitService = HealthKitService()

    // MARK: - Load

    func load() {
        isLoading = true
        sessions = storageService.fetchAll()
        isLoading = false
    }

    func requestHealthKit() async {
        try? await healthKitService.requestAuthorization()
    }

    // MARK: - Computed

    var lastSession: SleepSession? { sessions.first }

    /// Data point for the weekly chart
    struct ChartData: Identifiable {
        let id = UUID()
        let label: String
        let score: Int
        let apneaCount: Int
    }

    var weeklyChartData: [ChartData] {
        let calendar = Calendar.current
        var calendarWithSundayStart = calendar
        calendarWithSundayStart.firstWeekday = 1 // 1 = Domingo
        
        let today = calendarWithSundayStart.startOfDay(for: Date())
        
        // Encontrar el inicio de la semana (Domingo)
        let components = calendarWithSundayStart.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        guard let startOfWeek = calendarWithSundayStart.date(from: components) else { return [] }
        
        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: "es_ES")
        dayFormatter.dateFormat = "EEEEE" // Una letra (D, L, M, X...)
        
        return (0..<7).map { dayOffset in
            let day = calendarWithSundayStart.date(byAdding: .day, value: dayOffset, to: startOfWeek)!
            
            // Buscar sesiones en este día específico
            let sessionsOnDay = sessions.filter {
                calendarWithSundayStart.isDate($0.startDate, inSameDayAs: day)
            }
            
            let score = sessionsOnDay.isEmpty ? 0 :
                sessionsOnDay.map { $0.snoreScore }.reduce(0, +) / sessionsOnDay.count
            
            let apneaCount = sessionsOnDay.isEmpty ? 0 :
                sessionsOnDay.map { $0.apneaEventCount }.reduce(0, +) / sessionsOnDay.count
            
            return ChartData(
                label: dayFormatter.string(from: day).uppercased(),
                score: score,
                apneaCount: apneaCount
            )
        }
    }

    var averageScore: Int {
        guard !sessions.isEmpty else { return 0 }
        return sessions.prefix(7).map { $0.snoreScore }.reduce(0, +) / min(sessions.count, 7)
    }

    var weeklyAnatomicalAnalysis: (type: String, description: String, icon: String) {
        let last7 = sessions.prefix(7)
        guard !last7.isEmpty else { return ("Pendiente", "Aún necesitamos más datos para analizar tu tendencia.", "waveform") }
        
        let n = Double(last7.count)
        let avgNasal = last7.map { $0.nasalIntensity }.reduce(0, +) / n
        let avgPalatal = last7.map { $0.palatalIntensity }.reduce(0, +) / n
        let avgLingual = last7.map { $0.lingualIntensity }.reduce(0, +) / n
        
        if avgNasal >= avgPalatal && avgNasal >= avgLingual {
            return ("Nasal", "Tus ronquidos ocurren mayormente en las vías superiores. Esto suele estar relacionado con congestión o desviación del tabique.", "nose")
        } else if avgPalatal >= avgNasal && avgPalatal >= avgLingual {
            return ("Palatal", "La vibración ocurre principalmente en el paladar blando. Es el tipo más común de ronquido por relajación muscular.", "mouth")
        } else {
            return ("Lingual", "La base de la lengua obstruye parcialmente el paso del aire. Suele ocurrir al dormir boca arriba.", "tongue")
        }
    }

    // MARK: - Delete

    func delete(_ session: SleepSession) {
        storageService.delete(session)
        sessions = storageService.fetchAll()
    }
    
    func updateFeedback(for session: SleepSession, event: SnoreEvent, feedback: SnoreEvent.Feedback) {
        var updatedSession = session
        if let index = updatedSession.snoreEvents.firstIndex(where: { $0.id == event.id }) {
            updatedSession.snoreEvents[index].userFeedback = feedback
            storageService.save(updatedSession)
            
            // Reload to update UI
            sessions = storageService.fetchAll()
        }
    }

    func deleteAllSessions() {
        storageService.deleteAll()
        sessions = []
    }
}
