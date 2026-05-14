import Foundation
import CoreMedia

enum SomneraConstants {

    // MARK: - Audio Capture
    enum Audio {
        static let sampleRate: Double       = 16_000
        static let channels: Int            = 1
        static let bufferSize: UInt32       = 4_096
        static let ioBufferDuration: Double = 0.04     // 40ms
        static let encoderBitRate: Int      = 32_000   // 32 kbps AAC
    }

    // MARK: - DSP Filter
    enum DSP {
        static let bandpassLowHz: Float  = 80.0
        static let bandpassHighHz: Float = 2_500.0
        static let vadRMSThreshold: Float = 0.0008  // Más sensible (~28 dB)
    }

    // MARK: - Snore Detection
    enum Snore {
        static let confidenceThreshold: Double = 0.70
        static let windowDurationSeconds: Float64 = 1.0
        static let overlapFactor: Double = 0.5
        static let minDurationSeconds: Double = 0.4    // ignore micro-triggers
        static let modelFileName: String = "SomneraClassifier"
        static let snoreLabel: String    = "snoring"
    }

    // MARK: - Apnea Detection
    enum Apnea {
        static let silenceRMSThreshold: Float   = 0.0006  // ~22 dB (Más estricto para silencios)
        static let triggerSeconds: TimeInterval  = 12.0    // 12s para más seguridad
        static let checkIntervalSeconds: Double  = 1.0
    }

    // MARK: - Storage
    enum Storage {
        static let maxSessions: Int         = 7
        static let sessionsFolderName       = "SomneraSessions"
        static let audioExtension           = "m4a"
    }

    // MARK: - UI / Design
    enum Design {
        static let cornerRadius: CGFloat    = 20
        static let cardPadding: CGFloat     = 16
    }
}
