import Foundation
import AudioToolbox

/// Gestor de sonidos de ultra-alta velocidad usando AudioServices
class ConsciousnessSoundManager {
    static let shared = ConsciousnessSoundManager()
    
    private var soundID: SystemSoundID = 0
    
    private init() {
        loadSound()
    }
    
    private func loadSound() {
        guard let url = Bundle.main.url(forResource: "sparkle6", withExtension: "mp3") else { return }
        
        // Creamos el SystemSoundID. Este método es el más rápido para feedback corto.
        AudioServicesCreateSystemSoundID(url as CFURL, &soundID)
    }
    
    func playSparkle(pan: Float = 0) {
        guard soundID != 0 else { return }
        
        // AudioServicesPlaySystemSound es una función de fuego-y-olvido (fire-and-forget)
        // No tiene latencia de inicialización y corre fuera del hilo principal.
        AudioServicesPlaySystemSound(soundID)
    }
    
    deinit {
        if soundID != 0 {
            AudioServicesDisposeSystemSoundID(soundID)
        }
    }
}
