import Foundation

/// JSON-based local persistence for SleepSession (replaces Core Data for Phase 1 simplicity).
/// Enforces max 7 sessions with rolling eviction of the oldest.
final class SessionStorageService {
    static let shared = SessionStorageService()

    private let fileURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("somnera_sessions.json")
    }()

    private let audioFileService = AudioFileService()
    private let maxSessions = SomneraConstants.Storage.maxSessions

    // MARK: - CRUD

    func fetchAll() -> [SleepSession] {
        guard let data = try? Data(contentsOf: fileURL),
              let sessions = try? JSONDecoder().decode([SleepSession].self, from: data)
        else { return [] }
        
        // Ensure uniqueness and sort by date
        var uniqueSessions: [UUID: SleepSession] = [:]
        for session in sessions {
            uniqueSessions[session.id] = session
        }
        
        return Array(uniqueSessions.values).sorted { $0.startDate > $1.startDate }
    }

    func save(_ session: SleepSession) {
        var sessionsMap: [UUID: SleepSession] = [:]
        fetchAll().forEach { sessionsMap[$0.id] = $0 }
        
        // Upsert logic: Update if exists, otherwise insert
        sessionsMap[session.id] = session
        
        var sessions = Array(sessionsMap.values).sorted { $0.startDate > $1.startDate }

        // Enforce rolling 7-session limit
        if sessions.count > maxSessions {
            let toEvict = sessions.dropFirst(maxSessions)
            toEvict.forEach { old in
                if let path = old.audioFilePath {
                    audioFileService.deleteAudio(at: path)
                }
            }
            sessions = Array(sessions.prefix(maxSessions))
        }

        if let data = try? JSONEncoder().encode(sessions) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    func delete(_ session: SleepSession) {
        var sessions = fetchAll()
        sessions.removeAll { $0.id == session.id }
        if let path = session.audioFilePath {
            audioFileService.deleteAudio(at: path)
        }
        if let data = try? JSONEncoder().encode(sessions) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    func deleteAll() {
        // 1. Clear the entire audio sessions folder
        audioFileService.clearAllAudio()
        
        // 2. Remove the sessions JSON file
        try? FileManager.default.removeItem(at: fileURL)
    }
}
