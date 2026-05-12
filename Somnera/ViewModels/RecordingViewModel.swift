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
    private var sampleAccumulator: [Float] = []

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

    func startSession() async {
        guard !isRecording else { return }

        let id = UUID()
        let now = Date()
        sessionID = id
        sessionStart = now

        // ... (reset state)
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

        do {
            try AudioSessionManager.shared.configure()
            try audioFileService.ensureDirectoryExists()
            
            // Start engine FIRST so we know the output format
            try audioCapture.start()
            try snoreDetector.setup(format: audioCapture.outputFormat)
            motionDetector.start()
            
            // Create AVAudioFile using the SAME PCM format the engine delivers
            let audioURL = audioFileService.audioURL(for: id)
            audioFile = try AVAudioFile(
                forWriting: audioURL,
                settings: audioCapture.outputFormat.settings
            )
            print("[Somnera] 🎙️ Recording to: \(audioURL.lastPathComponent) | Format: \(audioCapture.outputFormat)")
            
            wireCallbacks()
            
            audioCapture.onBuffer = { [weak self] buffer, time in
                self?.processBuffer(buffer, time: time)
                // Write PCM buffer directly — formats now match
                try? self?.audioFile?.write(from: buffer)
            }
            
            startTimer()
            isRecording = true
            
            snoreDetector.startSession(at: now)
            apneaDetector.startSession(at: now)
            
        } catch {
            print("[Somnera] Failed to start session: \(error)")
        }
    }

    func stopSession() async {
        guard isRecording, let id = sessionID, let start = sessionStart else { return }

        isRecording = false
        timerTask?.cancel()

        // Stop services
        audioCapture.stop()
        
        // Final sample
        if !sampleAccumulator.isEmpty {
            let avgDB = sampleAccumulator.reduce(0, +) / Float(sampleAccumulator.count)
            decibelTimeline.append(avgDB)
        }
        
        snoreDetector.teardown()
        snoreDetector.stopSession()
        apneaDetector.stopSession()
        motionDetector.stop()
        audioFile = nil // This closes the file properly
        AudioSessionManager.shared.deactivate()

        // Final Save
        saveCurrentSessionState(isFinal: true)

        // Sync to HealthKit
        if healthKitService.isAvailable {
            try? await healthKitService.saveSleepSession(
                start: start,
                end: Date(),
                apneaEventCount: currentApneaEvents.count
            )
        }
    }

    // MARK: - Processing

    private func processBuffer(_ buffer: AVAudioPCMBuffer, time: AVAudioTime) {
        let rms = DSPFilter.rms(of: buffer) ?? 0.0001
        let dB = DSPFilter.toDecibels(rms)
        let motion = motionDetector.lastIntensity
        
        apneaDetector.update(rms: rms, motionIntensity: motion, at: Date())
        snoreDetector.analyze(buffer, at: time)

        // Timeline Sampling (5s)
        sampleAccumulator.append(dB)
        let now = Date()
        if now.timeIntervalSince(lastTimelineSampleTime) >= 5.0 {
            let avgDB = sampleAccumulator.reduce(0, +) / Float(max(1, sampleAccumulator.count))
            decibelTimeline.append(avgDB)
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
        
        let session = SleepSession(
            id: id,
            startDate: start,
            endDate: Date(),
            snoreEvents: currentSnoreEvents,
            apneaEvents: currentApneaEvents,
            audioFilePath: audioFileService.audioURL(for: id).relativePath,
            peakDecibels: peakDecibels,
            decibelTimeline: decibelTimeline
        )
        sessionStorage.save(session)
    }

    private func updateWaveform(rms: Float) {
        waveformBuffer.removeFirst()
        waveformBuffer.append(min(1.0, rms * 8))
        latestWaveform = waveformBuffer
    }

    private func wireCallbacks() {
        motionDetector.onMotionUpdate = { [weak self] intensity in
            Task { @MainActor in
                self?.currentMotionIntensity = intensity
            }
        }
        
        snoreDetector.onSnoreDetected = { [weak self] confidence, offset in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let event = SnoreEvent(
                    offsetSeconds: offset,
                    durationSeconds: SomneraConstants.Snore.windowDurationSeconds,
                    confidence: confidence,
                    peakDecibels: self.peakDecibels
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
                guard let self = self else { return }
                self.isApneaActive = false
                
                // Update the last event with final duration and confidence
                if var lastEvent = self.currentApneaEvents.last {
                    self.currentApneaEvents.removeLast()
                    lastEvent.durationSeconds = duration
                    lastEvent.confidence = confidence
                    
                    // Only keep it if it's a valid event (Sentinel V2 Filter)
                    if confidence >= 0.4 {
                        self.currentApneaEvents.append(lastEvent)
                    }
                    
                    self.apneaEventCount = self.currentApneaEvents.count
                }
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
