import SwiftUI

/// A medical-grade horizontal timeline (Hypnogram style) that shows snore waves and apnea blocks.
struct PSGTimelineView: View {
    let session: SleepSession
    @Binding var currentTime: TimeInterval
    let onSeek: (TimeInterval) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("HIPNOGRAMA DE RESPIRACIÓN")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.somTextSecondary)
                    .tracking(1)
                Spacer()
                Text(formatTime(currentTime))
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.somAccent)
            }
            .padding(.horizontal, 4)

            // Timeline Canvas
            ZStack(alignment: .leading) {
                // Background Grid
                medicalGrid
                
                // Snore Wave Layer (Blue)
                snoreWaveLayer
                
                // Apnea Blocks Layer (Red)
                apneaBlocksLayer
                
                // Scrubber / Medical Cursor
                medicalCursor
                
                // Debug Data Info (Temporary for diagnosis)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("SAMPLES: \(session.decibelTimeline.count)")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.4))
                            .padding(4)
                    }
                }
            }
            .frame(height: 120)
            .background(Color.black.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.somAccent.opacity(0.3), lineWidth: 2) // High visibility border
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let percentage = max(0, min(1, value.location.x / UIScreen.main.bounds.width))
                        let newTime = percentage * session.duration
                        onSeek(newTime)
                    }
            )
            
            // Time markers
            timeMarkers
        }
    }
    
    private var medicalGrid: some View {
        GeometryReader { geo in
            Path { path in
                // Horizontal Lines (dB Levels)
                for i in 0...4 {
                    let y = geo.size.height * CGFloat(i) * 0.25
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geo.size.width, y: y))
                }
                
                // Vertical Lines (Time)
                let hourCount = Int(session.duration / 3600) + 1
                for i in 0...hourCount {
                    let x = CGFloat(i) * (geo.size.width / CGFloat(max(1, hourCount)))
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geo.size.height))
                }
            }
            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        }
    }
    
    private var snoreWaveLayer: some View {
        GeometryReader { geo in
            Path { path in
                let count = session.decibelTimeline.count
                guard count > 1 else { return }
                
                let stepX = geo.size.width / CGFloat(count - 1)
                path.move(to: CGPoint(x: 0, y: geo.size.height))
                
                for (index, db) in session.decibelTimeline.enumerated() {
                    let x = CGFloat(index) * stepX
                    let y = geo.size.height - normalizedHeight(db)
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                
                path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [.somAccent.opacity(0.8), .somAccent.opacity(0.2)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .background(Color.somAccent.opacity(0.05)) // Subtle background for the wave area
        }
    }
    
    private var apneaBlocksLayer: some View {
        GeometryReader { geo in
            let widthPerSecond = geo.size.width / CGFloat(session.duration)
            
            ForEach(session.apneaEvents) { event in
                let x = CGFloat(event.offsetSeconds) * widthPerSecond
                let w = CGFloat(event.durationSeconds) * widthPerSecond
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.somApnea.opacity(0.7))
                    .frame(width: max(2, w), height: geo.size.height)
                    .position(x: x + w/2, y: geo.size.height / 2)
                    .overlay(
                        Text(event.durationSeconds > 15 ? "\(Int(event.durationSeconds))s" : "")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .position(x: x + w/2, y: 10)
                    )
            }
        }
    }
    
    private var medicalCursor: some View {
        GeometryReader { geo in
            let x = CGFloat(currentTime / session.duration) * geo.size.width
            
            ZStack {
                // Glow
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2)
                    .shadow(color: .somAccent, radius: 4)
                
                // Head
                Circle()
                    .fill(.white)
                    .frame(width: 8, height: 8)
                    .offset(y: -geo.size.height/2)
            }
            .position(x: x, y: geo.size.height / 2)
        }
    }
    
    private var timeMarkers: some View {
        HStack {
            Text(session.startDate.formatted(.dateTime.hour().minute()))
            Spacer()
            Text(session.endDate.formatted(.dateTime.hour().minute()))
        }
        .font(.system(size: 9, weight: .bold))
        .foregroundColor(.somTextSecondary)
        .padding(.horizontal, 2)
    }
    
    private func normalizedHeight(_ db: Float) -> CGFloat {
        // Scale Agnostic Normalization: Supports both old (negative) and new (positive) dB scales
        let normalized: Float
        if db < 0 {
            // Old Scale: -60 to -10
            normalized = (db - (-60)) / 50
        } else {
            // New Scale: 30 to 80
            normalized = (db - 30) / 50
        }
        return CGFloat(max(0.05, min(1.0, normalized)) * 120 * 0.8) // Relative to canvas height
    }
    
    private func formatTime(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        return String(format: "%02d:%02d", m, s)
    }
}
