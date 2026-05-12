import SwiftUI

struct HighlightsView: View {
    let session: SleepSession
    let onFeedback: (SleepSession, SnoreEvent, SnoreEvent.Feedback) -> Void
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
                            HighlightCard(event: event, audioURL: sessionAudioURL) { feedback in
                                onFeedback(session, event, feedback)
                            }
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
    let onFeedback: (SnoreEvent.Feedback) -> Void
    @StateObject private var playback = AudioPlaybackService.shared
    
    private var isCurrentlyPlaying: Bool {
        playback.isPlaying && playback.playingEventID == event.id
    }
    
    var body: some View {
        Button {
            if isCurrentlyPlaying {
                playback.stop()
            } else if let url = audioURL {
                let startOffset = max(0, event.offsetSeconds - 2.0)
                playback.playSegment(from: url, offset: startOffset, duration: 8.0, eventID: event.id)
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
        .opacity(event.userFeedback == .rejected ? 0.3 : 1.0)
        .overlay(
            Group {
                if event.userFeedback == .rejected {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .padding(4)
                } else if event.userFeedback == .confirmed {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .padding(4)
                }
            },
            alignment: .topTrailing
        )
        .contextMenu {
            Button {
                onFeedback(.confirmed)
            } label: {
                Label("Confirmar Ronquido", systemImage: "checkmark.circle")
            }
            
            Button(role: .destructive) {
                onFeedback(.rejected)
            } label: {
                Label("No es un ronquido", systemImage: "xmark.circle")
            }
        }
    }
}
#Preview {
    ZStack {
        Color.somBackground.ignoresSafeArea()
        HighlightsView(session: .mock) { _, _, _ in }
            .padding()
    }
}
