import Foundation
import SwiftUI

/// A detected apnea event: sustained silence ≥ 10 seconds.
struct ApneaEvent: Identifiable, Codable {
    let id: UUID
    var offsetSeconds: Double       // Seconds from session start when apnea began
    var durationSeconds: Double     // Total silence duration
    var confidence: Double          // Confidence from sensor fusion (0.0 to 1.0)

    var severity: Severity {
        switch durationSeconds {
        case ..<15:    return .mild
        case 15..<30:  return .moderate
        default:       return .severe
        }
    }

    enum Severity: String, Codable {
        case mild, moderate, severe

        var label: String {
            switch self {
            case .mild:     return "Leve"
            case .moderate: return "Moderado"
            case .severe:   return "Severo"
            }
        }
        
        var color: Color {
            switch self {
            case .mild:     return .somSafe      // Green/Cyan
            case .moderate: return .somWarning   // Yellow/Orange
            case .severe:   return .somApnea     // Red
            }
        }
    }

    init(
        id: UUID = UUID(),
        offsetSeconds: Double,
        durationSeconds: Double,
        confidence: Double = 1.0
    ) {
        self.id = id
        self.offsetSeconds = offsetSeconds
        self.durationSeconds = durationSeconds
        self.confidence = confidence
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

    var formattedDuration: String {
        String(format: "%.1fs", durationSeconds)
    }
}
