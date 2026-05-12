import Foundation
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {

    @Published var sessions: [SleepSession] = []
    @Published var isLoading: Bool = false

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
    }

    var weeklyChartData: [ChartData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Generate last 7 days (including today)
        let last7Days = (0..<7).map { dayOffset -> Date in
            calendar.date(byAdding: .day, value: -dayOffset, to: today)!
        }.reversed()
        
        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: "es_ES")
        dayFormatter.dateFormat = "EEEEE" // One letter (L, M, X...)
        
        return last7Days.map { day in
            // Find all sessions on this specific day
            let sessionsOnDay = sessions.filter {
                calendar.isDate($0.startDate, inSameDayAs: day)
            }
            
            // If multiple sessions, take the average score (or max for safety)
            let score = sessionsOnDay.isEmpty ? 0 : 
                sessionsOnDay.map { $0.snoreScore }.reduce(0, +) / sessionsOnDay.count
            
            return ChartData(
                label: dayFormatter.string(from: day).uppercased(),
                score: score
            )
        }
    }

    var averageScore: Int {
        guard !sessions.isEmpty else { return 0 }
        return sessions.prefix(7).map { $0.snoreScore }.reduce(0, +) / min(sessions.count, 7)
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
