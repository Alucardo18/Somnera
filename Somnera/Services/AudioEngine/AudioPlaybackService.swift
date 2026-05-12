import AVFoundation

/// Handles playback of specific segments from recorded sleep sessions.
final class AudioPlaybackService: NSObject, ObservableObject {
    static let shared = AudioPlaybackService()
    
    private var audioEngine = AVAudioEngine()
    private var playerNode = AVAudioPlayerNode()
    private var audioFile: AVAudioFile?
    
    @Published var isPlaying = false
    @Published var currentOffset: TimeInterval = 0
    
    private override init() {
        super.init()
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: nil)
    }
    
    func playSegment(from url: URL, offset: TimeInterval, duration: TimeInterval) {
        print("[Somnera] 🔊 Intentando reproducir highlight: \(url.lastPathComponent) @ \(offset)s")
        
        // Ensure audio goes to speakers and not the earpiece
        try? AudioSessionManager.shared.switchToPlayback()
        
        stop()
        
        do {
            let file = try AVAudioFile(forReading: url)
            self.audioFile = file
            
            let format = file.processingFormat
            let sampleRate = format.sampleRate
            
            let startFrame = AVAudioFramePosition(offset * sampleRate)
            let frameCount = AVAudioFrameCount(duration * sampleRate)
            
            // Ensure we don't go out of bounds
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
                    self?.isPlaying = false
                }
            }
            
            playerNode.play()
            isPlaying = true
            currentOffset = offset
            
        } catch {
            print("[Somnera] Playback error: \(error.localizedDescription)")
        }
    }
    
    func stop() {
        playerNode.stop()
        audioEngine.stop()
        isPlaying = false
    }
}
