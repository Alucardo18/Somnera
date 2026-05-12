import SwiftUI

struct HighlightsView: View {
    let session: SleepSession
    @StateObject private var playback = AudioPlaybackService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Grabaciones Destacadas")
                .font(.system(size: 14, weight: .black))
                .foregroundColor(.white)
                .tracking(1)
            
            if session.highlights.isEmpty {
                Text("No se detectaron eventos significativos.")
                    .font(.caption)
                    .foregroundColor(.somTextSecondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(session.highlights) { event in
                            HighlightCard(event: event, audioURL: sessionAudioURL)
                        }
                    }
                }
            }
        }
        .padding(20)
        .somGlassStyle(cornerRadius: 24)
    }
    
    private var sessionAudioURL: URL? {
        guard let idString = session.audioFilePath, let id = UUID(uuidString: idString) else { return nil }
        return AudioFileService.shared.audioURL(for: id)
    }
}

struct HighlightCard: View {
    let event: SnoreEvent
    let audioURL: URL?
    @StateObject private var playback = AudioPlaybackService.shared
    
    private var isCurrentlyPlaying: Bool {
        playback.isPlaying && playback.currentOffset == event.offsetSeconds
    }
    
    var body: some View {
        Button {
            if let url = audioURL {
                // Empezamos 2 segundos antes para dar contexto (sin bajar de 0)
                let startOffset = max(0, event.offsetSeconds - 2.0)
                playback.playSegment(from: url, offset: startOffset, duration: 8.0)
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: isCurrentlyPlaying ? "stop.fill" : "play.fill")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Color.somAccent.gradient)
                        .clipShape(Circle())
                    
                    Spacer()
                    
                    Text("\(Int(event.peakDecibels)) dB")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.somApnea)
                }
                
                Text("Snore Clip")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Ronquido Fuerte")
                    .font(.system(size: 10))
                    .foregroundColor(.somTextSecondary)
            }
            .padding(12)
            .frame(width: 120, height: 100)
            .background(Color.somSurfaceHigh.opacity(0.4))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isCurrentlyPlaying ? Color.somAccent : Color.clear, lineWidth: 2)
            )
        }
    }
}
#Preview {
    ZStack {
        Color.somBackground.ignoresSafeArea()
        HighlightsView(session: .mock)
            .padding()
    }
}
