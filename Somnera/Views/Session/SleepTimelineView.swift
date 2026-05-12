import SwiftUI

struct SleepTimelineView: View {
    let session: SleepSession
    @Binding var currentTime: TimeInterval
    let onSeek: (TimeInterval) -> Void
    
    private let barWidth: CGFloat = 3
    private let spacing: CGFloat = 1
    
    private var totalDuration: Double {
        max(1.0, session.duration)
    }
    
    private var sampleInterval: Double {
        totalDuration / Double(max(1, session.decibelTimeline.count))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 1. Bird's Eye Overview
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Navegación Nocturna")
                        .font(.system(.caption, design: .rounded).bold())
                        .foregroundColor(.somTextPrimary)
                    Spacer()
                    Text(formatTime(currentTime) + " / " + formatTime(totalDuration))
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.somTextSecondary)
                }
                .padding(.horizontal)
                
                overviewScrubber
                    .frame(height: 30)
                    .padding(.horizontal)
            }
            
            // 2. Detailed Scrollable View
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    ZStack(alignment: .leading) {
                        snoreZones
                        
                        LazyHStack(alignment: .bottom, spacing: spacing) {
                            ForEach(0..<session.decibelTimeline.count, id: \.self) { index in
                                let db = session.decibelTimeline[index]
                                let height = normalizedHeight(db)
                                
                                Rectangle()
                                    .fill(barColor(at: index))
                                    .frame(width: barWidth, height: height)
                                    .id(index)
                            }
                        }
                        .padding(.vertical, 10)
                        
                        apneaLines
                        playheadLine
                    }
                    .padding(.horizontal, 200)
                }
                .onChange(of: currentTime) { _, newValue in
                    let index = Int(newValue / sampleInterval)
                    withAnimation(.easeInOut(duration: 0.1)) {
                        proxy.scrollTo(index, anchor: .center)
                    }
                }
            }
            .frame(height: 100)
            .background(Color.somSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.somSurfaceHigh, lineWidth: 1)
            )
        }
    }
    
    // MARK: - Scrubber
    
    private var overviewScrubber: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.somSurface)
                
                // Snore markers (Purple)
                ForEach(session.snoreEvents.prefix(200)) { event in
                    let x = CGFloat(event.offsetSeconds / totalDuration) * geo.size.width
                    Rectangle()
                        .fill(Color.somAccent.opacity(0.4))
                        .frame(width: 2)
                        .offset(x: x)
                }
                
                // Apnea markers (Dynamic Color)
                ForEach(session.apneaEvents) { event in
                    let x = CGFloat(event.offsetSeconds / totalDuration) * geo.size.width
                    Rectangle()
                        .fill(event.severity.color)
                        .frame(width: 3)
                        .offset(x: x)
                }
                
                let handleX = CGFloat(currentTime / totalDuration) * geo.size.width
                Capsule()
                    .fill(Color.white)
                    .frame(width: 4)
                    .overlay(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 12, height: 12)
                    )
                    .offset(x: handleX - 2)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let percentage = max(0, min(1, value.location.x / geo.size.width))
                        onSeek(totalDuration * Double(percentage))
                    }
            )
        }
    }
    
    // MARK: - Detail Components
    
    private var snoreZones: some View {
        ZStack(alignment: .leading) {
            ForEach(session.snoreEvents) { event in
                let x = CGFloat(event.offsetSeconds / sampleInterval) * (barWidth + spacing)
                Rectangle()
                    .fill(Color.somAccent.opacity(0.12))
                    .frame(width: 15, height: 100)
                    .offset(x: x)
            }
        }
    }
    
    private var apneaLines: some View {
        ZStack(alignment: .leading) {
            ForEach(session.apneaEvents) { event in
                let x = CGFloat(event.offsetSeconds / sampleInterval) * (barWidth + spacing)
                Rectangle()
                    .fill(event.severity.color)
                    .frame(width: 2, height: 80)
                    .offset(x: x, y: 10)
            }
        }
    }
    
    private var playheadLine: some View {
        let x = CGFloat(currentTime / sampleInterval) * (barWidth + spacing)
        return Rectangle()
            .fill(Color.white)
            .frame(width: 2)
            .offset(x: x)
    }
    
    // MARK: - Helpers
    
    private func barColor(at index: Int) -> Color {
        let time = Double(index) * sampleInterval
        
        // 1. Check for Apnea first (Priority)
        if let apnea = session.apneaEvents.first(where: { 
            time >= $0.offsetSeconds && time <= ($0.offsetSeconds + $0.durationSeconds) 
        }) {
            return apnea.severity.color // DYNAMIC APNEA COLOR
        }
        
        // 2. Check for Snoring (PURPLE)
        if session.snoreEvents.contains(where: { 
            abs($0.offsetSeconds - time) < sampleInterval 
        }) {
            return .somAccent
        }
        
        // 3. Normal / Quiet
        return Color.somTextSecondary.opacity(0.1)
    }
    
    private func normalizedHeight(_ db: Float) -> CGFloat {
        let minDB: Float = -60
        let maxDB: Float = -10
        let normalized = (db - minDB) / (maxDB - minDB)
        return CGFloat(max(4, min(1.0, normalized)) * 60)
    }
    
    private func formatTime(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600
        let m = (Int(t) % 3600) / 60
        let s = Int(t) % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%02d:%02d", m, s)
    }
}
