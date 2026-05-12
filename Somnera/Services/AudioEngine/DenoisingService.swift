import Foundation
import Accelerate
import AVFoundation

/// Intelligent Noise Suppression service that filters stationary noise (fans, AC)
/// using Spectral Subtraction and Accelerate/vDSP.
final class DenoisingService {
    static let shared = DenoisingService()
    
    private var noiseFloor: [Float]?
    private let alpha: Float = 0.98 // Smoothing factor for noise estimation
    private let suppressionFactor: Float = 2.0 // How aggressive the filter is
    
    // FFT Setup
    private let fftSize: Int = 1024
    private let log2n: vDSP_Length
    private let fftSetup: FFTSetup
    
    private init() {
        self.log2n = vDSP_Length(log2(Double(fftSize)))
        self.fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2))!
    }
    
    deinit {
        vDSP_destroy_fftsetup(fftSetup)
    }
    
    /// Processes a PCM buffer and returns a clean version.
    func process(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer {
        guard let channelData = buffer.floatChannelData?[0] else { return buffer }
        let frameCount = Int(buffer.frameLength)
        
        // Output buffer
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: buffer.format, frameCapacity: buffer.frameLength) else {
            return buffer
        }
        outputBuffer.frameLength = buffer.frameLength
        let outData = outputBuffer.floatChannelData![0]
        
        // Process in chunks of fftSize
        var offset = 0
        while offset + fftSize <= frameCount {
            processChunk(input: channelData + offset, output: outData + offset)
            offset += fftSize
        }
        
        // Handle remainder (no denoising for simplicity on the tail)
        if offset < frameCount {
            for i in offset..<frameCount {
                outData[i] = channelData[i]
            }
        }
        
        return outputBuffer
    }
    
    private func processChunk(input: UnsafePointer<Float>, output: UnsafeMutablePointer<Float>) {
        var real = [Float](repeating: 0, count: fftSize / 2)
        var imag = [Float](repeating: 0, count: fftSize / 2)
        
        // 1. Convert to Split Complex
        var splitComplex = DSPSplitComplex(realp: &real, imagp: &imag)
        input.withMemoryRebound(to: DSPComplex.self, capacity: fftSize / 2) { 
            vDSP_ctoz($0, 2, &splitComplex, 1, vDSP_Length(fftSize / 2))
        }
        
        // 2. Perform Forward FFT
        vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2n, FFTDirection(kFFTDirection_Forward))
        
        // 3. Spectral Power Calculation
        var magnitudes = [Float](repeating: 0, count: fftSize / 2)
        vDSP_zvabs(&splitComplex, 1, &magnitudes, 1, vDSP_Length(fftSize / 2))
        
        // 4. Noise Floor Tracking (Adaptative)
        if noiseFloor == nil {
            noiseFloor = magnitudes
        } else {
            for i in 0..<fftSize/2 {
                // If signal is very consistent, it's noise
                noiseFloor![i] = noiseFloor![i] * alpha + magnitudes[i] * (1.0 - alpha)
            }
        }
        
        // 5. Spectral Subtraction (Wiener-ish)
        for i in 0..<fftSize/2 {
            let n = noiseFloor![i] * suppressionFactor
            let m = magnitudes[i]
            
            // Gain filter: reduce signal if it's too close to the noise floor
            let gain = max(0.1, (m - n) / max(0.001, m))
            real[i] *= gain
            imag[i] *= gain
        }
        
        // 6. Inverse FFT
        vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2n, FFTDirection(kFFTDirection_Inverse))
        
        // 7. Normalization and output
        var scale: Float = 1.0 / Float(fftSize * 2)
        vDSP_vsmul(real, 1, &scale, real, 1, vDSP_Length(fftSize / 2))
        vDSP_vsmul(imag, 1, &scale, imag, 1, vDSP_Length(fftSize / 2))
        
        output.withMemoryRebound(to: DSPComplex.self, capacity: fftSize / 2) {
            vDSP_ztoc(&splitComplex, 1, $0, 2, vDSP_Length(fftSize / 2))
        }
    }
}
