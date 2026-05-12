import AVFoundation
import Combine

/// Configures and manages AVAudioSession for overnight background recording.
final class AudioSessionManager {
    static let shared = AudioSessionManager()
    private init() {}

    private var interruptionCancellable: AnyCancellable?

    // MARK: - Setup

    func configure() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(
            .playAndRecord,
            mode: .measurement,
            options: [.mixWithOthers, .allowBluetoothA2DP, .defaultToSpeaker]
        )
        try session.setPreferredSampleRate(SomneraConstants.Audio.sampleRate)
        try session.setPreferredIOBufferDuration(SomneraConstants.Audio.ioBufferDuration)
        try session.setActive(true)

        observeInterruptions()
    }

    /// Switches the session to playback mode for listening to recordings.
    func switchToPlayback() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [])
        try session.overrideOutputAudioPort(.speaker) // Forza la salida por el altavoz principal
        try session.setActive(true)
    }

    func deactivate() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        interruptionCancellable?.cancel()
    }

    // MARK: - Interruption Handling

    private func observeInterruptions() {
        interruptionCancellable = NotificationCenter.default
            .publisher(for: AVAudioSession.interruptionNotification)
            .sink { [weak self] notification in
                self?.handleInterruption(notification)
            }
    }

    private func handleInterruption(_ notification: Notification) {
        guard
            let info = notification.userInfo,
            let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }

        switch type {
        case .began:
            NotificationCenter.default.post(name: .somneraPauseRecording, object: nil)

        case .ended:
            let optionValue = info[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: optionValue)
            if options.contains(.shouldResume) {
                try? AVAudioSession.sharedInstance().setActive(true)
                NotificationCenter.default.post(name: .somneraResumeRecording, object: nil)
            }

        @unknown default:
            break
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let somneraPauseRecording  = Notification.Name("com.somnera.pauseRecording")
    static let somneraResumeRecording = Notification.Name("com.somnera.resumeRecording")
}
