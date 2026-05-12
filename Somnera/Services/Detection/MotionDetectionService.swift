import Foundation
import CoreMotion

/// Detects micro-movements and mattress vibrations using the Accelerometer.
/// Used to augment audio data for more accurate apnea and sleep stage detection.
final class MotionDetectionService {
    
    static let shared = MotionDetectionService()
    
    private let motionManager = CMMotionManager()
    private let updateInterval = 0.1 // 10Hz for sleep tracking
    
    // Callbacks
    var onMotionUpdate: ((_ intensity: Double) -> Void)?
    
    // State
    private(set) var isRunning = false
    private(set) var lastIntensity: Double = 0
    
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
        
        // Apply a simple low-pass filter to smooth out noise
        let smoothedIntensity = (intensity * 0.2) + (lastIntensity * 0.8)
        lastIntensity = smoothedIntensity
        
        onMotionUpdate?(smoothedIntensity)
    }
}
