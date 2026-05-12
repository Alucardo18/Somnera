import Accelerate
import AVFoundation

/// DSP pre-processing: bandpass filter + Voice Activity Detection (VAD) gate.
/// All operations use Accelerate/vDSP for energy efficiency.
struct DSPFilter {

    // MARK: - VAD Gate

    /// Returns the RMS amplitude of the buffer (0.0–1.0).
    /// Returns nil when signal is below the VAD threshold (silence → skip ML).
    static func rms(of buffer: AVAudioPCMBuffer) -> Float? {
        guard let channelData = buffer.floatChannelData?[0] else { return nil }
        let frameCount = vDSP_Length(buffer.frameLength)
        guard frameCount > 0 else { return nil }

        var rmsValue: Float = 0
        vDSP_rmsqv(channelData, 1, &rmsValue, frameCount)

        // VAD gate: if silent, skip further processing
        guard rmsValue > SomneraConstants.DSP.vadRMSThreshold else { return nil }
        return rmsValue
    }

    /// Converts RMS amplitude to approximate dB SPL (0 dB floor).
    static func toDecibels(_ rms: Float) -> Float {
        guard rms > 0 else { return 0 }
        return max(0, 20 * log10(rms) + 90)   // +90 offset for human-readable scale
    }

    // MARK: - Bandpass Biquad (80 Hz – 2500 Hz @ 16 kHz)
    // Butterworth 2nd-order coefficients pre-computed for 16kHz sample rate

    /// Applies bandpass filter in-place and returns filtered samples.
    /// Removes sub-bass (<80Hz) and high-frequency content (>2500Hz).
    static func applyBandpass(to buffer: AVAudioPCMBuffer) -> [Float]? {
        guard let channelData = buffer.floatChannelData?[0] else { return nil }
        let count = Int(buffer.frameLength)

        var input = Array(UnsafeBufferPointer(start: channelData, count: count))
        var output = [Float](repeating: 0, count: count)

        // High-pass @ 80 Hz: b = [0.9945, -1.9891, 0.9945], a = [1, -1.9890, 0.9891]
        var hpB: [Float] = [0.9945, -1.9891, 0.9945]
        var hpA: [Float] = [1.0, -1.9890, 0.9891]
        applyIIR(input: input, output: &output, b: &hpB, a: &hpA, count: count)

        // Low-pass @ 2500 Hz: b = [0.2452, 0.4904, 0.2452], a = [1, -0.5095, 0.1905]
        var lpB: [Float] = [0.2452, 0.4904, 0.2452]
        var lpA: [Float] = [1.0, -0.5095, 0.1905]
        var final = [Float](repeating: 0, count: count)
        applyIIR(input: output, output: &final, b: &lpB, a: &lpA, count: count)

        return final
    }

    // MARK: - IIR Filter (Direct Form II)

    private static func applyIIR(
        input: [Float], output: inout [Float],
        b: inout [Float], a: inout [Float], count: Int
    ) {
        var w = [Float](repeating: 0, count: 3)   // state registers
        for n in 0..<count {
            let x = input[n]
            let w0 = x - a[1] * w[0] - a[2] * w[1]
            output[n] = b[0] * w0 + b[1] * w[0] + b[2] * w[1]
            w[1] = w[0]
            w[0] = w0
        }
    }
}
