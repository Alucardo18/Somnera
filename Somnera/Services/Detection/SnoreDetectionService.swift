import SoundAnalysis
import AVFoundation
import CoreML
import Combine

/// Wraps Apple's SoundAnalysis framework to classify snoring in real-time.
/// Falls back to a placeholder classifier until SomneraClassifier.mlmodel is trained.
final class SnoreDetectionService: NSObject, SNResultsObserving {
    static let shared = SnoreDetectionService()

    // MARK: - Callbacks
    var onSnoreDetected: ((_ confidence: Double, _ offsetFromStart: TimeInterval) -> Void)?

    // MARK: - Private
    private var streamAnalyzer: SNAudioStreamAnalyzer?
    private var sessionStart: Date?
    private let analysisQueue = DispatchQueue(label: "com.somnera.soundAnalysis", qos: .userInitiated)

    // MARK: - Setup

    /// Call after AudioCaptureService has started to get the live input format.
    func setup(format: AVAudioFormat) throws {
        streamAnalyzer = SNAudioStreamAnalyzer(format: format)

        let request: SNClassifySoundRequest

        // Attempt to load trained model — falls back to Apple's built-in classifier
        if let modelURL = Bundle.main.url(forResource: SomneraConstants.Snore.modelFileName, withExtension: "mlmodelc") {
            let config = MLModelConfiguration()
            config.computeUnits = .all  // Use Neural Engine when available
            let mlModel = try MLModel(contentsOf: modelURL, configuration: config)
            request = try SNClassifySoundRequest(mlModel: mlModel)
        } else {
            // Placeholder: classify all sounds (for development before model is trained)
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
            let result = result as? SNClassificationResult,
            let snoreClass = result.classifications.first(where: {
                $0.identifier.lowercased().contains(SomneraConstants.Snore.snoreLabel)
            }),
            snoreClass.confidence >= SomneraConstants.Snore.confidenceThreshold
        else { return }

        let offset = sessionStart.map { Date().timeIntervalSince($0) } ?? 0
        DispatchQueue.main.async { [weak self] in
            self?.onSnoreDetected?(snoreClass.confidence, offset)
        }
    }

    func request(_ request: SNRequest, didFailWithError error: Error) {
        print("[Somnera] SnoreDetection error: \(error.localizedDescription)")
    }
}
