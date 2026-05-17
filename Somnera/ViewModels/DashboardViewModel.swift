import Foundation
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {

    @Published var sessions: [SleepSession] = []
    @Published var isLoading: Bool = false
    @Published var sessionToNavigate: SleepSession? = nil // Nueva propiedad para auto-navegación

    private let storageService = SessionStorageService.shared
    private let healthKitService = HealthKitService.shared
    private let analyticsService = SessionAnalyticsService.shared

    // MARK: - Load

    func load() {
        isLoading = true
        
        // 1. Obtener todas las sesiones de la base de datos
        let allSessions = storageService.fetchAll()
        
        // 2. Rutina de Autocuidado Homeostático (Depuración higiénica)
        // Purga automáticamente sesiones vacías o accidentales menores a 15 segundos
        var validSessions: [SleepSession] = []
        for session in allSessions {
            let duration = session.endDate.timeIntervalSince(session.startDate)
            if duration < 15.0 {
                print("[Somnera] 🧹 Autolimpieza: eliminando sesión inválida/fantasma (\(Int(duration))s): \(session.id.uuidString)")
                storageService.delete(session)
            } else {
                validSessions.append(session)
            }
        }
        
        self.sessions = validSessions
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
        let score: Int? // Opcional para distinguir de "Sin datos"
        let apneaCount: Int
    }

    var weeklyChartData: [ChartData] {
        let calendar = Calendar.current
        var calendarWithSundayStart = calendar
        calendarWithSundayStart.firstWeekday = 1 // 1 = Domingo
        
        let today = calendarWithSundayStart.startOfDay(for: Date())
        
        let components = calendarWithSundayStart.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        guard let startOfWeek = calendarWithSundayStart.date(from: components) else { return [] }
        
        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: "es_ES")
        dayFormatter.dateFormat = "EEEEE"
        
        return (0..<7).map { dayOffset in
            let day = calendarWithSundayStart.date(byAdding: .day, value: dayOffset, to: startOfWeek)!
            
            let sessionsOnDay = sessions.filter {
                calendarWithSundayStart.isDate($0.startDate, inSameDayAs: day)
            }
            
            let score = sessionsOnDay.isEmpty ? nil :
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

    var weeklyInsight: SessionAnalyticsService.WeeklyReport {
        analyticsService.generateWeeklyReport(sessions: sessions)
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
        event.userFeedback = feedback
        storageService.save(session)
        
        // Reload to update UI
        sessions = storageService.fetchAll()
    }

    func deleteAllSessions() {
        storageService.deleteAll()
        sessions = []
    }
}
