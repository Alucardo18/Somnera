import Foundation
import AVFoundation
import Combine
import UIKit
import SwiftUI

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
    
    // Real-time Spectral Intensities
    @Published var currentNasalIntensity: Double = 0.0
    @Published var currentPalatalIntensity: Double = 0.0
    @Published var currentLingualIntensity: Double = 0.0
    
    // Countdown State
    @Published var isSetup: Bool = true
    @Published var isWaiting: Bool = false
    @Published var countdownRemaining: Int = 0
    @Published var selectedDelayMinutes: Int = 0
    
    // Sleep Shield (Screen Management)
    @Published var isDimmed: Bool = false
    @Published var isProximityCovered: Bool = false
    private var lastInteractionDate = Date()
    private var originalBrightness: CGFloat = UIScreen.main.brightness
    private var screenDimmerTask: Task<Void, Never>?
    
    // MARK: - Services
    private let audioCapture = AudioCaptureService.shared
    private let snoreDetector = SnoreDetectionService.shared
    private let apneaDetector = ApneaDetectionService.shared
    private let motionDetector = MotionDetectionService.shared
    private let sessionStorage = SessionStorageService.shared
    private let audioFileService = AudioFileService.shared
    private let healthKitService = HealthKitService.shared
    
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
    private var sessionPeakDecibels: Float = -100 // Process-thread safe peak tracking
    private var lastTimelineSampleTime = Date(timeIntervalSince1970: 0)
    private var lastAutoSaveTime = Date()
    private var lastUIUpdateTime = Date()
    private var lastValidSpectralTime = Date()
    
    // Internal thread-safe intensities for Digital Twin
    private var internalNasalIntensity: Double = 0.0
    private var internalPalatalIntensity: Double = 0.0
    private var internalLingualIntensity: Double = 0.0
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
    
    @AppStorage("somnera_sensitivity") private var userSensitivity: Double = 1.0
    
    // Thread-safe snapshots for the audio processing loop
    private var sessionConfidenceThreshold: Double = 0.70
    private var sessionDBThreshold: Float = 35.0
    private var sessionCrestThreshold: Float = 2.5
    private var sessionApneaThreshold: Float = 0.0006
    
    private var sensitivityMultiplier: Double {
        return 2.0 - userSensitivity
    }

    init() {
        setupInterruptionObservers()
        setupBatteryMonitoring()
        setupProximityMonitoring()
        resetInactivityTimer()
    }
    
    private func setupProximityMonitoring() {
        UIDevice.current.isProximityMonitoringEnabled = true
        
        NotificationCenter.default.addObserver(
            forName: UIDevice.proximityStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleProximityChange()
        }
    }
    
    private func handleProximityChange() {
        let isCovered = UIDevice.current.proximityState
        isProximityCovered = isCovered
        
        if isCovered {
            print("🛡️ Sleep Shield: Sensor cubierto (Pantalla física OFF)")
            // Trigger UI throttling immediately when screen is covered
            Task { @MainActor in
                self.enterDimmedState()
            }
        } else {
            print("🛡️ Sleep Shield: Sensor liberado")
            wakeUp()
        }
    }

    func resetInactivityTimer() {
        lastInteractionDate = Date()
        if isDimmed { wakeUp() }
        
        screenDimmerTask?.cancel()
        screenDimmerTask = Task {
            // Wait 2 minutes (120 seconds) of inactivity
            try? await Task.sleep(nanoseconds: 120_000_000_000)
            if !Task.isCancelled && (isRecording || isWaiting) {
                await MainActor.run { enterDimmedState() }
            }
        }
    }

    private func enterDimmedState() {
        guard !isDimmed else { return }
        print("🌙 Sleep Shield: Entrando en modo ahorro (2 min inactividad)")
        originalBrightness = UIScreen.main.brightness
        UIScreen.main.brightness = 0.01 // Minimum brightness
        isDimmed = true
    }

    func wakeUp() {
        guard isDimmed else { 
            lastInteractionDate = Date()
            return 
        }
        print("☀️ Sleep Shield: Despertando pantalla")
        UIScreen.main.brightness = originalBrightness
        isDimmed = false
        resetInactivityTimer()
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
        lastUpdatedRemainingSecond = -1
        
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
            // The countdown task is now a visual-only helper to tick when in foreground,
            // but is not responsible for the transition itself.
            startCountdownTask()
        }
    }

    private func startCountdownTask() {
        countdownTask?.cancel()
        countdownTask = Task {
            while countdownRemaining > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run {
                    if self.isWaiting && self.countdownRemaining > 0 {
                        self.countdownRemaining -= 1
                    }
                }
                if Task.isCancelled { return }
            }
        }
    }

    @MainActor
    private func transitionToActiveRecording(at now: Date) {
        guard isWaiting else { return }
        
        isWaiting = false
        countdownRemaining = 0
        countdownTask?.cancel()
        
        // Safely reset all session variables
        currentSnoreEvents = []
        currentApneaEvents = []
        decibelTimeline = []
        sampleAccumulator = []
        lastTimelineSampleTime = now
        lastAutoSaveTime = now
        peakDecibels = -100
        sessionPeakDecibels = -100
        elapsedSeconds = 0
        snoreEventCount = 0
        apneaEventCount = 0
        isApneaActive = false
        nasalSum = 0
        palatalSum = 0
        lingualSum = 0
        spectralCount = 0
        internalNasalIntensity = 0
        internalPalatalIntensity = 0
        internalLingualIntensity = 0
        currentNasalIntensity = 0
        currentPalatalIntensity = 0
        currentLingualIntensity = 0
        snrTimeline = []
        stabilityTimeline = []
        tiltTimeline = []
        motionTimeline = []
        
        let multiplier = self.sensitivityMultiplier
        sessionConfidenceThreshold = SomneraConstants.Snore.confidenceThreshold * multiplier
        sessionDBThreshold = Float(35.0 * multiplier)
        sessionCrestThreshold = Float(2.5 * multiplier)
        sessionApneaThreshold = SomneraConstants.Apnea.silenceRMSThreshold * Float(multiplier)
        
        print("[Somnera] 🎯 Transición Hardware - Umbrales de sesión: dB > \(Int(sessionDBThreshold)), Crest > \(String(format: "%.1f", sessionCrestThreshold))")
        
        do {
            try snoreDetector.setup(
                format: audioCapture.outputFormat,
                confidenceThreshold: sessionConfidenceThreshold
            )
            motionDetector.start()
            
            apneaDetector.silenceThreshold = sessionApneaThreshold
            
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
            
            // Update stored start date to reflect actual active recording start
            if let session = self.session {
                session.startDate = now
                sessionStorage.save(session)
            }
            
            print("[Somnera] 🎙️ Grabación física iniciada vía hardware con éxito.")
        } catch {
            print("[Somnera] ❌ Error en transición de hardware: \(error)")
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
            sessionPeakDecibels = -100
            elapsedSeconds = 0
            snoreEventCount = 0
            apneaEventCount = 0
            isApneaActive = false
            nasalSum = 0
            palatalSum = 0
            lingualSum = 0
            spectralCount = 0
            internalNasalIntensity = 0
            internalPalatalIntensity = 0
            internalLingualIntensity = 0
            currentNasalIntensity = 0
            currentPalatalIntensity = 0
            currentLingualIntensity = 0
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
                // Capture snapshots on MainActor before entering the audio thread
                let multiplier = self.sensitivityMultiplier
                sessionConfidenceThreshold = SomneraConstants.Snore.confidenceThreshold * multiplier
                sessionDBThreshold = Float(35.0 * multiplier)
                sessionCrestThreshold = Float(2.5 * multiplier)
                sessionApneaThreshold = SomneraConstants.Apnea.silenceRMSThreshold * Float(multiplier)
                
                print("[Somnera] 🎯 Umbrales de sesión: dB > \(Int(sessionDBThreshold)), Crest > \(String(format: "%.1f", sessionCrestThreshold)), IA > \(Int(sessionConfidenceThreshold*100))%")

                try snoreDetector.setup(
                    format: audioCapture.outputFormat,
                    confidenceThreshold: sessionConfidenceThreshold
                )
                motionDetector.start()
                
                apneaDetector.silenceThreshold = sessionApneaThreshold
                
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
            
            // Initialize SwiftData session early
            let newSession = SleepSession(
                id: sessionID ?? UUID(),
                startDate: now,
                audioFilePath: sessionID?.uuidString,
                surfaceType: currentSurface.rawValue
            )
            sessionStorage.save(newSession)
            self.session = newSession
            
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
        screenDimmerTask?.cancel()
        
        // Restore screen
        wakeUp()
        UIDevice.current.isProximityMonitoringEnabled = false

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
        } else {
            print("[Somnera] 🗑️ Sesión descartada (cancelada durante el retardo/setup)")
            if let sessionToDiscard = self.session {
                sessionStorage.delete(sessionToDiscard)
            }
            session = nil
        }
    }

    // MARK: - Processing

    // Advanced Telemetry State
    private var noiseFloorRMS: Float = 0.001
    private var lastPeakTime: Date = Date()
    private var peakIntervals: [TimeInterval] = []
    private var lastUpdatedRemainingSecond: Int = -1

    private func processBuffer(_ buffer: AVAudioPCMBuffer, time: AVAudioTime) {
        autoreleasepool {
            let now = Date()
            
            // 1. Math & DSP (Background Thread Safe)
            let rms = DSPFilter.rms(of: buffer) ?? 0.0001
            let dB = (20 * log10(max(1e-5, rms))) + 80 // Normalized to 0-80 dB range
            let spectral = SpectralAnalysisService.shared.analyze(buffer: buffer)
            
            let frameCount = Int(buffer.frameLength)
            var peak: Float = 0
            if let ptr = buffer.floatChannelData?[0] {
                let samples = UnsafeBufferPointer(start: ptr, count: frameCount)
                for s in samples { peak = max(peak, abs(s)) }
            }
            let crest = rms > 0 ? peak / rms : 0
            
            // 2. Write Amplified Copy (Background Thread Safe, avoids UI lag)
            self.writeAmplifiedBuffer(buffer)
            
            // 3. IA Snore Analysis (Background Thread Safe)
            snoreDetector.analyze(buffer, at: time)
            
            // 4. Safely dispatch all mutations and logic to MainActor
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.processBufferOnMainActor(rms: rms, dB: dB, spectral: (spectral.nasal, spectral.palatal, spectral.lingual), crest: crest, now: now, time: time)
            }
        }
    }

    @MainActor
    private func processBufferOnMainActor(rms: Float, dB: Float, spectral: (nasal: Double, palatal: Double, lingual: Double), crest: Float, now: Date, time: AVAudioTime) {
        // Track peak on MainActor
        sessionPeakDecibels = max(sessionPeakDecibels, dB)
        
        // --- SNR CALCULATION ---
        noiseFloorRMS = (rms < noiseFloorRMS) ? (rms * 0.05 + noiseFloorRMS * 0.95) : (noiseFloorRMS * 0.999 + rms * 0.001)
        let snr = 20 * log10(max(1.1, rms / max(0.0001, noiseFloorRMS)))
        
        // --- STABILITY (RHYTHM) CALCULATION ---
        if rms > noiseFloorRMS * 1.5 && rms > 0.001 {
            let interval = now.timeIntervalSince(lastPeakTime)
            if interval > 1.0 && interval < 6.0 {
                peakIntervals.append(interval)
                if peakIntervals.count > 10 { peakIntervals.removeFirst() }
                
                if peakIntervals.count >= 3 {
                    let mean = peakIntervals.reduce(0, +) / Double(peakIntervals.count)
                    let variance = peakIntervals.map { pow($0 - mean, 2) }.reduce(0, +) / Double(peakIntervals.count)
                    let stdDev = sqrt(variance)
                    let stability = max(0.0, min(1.0, 1.0 - (stdDev / mean)))
                    
                    self.breathingStability = stability
                    self.stabilitySum += stability
                    self.stabilityCount += 1
                }
                lastPeakTime = now
            }
        }

        let shouldUpdateUI = now.timeIntervalSince(lastUIUpdateTime) >= 0.05
        self.lastSpectralAnalysis = (spectral.nasal, spectral.palatal, spectral.lingual)
        
        if dB > sessionDBThreshold && crest > sessionCrestThreshold {
            internalNasalIntensity = (internalNasalIntensity * 0.7) + (spectral.nasal * 0.3)
            internalPalatalIntensity = (internalPalatalIntensity * 0.7) + (spectral.palatal * 0.3)
            internalLingualIntensity = (internalLingualIntensity * 0.7) + (spectral.lingual * 0.3)
            lastValidSpectralTime = now
        } else if now.timeIntervalSince(lastValidSpectralTime) > 1.5 {
            internalNasalIntensity *= 0.9
            internalPalatalIntensity *= 0.9
            internalLingualIntensity *= 0.9
        }
        
        if shouldUpdateUI {
            if !self.isDimmed {
                self.currentRMS = rms
                self.currentDecibels = dB
                self.currentSNR = Double(snr)
                self.peakDecibels = self.sessionPeakDecibels
                self.updateWaveform(rms: rms)
                
                self.currentNasalIntensity = self.internalNasalIntensity
                self.currentPalatalIntensity = self.internalPalatalIntensity
                self.currentLingualIntensity = self.internalLingualIntensity
            }
            lastUIUpdateTime = now
        }
        
        if snoreDetector.isSnoring && dB > sessionDBThreshold && crest > sessionCrestThreshold {
            nasalSum += spectral.nasal
            palatalSum += spectral.palatal
            lingualSum += spectral.lingual
            spectralCount += 1
        }

        // --- 1. PROCESAMIENTO DEL RETARDADOR DE ESPERA (HARDWARE-DRIVEN) ---
        if isWaiting {
            if let start = sessionStart {
                let elapsed = now.timeIntervalSince(start)
                let targetSeconds = Double(selectedDelayMinutes * 60)
                
                if elapsed >= targetSeconds {
                    self.transitionToActiveRecording(at: now)
                } else {
                    let remaining = max(0, Int(targetSeconds - elapsed))
                    if remaining != self.lastUpdatedRemainingSecond {
                        self.lastUpdatedRemainingSecond = remaining
                        self.countdownRemaining = remaining
                    }
                }
            }
            return
        }

        guard isRecording else { return }

        let motion = motionDetector.lastIntensity
        apneaDetector.update(rms: rms, motionIntensity: motion, at: Date())
            
        if snoreDetector.isSnoring {
            apneaDetector.reportSnore(at: now)
        }

        // Timeline Sampling (1s resolution for smoother hypnogram)
        sampleAccumulator.append(dB)
        if now.timeIntervalSince(lastTimelineSampleTime) >= 1.0 {
            let peakInWindow = sampleAccumulator.max() ?? dB
            decibelTimeline.append(peakInWindow)
            
            snrTimeline.append(currentSNR)
            stabilityTimeline.append(breathingStability)
            tiltTimeline.append(currentTiltAngle)
            motionTimeline.append(currentMotionG)
            
            sampleAccumulator = []
            lastTimelineSampleTime = now
            
            if now.timeIntervalSince(lastAutoSaveTime) >= 300 {
                saveCurrentSessionState(isFinal: false)
                lastAutoSaveTime = now
            }
        }
    }

    private func saveCurrentSessionState(isFinal: Bool) {
        guard let session = self.session else { return }
        print("[Somnera] 💾 Actualizando sesión: \(session.id.uuidString)")
        
        session.endDate = Date()
        session.peakDecibels = sessionPeakDecibels
        session.decibelTimeline = decibelTimeline
        print("[Somnera] 📈 Guardando Hipnograma: \(decibelTimeline.count) muestras.")
        session.surfaceType = currentSurface.rawValue
        
        // Anatomical Average: Based on validated SnoreEvents for maximum clinical accuracy.
        // This avoids background noise contamination in the final report.
        let eventsWithIntensity = currentSnoreEvents.filter { ($0.nasalIntensity + $0.palatalIntensity + $0.lingualIntensity) > 0 }
        
        if !eventsWithIntensity.isEmpty {
            let count = Double(eventsWithIntensity.count)
            session.nasalIntensity = eventsWithIntensity.map { $0.nasalIntensity }.reduce(0, +) / count
            session.palatalIntensity = eventsWithIntensity.map { $0.palatalIntensity }.reduce(0, +) / count
            session.lingualIntensity = eventsWithIntensity.map { $0.lingualIntensity }.reduce(0, +) / count
        } else {
            // Fallback to the accumulated sums if no snore events were captured (unlikely with IA gating)
            session.nasalIntensity = spectralCount > 0 ? (nasalSum / Double(spectralCount)) : 0.0
            session.palatalIntensity = spectralCount > 0 ? (palatalSum / Double(spectralCount)) : 0.0
            session.lingualIntensity = spectralCount > 0 ? (lingualSum / Double(spectralCount)) : 0.0
        }
        
        let nasalVal = session.nasalIntensity.isFinite ? Int(session.nasalIntensity * 100) : 0
        let palatalVal = session.palatalIntensity.isFinite ? Int(session.palatalIntensity * 100) : 0
        let lingualVal = session.lingualIntensity.isFinite ? Int(session.lingualIntensity * 100) : 0
        
        print("[Somnera] 📊 Persistiendo reporte anatómico - Nasal: \(nasalVal)%, Palatal: \(palatalVal)%, Lingual: \(lingualVal)% (Eventos: \(eventsWithIntensity.count))")
        
        session.snrTimeline = snrTimeline
        session.stabilityTimeline = stabilityTimeline
        session.tiltTimeline = tiltTimeline
        session.motionTimeline = motionTimeline
        
        sessionStorage.save(session)
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
            guard let self = self else { return }
            
            // CRITICAL: Capture intensities IMMEDIATELY on the processing thread.
            // If we wait for the @MainActor Task to run, the values might have already decayed.
            let capturedNasal = self.internalNasalIntensity
            let capturedPalatal = self.internalPalatalIntensity
            let capturedLingual = self.internalLingualIntensity
            
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let event = SnoreEvent(
                    offsetSeconds: offset,
                    durationSeconds: SomneraConstants.Snore.windowDurationSeconds,
                    confidence: confidence,
                    peakDecibels: self.peakDecibels,
                    nasalIntensity: capturedNasal,
                    palatalIntensity: capturedPalatal,
                    lingualIntensity: capturedLingual
                )
                if let session = self.session, let context = self.sessionStorage.context {
                    event.session = session
                    context.insert(event)
                }
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
                if let lastEvent = self.currentApneaEvents.last {
                    lastEvent.durationSeconds = duration
                    lastEvent.confidence = confidence
                    
                    // Only keep it if it satisfies Sentinel V2 clinical criteria
                    if confidence >= 0.4 {
                        // Sync specific event to HealthKit as an interruption (asleep -> awake)
                        try? await self.healthKitService.saveApneaEvent(at: Date(), duration: duration)
                        
                        if let session = self.session, let context = self.sessionStorage.context {
                            lastEvent.session = session
                            context.insert(lastEvent)
                        }
                    } else {
                        self.currentApneaEvents.removeLast()
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
