import Foundation
import AVFoundation

/// Handles writing and reading audio session files (.m4a) from the Documents directory.
final class AudioFileService {
    static let shared = AudioFileService()

    // MARK: - Paths

    private var sessionsDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(SomneraConstants.Storage.sessionsFolderName)
    }

    func ensureDirectoryExists() throws {
        try FileManager.default.createDirectory(
            at: sessionsDirectory,
            withIntermediateDirectories: true
        )
    }

    func audioURL(for sessionID: UUID) -> URL {
        sessionsDirectory
            .appendingPathComponent(sessionID.uuidString)
            .appendingPathExtension(SomneraConstants.Storage.audioExtension)
    }

    // MARK: - Recorder Settings

    var recorderSettings: [String: Any] {
        [
            AVFormatIDKey:              Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey:            SomneraConstants.Audio.sampleRate,
            AVNumberOfChannelsKey:      SomneraConstants.Audio.channels,
            AVEncoderAudioQualityKey:   AVAudioQuality.medium.rawValue,
            AVEncoderBitRateKey:        SomneraConstants.Audio.encoderBitRate
        ]
    }

    // MARK: - Delete

    func deleteAudio(for sessionID: UUID) {
        let url = audioURL(for: sessionID)
        try? FileManager.default.removeItem(at: url)
    }

    func deleteAudio(at path: String) {
        try? FileManager.default.removeItem(atPath: path)
    }

    func clearAllAudio() {
        try? FileManager.default.removeItem(at: sessionsDirectory)
        try? ensureDirectoryExists()
    }

    // MARK: - Info

    func fileSizeMB(for sessionID: UUID) -> Double {
        let url = audioURL(for: sessionID)
        let bytes = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0
        return Double(bytes) / 1_048_576
    }
}
