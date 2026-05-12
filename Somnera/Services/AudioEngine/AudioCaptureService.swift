import AVFoundation

/// Manages AVAudioEngine: installs a tap using the hardware's NATIVE format,
/// then converts each buffer to 16kHz mono via AVAudioConverter for analysis.
///
/// Root cause of "format mismatch" crash:
///   AVAudioEngine's inputNode must be tapped with its own hardware format.
///   You cannot force a custom sample rate in the tap format parameter.
///   Solution: tap with native format → convert offline to 16kHz mono.
final class AudioCaptureService {
    static let shared = AudioCaptureService()

    // MARK: - Properties
    private let engine        = AVAudioEngine()
    private var converter: AVAudioConverter?
    private let analysisQueue = DispatchQueue(label: "com.somnera.audioAnalysis", qos: .userInitiated)

    /// Delivers 16kHz mono PCM buffers ready for DSP + SoundAnalysis
    var onBuffer: ((AVAudioPCMBuffer, AVAudioTime) -> Void)?

    /// The 16kHz mono format used downstream (for SNAudioStreamAnalyzer setup)
    private(set) var outputFormat: AVAudioFormat = AVAudioFormat(
        standardFormatWithSampleRate: SomneraConstants.Audio.sampleRate,
        channels: 1
    )!

    var isRunning: Bool { engine.isRunning }

    // MARK: - Lifecycle

    func start() throws {
        let inputNode   = engine.inputNode
        
        // 🚀 Activar el procesamiento de voz nativo de Apple (Denoising Profesional)
        try? inputNode.setVoiceProcessingEnabled(true)
        
        // ⚠️ MUST use the hardware's native format for the tap
        let nativeFormat = inputNode.outputFormat(forBus: 0)

        // Build converter: nativeFormat → 16kHz mono Float32
        guard let conv = AVAudioConverter(from: nativeFormat, to: outputFormat) else {
            throw AudioCaptureError.converterUnavailable(
                from: nativeFormat, to: outputFormat
            )
        }
        converter = conv

        inputNode.installTap(
            onBus: 0,
            bufferSize: SomneraConstants.Audio.bufferSize,
            format: nativeFormat   // ← native format, no crash
        ) { [weak self] buffer, time in
            self?.analysisQueue.async {
                self?.convert(buffer, time: time)
            }
        }

        engine.prepare()
        try engine.start()
    }

    func stop() {
        guard engine.isRunning else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        converter = nil
    }

    // MARK: - Conversion

    private func convert(_ inputBuffer: AVAudioPCMBuffer, time: AVAudioTime) {
        guard let converter else { return }

        // Calculate how many output frames we'll produce
        let inputFrames  = AVAudioFrameCount(inputBuffer.frameLength)
        let sampleRatio  = outputFormat.sampleRate / inputBuffer.format.sampleRate
        let outputFrames = AVAudioFrameCount(Double(inputFrames) * sampleRatio + 0.5)

        guard outputFrames > 0,
              let outputBuffer = AVAudioPCMBuffer(
                pcmFormat: outputFormat,
                frameCapacity: outputFrames
              )
        else { return }

        var error: NSError?
        var inputConsumed = false

        let status = converter.convert(to: outputBuffer, error: &error) { _, outStatus in
            if inputConsumed {
                outStatus.pointee = .noDataNow
                return nil
            }
            outStatus.pointee = .haveData
            inputConsumed = true
            return inputBuffer
        }

        guard status != .error, error == nil else {
            print("[Somnera] Conversion error: \(error?.localizedDescription ?? "unknown")")
            return
        }

        // Build a corrected AVAudioTime at 16kHz for the downstream analyzer
        let outputTime = AVAudioTime(
            sampleTime: AVAudioFramePosition(
                Double(time.sampleTime) * sampleRatio
            ),
            atRate: outputFormat.sampleRate
        )

        onBuffer?(outputBuffer, outputTime)
    }
}

// MARK: - Errors

enum AudioCaptureError: LocalizedError {
    case converterUnavailable(from: AVAudioFormat, to: AVAudioFormat)

    var errorDescription: String? {
        switch self {
        case .converterUnavailable(let from, let to):
            return "Cannot create AVAudioConverter from \(from) to \(to)"
        }
    }
}
