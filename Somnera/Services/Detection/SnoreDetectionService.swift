import SoundAnalysis
import AVFoundation
import CoreML
import Combine

/// Wraps Apple's SoundAnalysis framework to classify snoring in real-time.
/// Falls back to a placeholder classifier until SomneraClassifier.mlmodel is trained.
final class SnoreDetectionService: NSObject, SNResultsObserving {
    static let shared = SnoreDetectionService()

    // MARK: - Callbacks
    var onSnoreDetected: ((_ confidence: Double, _ offsetFromStart: TimeInterval, _ distance: Double) -> Void)?
    var onDistanceEstimated: ((_ meters: Double) -> Void)?

    // MARK: - Private
    private var streamAnalyzer: SNAudioStreamAnalyzer?
    private var sessionStart: Date?
    private var lastDistance: Double = 0.5
    private(set) var isSnoring: Bool = false
    private var confidenceThreshold: Double = SomneraConstants.Snore.confidenceThreshold
    private let analysisQueue = DispatchQueue(label: "com.somnera.soundAnalysis", qos: .userInitiated)

    // MARK: - Setup

    /// Call after AudioCaptureService has started to get the live input format.
    func setup(format: AVAudioFormat, confidenceThreshold: Double? = nil) throws {
        if let threshold = confidenceThreshold {
            self.confidenceThreshold = threshold
        }
        streamAnalyzer = SNAudioStreamAnalyzer(format: format)

        let request: SNClassifySoundRequest
        
        // Attempt to load trained model with robust fallback
        if let modelURL = Bundle.main.url(forResource: SomneraConstants.Snore.modelFileName, withExtension: "mlmodelc") {
            do {
                let config = MLModelConfiguration()
                // Use default compute units to avoid ANE/fopen errors on some devices
                let mlModel = try MLModel(contentsOf: modelURL, configuration: config)
                request = try SNClassifySoundRequest(mlModel: mlModel)
                print("[Somnera] 🧠 IA: Modelo personalizado cargado con éxito.")
            } catch {
                print("[Somnera] ⚠️ IA: Error al cargar modelo personalizado, usando fallback de Apple: \(error.localizedDescription)")
                request = try SNClassifySoundRequest(classifierIdentifier: .version1)
            }
        } else {
            print("[Somnera] ℹ️ IA: Modelo personalizado no encontrado, usando detector estándar.")
            request = try SNClassifySoundRequest(classifierIdentifier: .version1)
        }

        request.windowDuration = CMTimeMakeWithSeconds(
            SomneraConstants.Snore.windowDurationSeconds,
            preferredTimescale: 44_100
        )
        request.overlapFactor = SomneraConstants.Snore.overlapFactor

        try streamAnalyzer?.add(request, withObserver: self)
    }

    func startSession(at date: Date) {
        sessionStart = date
    }

    func stopSession() {
        sessionStart = nil
    }

    /// Feed each audio buffer from AudioCaptureService into the analyzer.
    func analyze(_ buffer: AVAudioPCMBuffer, at time: AVAudioTime) {
        // Echo-Location Analysis
        if let samples = buffer.floatChannelData?[0] {
            let frameCount = Int(buffer.frameLength)
            var sum: Float = 0
            var maxVal: Float = 0
            
            for i in 0..<frameCount {
                let s = abs(samples[i])
                sum += s
                maxVal = max(maxVal, s)
            }
            
            // Heuristic Refined:
            // Snoring is percussive. In a quiet room at 1m, Crest Factor is ~10-12.
            // If the phone is face down, the crest factor drops by ~30-40%.
            
            let avg = sum / Float(frameCount)
            let crest = maxVal / (avg + 0.00001)
            
            // Adjust constant: we want a crest of ~12 to result in ~0.7m-1.0m
            // We use a power function to make it less sensitive at far distances
            // and more precise at close range.
            var estimatedMeters = 8.5 / pow(Double(crest), 0.85)
            
            // Clamp between 0.3m and 3.0m
            estimatedMeters = max(0.3, min(3.0, estimatedMeters))
            
            // Smoothing: Faster response to change (0.2 instead of 0.1)
            lastDistance = (estimatedMeters * 0.2) + (lastDistance * 0.8)
            
            DispatchQueue.main.async { [weak self] in
                self?.onDistanceEstimated?(self?.lastDistance ?? 0.5)
            }
        }

        analysisQueue.async { [weak self] in
            self?.streamAnalyzer?.analyze(buffer, atAudioFramePosition: time.sampleTime)
        }
    }

    func teardown() {
        streamAnalyzer?.removeAllRequests()
        streamAnalyzer = nil
    }

    // MARK: - SNResultsObserving

    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard
            let result = result as? SNClassificationResult
        else {
            self.isSnoring = false
            return
        }

        let snoreClass = result.classifications.first(where: {
            // Inclusive check: matches "snore" (custom) and "snoring" (Apple V1)
            let label = $0.identifier.lowercased()
            return label.contains("snore") || label.contains("snoring")
        })
        
        // Use the session-specific threshold
        if let snore = snoreClass, snore.confidence >= self.confidenceThreshold {
            self.isSnoring = true
            let offset = sessionStart.map { Date().timeIntervalSince($0) } ?? 0
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.onSnoreDetected?(snore.confidence, offset, self.lastDistance)
            }
        } else {
            self.isSnoring = false
        }
    }

    func request(_ request: SNRequest, didFailWithError error: Error) {
        print("[Somnera] SnoreDetection error: \(error.localizedDescription)")
    }
}
