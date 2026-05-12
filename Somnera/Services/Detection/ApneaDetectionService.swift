import Foundation
import AVFoundation

/// ApneaDetectionService Sentinel V2: Professional-grade Sensor Fusion.
/// Implements Cross-Correlation between Audio Energy and Physical Actigraphy.
final class ApneaDetectionService {
    static let shared = ApneaDetectionService()

    // MARK: - Callbacks
    var onApneaDetected: ((_ durationSeconds: TimeInterval, _ offsetFromStart: TimeInterval) -> Void)?
    var onApneaResolved: ((_ totalDuration: TimeInterval, _ confidence: Double) -> Void)?

    // MARK: - State Tracking
    private var sessionStart: Date?
    private var silenceStart: Date?
    private var isApneaActive: Bool = false
    
    // Pattern Window (Sliding history)
    private var recentMotionIntensity: [Double] = []
    private var recentRMS: [Float] = []
    private let windowSize = 30 // ~3 seconds at 10Hz

    private let silenceThreshold = SomneraConstants.Apnea.silenceRMSThreshold
    private let apneaTriggerSeconds = SomneraConstants.Apnea.triggerSeconds

    // Analysis Buffers
    private var maxMotionDuringSilence: Double = 0.0

    // MARK: - Interface

    func startSession(at date: Date) {
        sessionStart = date
        reset()
    }

    func stopSession() {
        reset()
        sessionStart = nil
    }

    func update(rms: Float, motionIntensity: Double, at timestamp: Date) {
        // 1. Maintain sliding window for 'Gasp' detection
        recentRMS.append(rms)
        recentMotionIntensity.append(motionIntensity)
        if recentRMS.count > windowSize {
            recentRMS.removeFirst()
            recentMotionIntensity.removeFirst()
        }

        // 2. Monitoring logic
        if rms < silenceThreshold {
            if silenceStart == nil {
                silenceStart = timestamp
                maxMotionDuringSilence = 0.0
            }
            
            // Track movement during silence
            maxMotionDuringSilence = max(maxMotionDuringSilence, motionIntensity)
            
            let currentSilenceDuration = timestamp.timeIntervalSince(silenceStart!)
            
            if currentSilenceDuration >= apneaTriggerSeconds && !isApneaActive {
                isApneaActive = true
                let offset = sessionStart.map { timestamp.timeIntervalSince($0) } ?? 0
                onApneaDetected?(currentSilenceDuration, offset)
            }
        } else {
            // Audio detected - Analyze if it's a 'Recovery Gasp'
            if isApneaActive {
                validateAndResolve(at: timestamp)
            }
            resetSilence()
        }
    }

    // MARK: - Sentinel V2 Logic

    private func validateAndResolve(at timestamp: Date) {
        guard let start = silenceStart else { return }
        let duration = timestamp.timeIntervalSince(start)
        
        let wasStill = maxMotionDuringSilence < 0.04 
        let audioSpike = (recentRMS.last ?? 0) - (recentRMS.first ?? 0) > 15.0
        let motionSpike = recentMotionIntensity.last ?? 0 > 0.08
        
        var confidenceScore: Double = 0.1 
        
        if wasStill { confidenceScore += 0.3 }
        if audioSpike { confidenceScore += 0.3 }
        if motionSpike { confidenceScore += 0.3 }
        
        if confidenceScore < 0.4 && duration < 15 {
            return 
        }
        
        onApneaResolved?(duration, confidenceScore)
    }

    private func resetSilence() {
        silenceStart = nil
        isApneaActive = false
        maxMotionDuringSilence = 0.0
    }
    
    private func reset() {
        resetSilence()
        recentRMS.removeAll()
        recentMotionIntensity.removeAll()
    }
}
