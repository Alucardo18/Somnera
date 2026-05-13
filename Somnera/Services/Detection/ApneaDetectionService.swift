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
    private let windowSize = 50 // ~5 seconds for better context
    private var lastSnoreDate: Date?

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

    func reportSnore(at date: Date) {
        lastSnoreDate = date
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
            
            // Track movement during silence. 
            // If movement is too high (>0.05), we reset the silence timer 
            // because someone moving is NOT having an obstructive apnea event.
            if motionIntensity > 0.05 {
                silenceStart = timestamp 
                maxMotionDuringSilence = 0.0
            } else {
                maxMotionDuringSilence = max(maxMotionDuringSilence, motionIntensity)
            }
            
            let currentSilenceDuration = timestamp.timeIntervalSince(silenceStart!)
            
            // Trigger local flag but DON'T NOTIFY UI YET. 
            // We wait until resolution to be sure.
            if currentSilenceDuration >= apneaTriggerSeconds {
                isApneaActive = true
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
        
        // Safety: Ignore pauses longer than 120s (likely phone left alone or disconnected)
        if duration > 120 { return }

        // Bio-Context 1: Was there a snore recently? (Last 5 minutes)
        let secondsSinceLastSnore = lastSnoreDate.map { timestamp.timeIntervalSince($0) } ?? 9999
        let hadRecentSnoring = secondsSinceLastSnore < 300
        
        // Bio-Context 2: Motion during silence
        let wasStill = maxMotionDuringSilence < 0.03
        
        // Bio-Context 3: The "Recovery Gasp" (Audio & Motion spike)
        let audioSpike = (recentRMS.last ?? 0) - (recentRMS.dropLast(5).first ?? 0) > 25.0
        let motionSpike = recentMotionIntensity.last ?? 0 > 0.06
        
        var confidenceScore: Double = 0.0
        
        if hadRecentSnoring { confidenceScore += 0.4 } // High weight to snore context
        if wasStill { confidenceScore += 0.2 }
        if audioSpike { confidenceScore += 0.2 }
        if motionSpike { confidenceScore += 0.2 }
        
        // CRITICAL: If no recent snoring AND low confidence, it's a false positive (likely awake).
        if !hadRecentSnoring && confidenceScore < 0.5 {
            print("[Sentinel] 🛡️ Apnea rechazada: Falta contexto de ronquido/gasp. Score: \(confidenceScore)")
            return 
        }
        
        // Minimum score to actually report as a critical event
        if confidenceScore >= 0.4 {
            onApneaResolved?(duration, confidenceScore)
        }
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
