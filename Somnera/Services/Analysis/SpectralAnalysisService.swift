import Foundation
import Accelerate
import AVFoundation

/// High-performance service that performs spectral analysis on audio buffers.
/// Optimized to reuse FFT setups and windows.
final class SpectralAnalysisService {
    static let shared = SpectralAnalysisService()
    
    // Frequency Band Definitions (Hz)
    private let lowBandRange: ClosedRange<Float> = 200...799     // Lingual
    private let midBandRange: ClosedRange<Float> = 800...1799    // Palatal
    private let highBandRange: ClosedRange<Float> = 1800...4000  // Nasal
    
    // Cached resources
    private var fftSetup: FFTSetup?
    private var window: [Float] = []
    private var lastLog2n: UInt = 0
    
    private let processingQueue = DispatchQueue(label: "com.somnera.spectralProcessing")
    
    /// Analyzes an audio buffer and returns intensities for the three anatomical zones.
    func analyze(buffer: AVAudioPCMBuffer) -> (nasal: Double, palatal: Double, lingual: Double) {
        guard let channelData = buffer.floatChannelData?[0] else {
            return (0, 0, 0)
        }
        
        let frameCount = Int(buffer.frameLength)
        let log2n = UInt(round(log2(Double(frameCount))))
        let n = Int(1 << log2n)
        
        // 1. Prepare/Reuse Resources
        if log2n != lastLog2n {
            if let oldSetup = fftSetup { vDSP_destroy_fftsetup(oldSetup) }
            fftSetup = vDSP_create_fftsetup(log2n, Int32(kFFTRadix2))
            
            window = [Float](repeating: 0, count: n)
            vDSP_hann_window(&window, vDSP_Length(n), Int32(vDSP_HANN_NORM))
            
            lastLog2n = log2n
        }
        
        guard let setup = fftSetup else { return (0, 0, 0) }
        
        // 2. Apply Window
        var windowedInput = [Float](repeating: 0, count: n)
        vDSP_vmul(channelData, 1, window, 1, &windowedInput, 1, vDSP_Length(n))
        
        // 3. Perform FFT
        var realp = [Float](repeating: 0, count: n/2)
        var imagp = [Float](repeating: 0, count: n/2)
        var output = DSPSplitComplex(realp: &realp, imagp: &imagp)
        
        windowedInput.withUnsafeBufferPointer { pointer in
            pointer.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: n/2) { complexPointer in
                vDSP_ctoz(complexPointer, 2, &output, 1, vDSP_Length(n/2))
            }
        }
        
        vDSP_fft_zrip(setup, &output, 1, log2n, FFTDirection(kFFTDirection_Forward))
        
        // 4. Calculate Magnitudes
        var magnitudes = [Float](repeating: 0, count: n/2)
        vDSP_zvmags(&output, 1, &magnitudes, 1, vDSP_Length(n/2))
        
        // 5. Aggregate Energy into Bands
        let sampleRate = Float(buffer.format.sampleRate)
        let binFrequencyWidth = sampleRate / Float(n)
        
        var lowEnergy: Float = 0
        var midEnergy: Float = 0
        var highEnergy: Float = 0
        
        for i in 1..<n/2 { // Skip DC component
            let frequency = Float(i) * binFrequencyWidth
            let magnitude = magnitudes[i]
            
            if lowBandRange.contains(frequency) {
                lowEnergy += magnitude
            } else if midBandRange.contains(frequency) {
                midEnergy += magnitude
            } else if highBandRange.contains(frequency) {
                highEnergy += magnitude
            }
        }
        
        // 6. Normalize results
        let totalEnergy = lowEnergy + midEnergy + highEnergy
        guard totalEnergy > 1e-10 else { return (0, 0, 0) }
        
        return (
            nasal: Double(highEnergy / totalEnergy),
            palatal: Double(midEnergy / totalEnergy),
            lingual: Double(lowEnergy / totalEnergy)
        )
    }
    
    deinit {
        if let setup = fftSetup {
            vDSP_destroy_fftsetup(setup)
        }
    }
}
