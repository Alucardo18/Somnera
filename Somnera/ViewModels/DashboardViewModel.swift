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

    var weeklyScores: [Int] {
        // Last 7 sessions scores (oldest → newest)
        sessions.prefix(7).reversed().map { $0.snoreScore }
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

    func deleteAllSessions() {
        storageService.deleteAll()
        sessions = []
    }
}
