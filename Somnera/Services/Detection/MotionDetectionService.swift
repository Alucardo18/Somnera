import Foundation
import CoreMotion

/// Detects micro-movements and mattress vibrations using the Accelerometer.
/// Used to augment audio data for more accurate apnea and sleep stage detection.
final class MotionDetectionService {
    
    static let shared = MotionDetectionService()
    
    private let motionManager = CMMotionManager()
    private let updateInterval = 0.1 // 10Hz for sleep tracking
    
    enum SurfaceType: String {
        case bed, nightstand, handheld, unknown
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
        let x = data.acceleration.x
        let y = data.acceleration.y
        let z = data.acceleration.z
        let magnitude = sqrt(x*x + y*y + z*z)
        let intensity = abs(magnitude - 1.0)
        
        // --- TILT DETECTION (Inclinación) ---
        // If the phone is NOT flat (Z ~ 1.0 or -1.0), it's likely being held.
        // We look for a Z-gravity of at least 0.85 to consider it "flat on a surface"
        let isFlat = abs(z) > 0.85
        
        if !isFlat {
            // Force handheld state immediately if tilted
            if currentSurface != .handheld {
                currentSurface = .handheld
                onSurfaceDetected?(.handheld)
                varianceBuffer.removeAll() // Clear buffer to avoid stale data
            }
        } else {
            // --- CONTINUOUS SURFACE MONITORING (Only when flat) ---
            varianceBuffer.append(intensity)
            if varianceBuffer.count > calibrationLimit {
                varianceBuffer.removeFirst()
                updateSurfaceType()
            }
        }
        
        // Apply a simple low-pass filter to smooth out noise
        let smoothedIntensity = (intensity * 0.2) + (lastIntensity * 0.8)
        lastIntensity = smoothedIntensity
        
        onMotionUpdate?(smoothedIntensity)
    }
    
    private func updateSurfaceType() {
        guard !varianceBuffer.isEmpty else { return }
        let avg = varianceBuffer.reduce(0, +) / Double(varianceBuffer.count)
        
        // RE-CALIBRATED THRESHOLDS:
        // - < 0.005: Nightstand (Mesa rígida con ruido ambiental)
        // - 0.005 to 0.06: Bed (Colchón/Respiración)
        // - > 0.08: Handheld
        
        let newSurface: SurfaceType
        if avg > 0.08 {
            newSurface = .handheld
        } else if avg < 0.005 {
            newSurface = .nightstand
        } else {
            newSurface = .bed
        }
        
        if newSurface != currentSurface {
            currentSurface = newSurface
            print("[Somnera] 🔍 Surface Changed: \(currentSurface.rawValue) (Avg: \(avg))")
            onSurfaceDetected?(currentSurface)
        }
    }
}
