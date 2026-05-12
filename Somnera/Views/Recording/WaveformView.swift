import SwiftUI

/// Animated audio waveform drawn with SwiftUI Canvas.
struct WaveformView: View {
    let samples: [Float]        // 60 amplitude values (0.0–1.0)
    var isApnea: Bool = false

    private let barCount = 60
    private let barSpacing: CGFloat = 2

    var barColor: Color {
        isApnea ? .somApnea : .somAccent
    }

    var body: some View {
        Canvas { context, size in
            let barWidth = (size.width - CGFloat(barCount - 1) * barSpacing) / CGFloat(barCount)
            let midY = size.height / 2

            for (i, sample) in samples.enumerated() {
                let x = CGFloat(i) * (barWidth + barSpacing)
                let barHeight = max(4, CGFloat(sample) * size.height * 0.9)
                let rect = CGRect(
                    x: x,
                    y: midY - barHeight / 2,
                    width: barWidth,
                    height: barHeight
                )
                let path = Path(roundedRect: rect, cornerRadius: barWidth / 2)

                // Fade older bars
                let alpha = 0.3 + (Double(i) / Double(barCount)) * 0.7
                context.fill(path, with: .color(barColor.opacity(alpha)))
            }
        }
        .animation(.linear(duration: 0.1), value: samples)
    }
}
