import Foundation
import CoreMotion

/// Detects micro-movements and mattress vibrations using the Accelerometer.
/// Used to augment audio data for more accurate apnea and sleep stage detection.
final class MotionDetectionService {
    
    static let shared = MotionDetectionService()
    
    private let motionManager = CMMotionManager()
    private let updateInterval = 0.1 // 10Hz for sleep tracking
    
    enum SurfaceType: String {
        case bed, nightstand, unknown
    }
    
    // Callbacks
    var onMotionUpdate: ((_ intensity: Double) -> Void)?
    var onSurfaceDetected: ((_ surface: SurfaceType) -> Void)?
    
    // State
    private(set) var isRunning = false
    private(set) var lastIntensity: Double = 0
    private(set) var currentSurface: SurfaceType = .unknown
    
    private var varianceBuffer: [Double] = []
    private let calibrationLimit = 100 // ~10 seconds of data for calibration
    
    private init() {}
    
    func start() {
        guard motionManager.isAccelerometerAvailable else {
            print("[Somnera] Accelerometer not available")
            return
        }
        
        motionManager.accelerometerUpdateInterval = updateInterval
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let data = data, error == nil else { return }
            self?.processMotion(data)
        }
        isRunning = true
    }
    
    func stop() {
        motionManager.stopAccelerometerUpdates()
        isRunning = false
    }
    
    private func processMotion(_ data: CMAccelerometerData) {
        // Calculate G-force vector magnitude
        let x = data.acceleration.x
        let y = data.acceleration.y
        let z = data.acceleration.z
        let magnitude = sqrt(x*x + y*y + z*z)
        
        // Filter out gravity (approx 1.0G) to get pure movement intensity
        let intensity = abs(magnitude - 1.0)
        
        // Surface Detection Calibration
        if currentSurface == .unknown {
            varianceBuffer.append(intensity)
            if varianceBuffer.count >= calibrationLimit {
                calibrateSurface()
            }
        }
        
        // Apply a simple low-pass filter to smooth out noise
        let smoothedIntensity = (intensity * 0.2) + (lastIntensity * 0.8)
        lastIntensity = smoothedIntensity
        
        onMotionUpdate?(smoothedIntensity)
    }
    
    private func calibrateSurface() {
        guard !varianceBuffer.isEmpty else { return }
        let avg = varianceBuffer.reduce(0, +) / Double(varianceBuffer.count)
        
        // If average micro-movement is extremely low, it's a rigid surface (nightstand)
        // Colchón suele tener un ruido base > 0.002 incluso en reposo por la elasticidad
        if avg < 0.0015 {
            currentSurface = .nightstand
        } else {
            currentSurface = .bed
        }
        
        print("[Somnera] 🔍 Surface Detected: \(currentSurface.rawValue) (Avg: \(avg))")
        onSurfaceDetected?(currentSurface)
        varianceBuffer.removeAll()
    }
}
