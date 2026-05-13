import Foundation
import AVFoundation
import Combine
import UIKit

/// Central coordinator for a live sleep recording session.
/// Connects AudioCapture → DSP → SnoreDetection + ApneaDetection → Storage.
@MainActor
final class RecordingViewModel: ObservableObject {

    // MARK: - Published State
    @Published var isRecording: Bool = false
    @Published var elapsedSeconds: Int = 0
    @Published var currentRMS: Float = 0
    @Published var currentDecibels: Float = 0
    @Published var snoreEventCount: Int = 0
    @Published var apneaEventCount: Int = 0
    @Published var isApneaActive: Bool = false
    @Published var latestWaveform: [Float] = Array(repeating: 0, count: 60)
    @Published var peakDecibels: Float = -100
    @Published var isCharging: Bool = false
    @Published var currentMotionIntensity: Double = 0
    @Published var session: SleepSession? = nil // Nueva propiedad para exponer la sesión terminada
    @Published var currentSurface: MotionDetectionService.SurfaceType = .unknown
    @Published var currentDistance: Double = 0.5
    @Published var currentSNR: Double = 0.0
    @Published var breathingStability: Double = 1.0
    @Published var currentTiltAngle: Double = 0.0
    @Published var currentMotionG: Double = 0.0
    
    // Countdown State
    @Published var isSetup: Bool = true
    @Published var isWaiting: Bool = false
    @Published var countdownRemaining: Int = 0
    @Published var selectedDelayMinutes: Int = 0
    
    // MARK: - Services
    private let audioCapture = AudioCaptureService.shared
    private let snoreDetector = SnoreDetectionService.shared
    private let apneaDetector = ApneaDetectionService.shared
    private let motionDetector = MotionDetectionService.shared
    private let sessionStorage = SessionStorageService.shared
    private let audioFileService = AudioFileService.shared
    private let healthKitService = HealthKitService()
    
    // MARK: - Session State
    private var sessionID: UUID?
    private var sessionStart: Date?
    private var timerTask: Task<Void, Never>?

    // Event accumulators
    private var currentSnoreEvents: [SnoreEvent] = []
    private var currentApneaEvents: [ApneaEvent] = []
    
    // Visualization & Timeline
    private var waveformBuffer: [Float] = Array(repeating: 0, count: 60)
    private var decibelTimeline: [Float] = []
    private var lastTimelineSampleTime = Date()
    private var lastAutoSaveTime = Date()
    private var lastSpectralAnalysis: (nasal: Double, palatal: Double, lingual: Double) = (0, 0, 0)
    
    // Sentinel V2 Timelines
    private var snrTimeline: [Double] = []
    private var stabilityTimeline: [Double] = []
    private var tiltTimeline: [Double] = []
    private var motionTimeline: [Double] = []
    private var sampleAccumulator: [Float] = []
    
    // Stability Averages
    private var stabilitySum: Double = 0.0
    private var stabilityCount: Int = 0

    // Spectral Averages (Digital Twin)
    private var nasalSum: Double = 0.0
    private var palatalSum: Double = 0.0
    private var lingualSum: Double = 0.0
    private var spectralCount: Int = 0

    init() {
        setupInterruptionObservers()
        setupBatteryMonitoring()
    }
    
    private func setupBatteryMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        updateChargingState()
        
        NotificationCenter.default.addObserver(forName: UIDevice.batteryStateDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.updateChargingState()
        }
    }
    
    private func updateChargingState() {
        let state = UIDevice.current.batteryState
        isCharging = (state == .charging || state == .full)
    }
    
    // MARK: - Interruption Handling
    
    private func setupInterruptionObservers() {
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] notification in
            self?.handleInterruption(notification: notification)
        }
    }
    
    private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        
        if type == .began {
            // System stops engine automatically on interruption began
            print("🎙️ Interrupción de audio iniciada (Llamada/Alarma)")
        } else if type == .ended {
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) && isRecording {
                print("🎙️ Reanudando grabación tras interrupción")
                try? audioCapture.start()
            }
        }
    }

    // MARK: - Start/Stop Session

    private var audioFile: AVAudioFile?
    private var countdownTask: Task<Void, Never>?

    func startWithDelay(minutes: Int) {
        isSetup = false
        let id = UUID()
        let now = Date()
        sessionID = id
        sessionStart = now
        
        // Disable screen dimming
        UIApplication.shared.isIdleTimerDisabled = true
        
        selectedDelayMinutes = minutes
        
        // CRITICAL: Start the audio engine IMMEDIATELY to prevent iOS from killing the process
        // during the cooldown period.
        Task {
            await startSession(isWaitingPhase: minutes > 0)
        }

        if minutes > 0 {
            isWaiting = true
            countdownRemaining = minutes * 60
            startCountdownTask()
        }
    }

    private func startCountdownTask() {
        countdownTask?.cancel()
        countdownTask = Task {
            while countdownRemaining > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run {
                    self.countdownRemaining -= 1
                }
                if Task.isCancelled { return }
            }
            await MainActor.run {
                self.isWaiting = false
            }
            await startSession()
        }
    }

    func startSession(isWaitingPhase: Bool = false) async {
        isSetup = false
        if !isWaitingPhase {
            isWaiting = false
        }
        
        // If already recording (from cooldown), just ensure state is right
        if isRecording && !isWaitingPhase { return }
        
        let now = Date()

        // ... (reset state)
        if !isWaitingPhase {
            currentSnoreEvents = []
            currentApneaEvents = []
            decibelTimeline = []
            sampleAccumulator = []
            lastTimelineSampleTime = now
            lastAutoSaveTime = now
            peakDecibels = -100
            elapsedSeconds = 0
            snoreEventCount = 0
            apneaEventCount = 0
            isApneaActive = false
            nasalSum = 0
            palatalSum = 0
            lingualSum = 0
            spectralCount = 0
            snrTimeline = []
            stabilityTimeline = []
            tiltTimeline = []
            motionTimeline = []
        }

        do {
            try AudioSessionManager.shared.configure()
            try audioFileService.ensureDirectoryExists()
            
            // Start engine FIRST so we know the output format
            try audioCapture.start()
            
            if !isWaitingPhase {
                try snoreDetector.setup(format: audioCapture.outputFormat)
                motionDetector.start()
                
                // Create AVAudioFile with AAC settings
                let audioURL = audioFileService.audioURL(for: sessionID ?? UUID())
                audioFile = try AVAudioFile(
                    forWriting: audioURL,
                    settings: audioFileService.recorderSettings,
                    commonFormat: .pcmFormatFloat32,
                    interleaved: false
                )
                
                snoreDetector.startSession(at: now)
                apneaDetector.startSession(at: now)
                isRecording = true
                startTimer()
            }
            
            wireCallbacks()
            
            audioCapture.onBuffer = { [weak self] buffer, time in
                self?.processBuffer(buffer, time: time)
            }
            
        } catch {
            print("[Somnera] Failed to start session: \(error)")
        }
    }

    func stopSession() async {
        let wasRecording = isRecording
        countdownTask?.cancel()
        
        // Re-enable screen dimming
        UIApplication.shared.isIdleTimerDisabled = false
        
        isRecording = false
        isWaiting = false
        isSetup = true
        timerTask?.cancel()

        // Stop services
        audioCapture.stop()
        
        // Final sample
        if wasRecording && !sampleAccumulator.isEmpty {
            let avgDB = sampleAccumulator.reduce(0, +) / Float(max(1, sampleAccumulator.count))
            decibelTimeline.append(avgDB)
            
            // Final Sentinel V2 samples
            snrTimeline.append(currentSNR)
            stabilityTimeline.append(breathingStability)
            tiltTimeline.append(currentTiltAngle)
            motionTimeline.append(currentMotionG)
        }
        
        snoreDetector.teardown()
        snoreDetector.stopSession()
        apneaDetector.stopSession()
        motionDetector.stop()
        audioFile = nil // This closes the file properly
        AudioSessionManager.shared.deactivate()

        // ONLY SAVE IF WE ACTUALLY STARTED RECORDING
        if wasRecording {
            saveCurrentSessionState(isFinal: true)

            // Final Sync to HealthKit
            let avgStability = stabilityCount > 0 ? (stabilitySum / Double(stabilityCount)) : 1.0
            if healthKitService.isAvailable, let start = sessionStart {
                try? await healthKitService.saveSleepSession(
                    start: start,
                    end: Date(),
                    apneaEventCount: currentApneaEvents.count,
                    avgStability: avgStability
                )
            }
            
            if let session = self.session {
                sessionStorage.save(session)
            }
        } else {
            print("[Somnera] 🗑️ Sesión descartada (cancelada durante el retardo/setup)")
            session = nil
        }
    }

    // MARK: - Processing

    // Advanced Telemetry State
    private var noiseFloorRMS: Float = 0.001
    private var lastPeakTime: Date = Date()
    private var peakIntervals: [TimeInterval] = []

    private func processBuffer(_ buffer: AVAudioPCMBuffer, time: AVAudioTime) {
        // 1. Metrics
        let rms = DSPFilter.rms(of: buffer) ?? 0.0001
        let dB = DSPFilter.toDecibels(rms)
        
        // --- SNR CALCULATION ---
        // Slowly track the lowest RMS to find the noise floor
        noiseFloorRMS = (rms < noiseFloorRMS) ? (rms * 0.05 + noiseFloorRMS * 0.95) : (noiseFloorRMS * 0.999 + rms * 0.001)
        let snr = 20 * log10(max(1.1, rms / max(0.0001, noiseFloorRMS)))
        
        // --- STABILITY (RHYTHM) CALCULATION ---
        // Basic peak detection for breathing rhythm
        if rms > noiseFloorRMS * 1.5 && rms > 0.001 {
            let now = Date()
            let interval = now.timeIntervalSince(lastPeakTime)
            if interval > 1.0 && interval < 6.0 { // Range for human breathing (10-60 bpm)
                peakIntervals.append(interval)
                if peakIntervals.count > 10 { peakIntervals.removeFirst() }
                
                // Stability = 1.0 - (StdDev / Mean)
                if peakIntervals.count >= 3 {
                    let mean = peakIntervals.reduce(0, +) / Double(peakIntervals.count)
                    let variance = peakIntervals.map { pow($0 - mean, 2) }.reduce(0, +) / Double(peakIntervals.count)
                    let stdDev = sqrt(variance)
                    let stability = max(0.0, min(1.0, 1.0 - (stdDev / mean)))
                    
                    Task { @MainActor in
                        self.breathingStability = stability
                        self.stabilitySum += stability
                        self.stabilityCount += 1
                    }
                }
                lastPeakTime = now
            }
        }

        // Visual updates even during waiting
        Task { @MainActor in
            self.currentRMS = rms
            self.currentDecibels = dB
            self.currentSNR = Double(snr)
            self.updateWaveform(rms: rms)
        }

        // IF WAITING: We just return here but the engine keeps running!
        // This is the trick to keep the app alive in background.
        guard isRecording && !isWaiting else { return }

        let motion = motionDetector.lastIntensity
        apneaDetector.update(rms: rms, motionIntensity: motion, at: Date())
        
        // 2. Save amplified copy
        self.writeAmplifiedBuffer(buffer)
        
        // 3. IA Analysis
        let now = Date()
        snoreDetector.analyze(buffer, at: time)
        
        // Link snore events to apnea detector
        if snoreDetector.isSnoring {
            apneaDetector.reportSnore(at: now)
        }
        
        // 4. Digital Twin Spectral Analysis
        // We analyze any buffer that isn't complete silence (> 30dB)
        if dB > 30 {
            let spectral = SpectralAnalysisService.shared.analyze(buffer: buffer)
            self.lastSpectralAnalysis = (spectral.nasal, spectral.palatal, spectral.lingual)
            
            if (spectral.nasal + spectral.palatal + spectral.lingual) > 0 {
                Task { @MainActor in
                    self.nasalSum += spectral.nasal
                    self.palatalSum += spectral.palatal
                    self.lingualSum += spectral.lingual
                    self.spectralCount += 1
                }
            }
        }

        // Timeline Sampling (5s)
        sampleAccumulator.append(dB)
        if now.timeIntervalSince(lastTimelineSampleTime) >= 5.0 {
            let avgDB = sampleAccumulator.reduce(0, +) / Float(max(1, sampleAccumulator.count))
            decibelTimeline.append(avgDB)
            
            // Collect Sentinel V2 Telemetry
            snrTimeline.append(currentSNR)
            stabilityTimeline.append(breathingStability)
            tiltTimeline.append(currentTiltAngle)
            motionTimeline.append(currentMotionG)
            
            sampleAccumulator = []
            lastTimelineSampleTime = now
            
            // Auto-save metadata every 5 minutes
            if now.timeIntervalSince(lastAutoSaveTime) >= 300 {
                saveCurrentSessionState(isFinal: false)
                lastAutoSaveTime = now
            }
        }

        Task { @MainActor in
            self.currentRMS = rms
            self.currentDecibels = dB
            self.peakDecibels = max(self.peakDecibels, dB)
            self.updateWaveform(rms: rms)
        }
    }

    private func saveCurrentSessionState(isFinal: Bool) {
        guard let id = sessionID, let start = sessionStart else { return }
        print("[Somnera] 💾 Guardando sesión: \(id.uuidString)")
        print("[Somnera] 📈 Puntos del Heatmap: \(decibelTimeline.count)")
        
        let session = SleepSession(
            id: id,
            startDate: start,
            endDate: Date(),
            snoreEvents: currentSnoreEvents,
            apneaEvents: currentApneaEvents,
            audioFilePath: id.uuidString,
            peakDecibels: peakDecibels,
            decibelTimeline: decibelTimeline,
            surfaceType: currentSurface.rawValue,
            nasalIntensity: spectralCount > 0 ? (nasalSum / Double(spectralCount)) : 0.0,
            palatalIntensity: spectralCount > 0 ? (palatalSum / Double(spectralCount)) : 0.0,
            lingualIntensity: spectralCount > 0 ? (lingualSum / Double(spectralCount)) : 0.0,
            snrTimeline: snrTimeline,
            stabilityTimeline: stabilityTimeline,
            tiltTimeline: tiltTimeline,
            motionTimeline: motionTimeline
        )
        sessionStorage.save(session)
        self.session = session
    }

    private func updateWaveform(rms: Float) {
        waveformBuffer.removeFirst()
        waveformBuffer.append(min(1.0, rms * 8))
        latestWaveform = waveformBuffer
    }

    /// Writes an amplified copy of the buffer to the audio file.
    /// The original buffer is NOT modified — IA analysis is unaffected.
    private func writeAmplifiedBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let audioFile = audioFile,
              let channelData = buffer.floatChannelData else { return }
        
        let frameCount = Int(buffer.frameLength)
        let gain: Float = 15.0 // Boost factor for human listening
        
        // Create an amplified copy
        guard let amplified = AVAudioPCMBuffer(
            pcmFormat: buffer.format,
            frameCapacity: buffer.frameLength
        ) else { return }
        amplified.frameLength = buffer.frameLength
        
        guard let ampData = amplified.floatChannelData else { return }
        
        for i in 0..<frameCount {
            let sample = channelData[0][i] * gain
            ampData[0][i] = max(-1.0, min(1.0, sample)) // Clamp to avoid distortion
        }
        
        try? audioFile.write(from: amplified)
    }

    private func wireCallbacks() {
        motionDetector.onMotionUpdate = { [weak self] intensity, tilt, rawG in
            Task { @MainActor in
                self?.currentMotionIntensity = intensity
                self?.currentTiltAngle = tilt
                self?.currentMotionG = rawG
            }
        }
        
        motionDetector.onSurfaceDetected = { [weak self] surface in
            Task { @MainActor in
                self?.currentSurface = surface
            }
        }
        
        snoreDetector.onDistanceEstimated = { [weak self] distance in
            Task { @MainActor in
                self?.currentDistance = distance
            }
        }
        
        snoreDetector.onSnoreDetected = { [weak self] confidence, offset, distance in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let event = SnoreEvent(
                    offsetSeconds: offset,
                    durationSeconds: SomneraConstants.Snore.windowDurationSeconds,
                    confidence: confidence,
                    peakDecibels: self.peakDecibels,
                    nasalIntensity: self.lastSpectralAnalysis.nasal,
                    palatalIntensity: self.lastSpectralAnalysis.palatal,
                    lingualIntensity: self.lastSpectralAnalysis.lingual
                )
                self.currentSnoreEvents.append(event)
                self.snoreEventCount = self.currentSnoreEvents.count
            }
        }

        apneaDetector.onApneaDetected = { [weak self] duration, offset in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let event = ApneaEvent(offsetSeconds: offset, durationSeconds: duration)
                self.currentApneaEvents.append(event)
                self.apneaEventCount = self.currentApneaEvents.count
                self.isApneaActive = true
            }
        }

        apneaDetector.onApneaResolved = { [weak self] duration, confidence in
            Task { @MainActor [weak self] in
                guard let self else { return }
                
                // Update the last event (the one created in onApneaDetected)
                if var lastEvent = self.currentApneaEvents.last {
                    self.currentApneaEvents.removeLast()
                    lastEvent.durationSeconds = duration
                    lastEvent.confidence = confidence
                    
                    // Only keep it if it satisfies Sentinel V2 clinical criteria
                    if confidence >= 0.4 {
                        self.currentApneaEvents.append(lastEvent)
                        
                        // Sync specific event to HealthKit as an interruption (asleep -> awake)
                        try? await self.healthKitService.saveApneaEvent(at: Date(), duration: duration)
                    }
                }
                
                self.apneaEventCount = self.currentApneaEvents.count
                self.isApneaActive = false
            }
        }
    }

    private func startTimer() {
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run { self.elapsedSeconds += 1 }
            }
        }
    }

    var formattedElapsed: String {
        let h = elapsedSeconds / 3600
        let m = (elapsedSeconds % 3600) / 60
        let s = elapsedSeconds % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%02d:%02d", m, s)
    }
}
