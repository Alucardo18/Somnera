import Foundation

/// A single detected snoring event within a sleep session.
struct SnoreEvent: Identifiable, Codable {
    let id: UUID
    var offsetSeconds: Double       // Seconds from session start
    var durationSeconds: Double
    var confidence: Double          // ML confidence 0.75–1.0
    var peakDecibels: Float

    init(
        id: UUID = UUID(),
        offsetSeconds: Double,
        durationSeconds: Double = 1.0,
        confidence: Double,
        peakDecibels: Float = 0
    ) {
        self.id = id
        self.offsetSeconds = offsetSeconds
        self.durationSeconds = durationSeconds
        self.confidence = confidence
        self.peakDecibels = peakDecibels
    }

    var formattedOffset: String {
        let total = Int(offsetSeconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%02d:%02d", m, s)
    }
}
