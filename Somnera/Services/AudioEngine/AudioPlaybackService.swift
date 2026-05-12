import AVFoundation

/// Handles playback of specific segments from recorded sleep sessions.
final class AudioPlaybackService: NSObject, ObservableObject {
    static let shared = AudioPlaybackService()
    
    private var audioEngine = AVAudioEngine()
    private var playerNode = AVAudioPlayerNode()
    private var audioFile: AVAudioFile?
    
    @Published var isPlaying = false
    @Published var currentOffset: TimeInterval = 0
    @Published var playingEventID: UUID?
    
    private override init() {
        super.init()
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: nil)
    }
    
    func playSegment(from url: URL, offset: TimeInterval, duration: TimeInterval, eventID: UUID) {
        print("[Somnera] 🔊 Reproduciendo clip: \(eventID.uuidString)")
        
        try? AudioSessionManager.shared.switchToPlayback()
        
        stop()
        
        do {
            let file = try AVAudioFile(forReading: url)
            self.audioFile = file
            
            let format = file.processingFormat
            let sampleRate = format.sampleRate
            
            let startFrame = AVAudioFramePosition(offset * sampleRate)
            let frameCount = AVAudioFrameCount(duration * sampleRate)
            
            guard startFrame < file.length else { return }
            let safeFrameCount = min(frameCount, AVAudioFrameCount(file.length - startFrame))
            
            if !audioEngine.isRunning {
                try audioEngine.start()
            }
            
            playerNode.scheduleSegment(file, 
                                     startingFrame: startFrame, 
                                     frameCount: safeFrameCount, 
                                     at: nil) { [weak self] in
                DispatchQueue.main.async {
                    if self?.playingEventID == eventID {
                        self?.isPlaying = false
                        self?.playingEventID = nil
                    }
                }
            }
            
            playerNode.play()
            isPlaying = true
            currentOffset = offset
            playingEventID = eventID
            
        } catch {
            print("[Somnera] Playback error: \(error.localizedDescription)")
        }
    }
    
    func stop() {
        playerNode.stop()
        audioEngine.stop()
        isPlaying = false
        playingEventID = nil
    }
}
