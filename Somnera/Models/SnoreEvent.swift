import Foundation
import SwiftData

/// A single detected snoring event within a sleep session.
@Model
final class SnoreEvent: Identifiable {
    @Attribute(.unique) var id: UUID
    var offsetSeconds: Double       // Seconds from session start
    var durationSeconds: Double
    var confidence: Double          // ML confidence 0.75–1.0
    var peakDecibels: Float
    var userFeedbackRaw: String?    // Stores Feedback enum as String for SwiftData
    
    // Spectral Intensities for Digital Twin
    var nasalIntensity: Double = 0.0
    var palatalIntensity: Double = 0.0
    var lingualIntensity: Double = 0.0
    
    // Relationship back to session
    var session: SleepSession?

    enum Feedback: String, Codable {
        case confirmed
        case rejected
    }
    
    var userFeedback: Feedback? {
        get {
            guard let raw = userFeedbackRaw else { return nil }
            return Feedback(rawValue: raw)
        }
        set {
            userFeedbackRaw = newValue?.rawValue
        }
    }

    init(
        id: UUID = UUID(),
        offsetSeconds: Double,
        durationSeconds: Double = 1.0,
        confidence: Double,
        peakDecibels: Float = 0,
        userFeedback: Feedback? = nil,
        nasalIntensity: Double = 0.0,
        palatalIntensity: Double = 0.0,
        lingualIntensity: Double = 0.0
    ) {
        self.id = id
        self.offsetSeconds = offsetSeconds
        self.durationSeconds = durationSeconds
        self.confidence = confidence
        self.peakDecibels = peakDecibels
        self.userFeedbackRaw = userFeedback?.rawValue
        self.nasalIntensity = nasalIntensity
        self.palatalIntensity = palatalIntensity
        self.lingualIntensity = lingualIntensity
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
