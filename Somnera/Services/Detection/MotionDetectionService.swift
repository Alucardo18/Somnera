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
    var onMotionUpdate: ((_ intensity: Double, _ tiltAngle: Double, _ rawG: Double) -> Void)?
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
        // Angle relative to vertical (Z-axis)
        let tiltAngle = acos(min(1.0, abs(z))) * (180.0 / .pi)
        let isFlat = tiltAngle < 25.0 // More permissive flat detection (within 25 degrees)
        
        if !isFlat {
            if currentSurface != .handheld {
                currentSurface = .handheld
                onSurfaceDetected?(.handheld)
                varianceBuffer.removeAll()
            }
        } else {
            // --- CONTINUOUS SURFACE MONITORING ---
            varianceBuffer.append(intensity)
            if varianceBuffer.count > calibrationLimit {
                varianceBuffer.removeFirst()
                updateSurfaceType()
            }
        }
        
        let smoothedIntensity = (intensity * 0.2) + (lastIntensity * 0.8)
        lastIntensity = smoothedIntensity
        
        // Pass all telemetry to the callback
        onMotionUpdate?(smoothedIntensity, tiltAngle, intensity)
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
