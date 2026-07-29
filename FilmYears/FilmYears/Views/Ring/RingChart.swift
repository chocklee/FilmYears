import SwiftUI

struct RingChart: View {
    let frames: [FilmFrame]
    var onSelectDate: ((Date) -> Void)?

    private let lineWidth: CGFloat = 24

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) / 2 - 20
            let total = max(frames.count, 1)
            let segmentAngle = 2 * .pi / Double(total)
            let gap: Double = 0.5
            let drawAngle = segmentAngle - gap

            ZStack {
                ForEach(Array(frames.enumerated()), id: \.offset) { index, frame in
                    let start = Double(index) * segmentAngle - .pi / 2
                    RingSegmentView(
                        center: center,
                        radius: radius,
                        startAngle: Angle(radians: start),
                        endAngle: Angle(radians: start + drawAngle),
                        isFilled: frame.isFilled,
                        lineWidth: lineWidth
                    )
                    .onTapGesture {
                        onSelectDate?(frame.date)
                    }
                }

                CenterLabel(frames: frames)
            }
        }
    }
}

// MARK: - Single ring segment
private struct RingSegmentView: View {
    let center: CGPoint
    let radius: CGFloat
    let startAngle: Angle
    let endAngle: Angle
    let isFilled: Bool
    let lineWidth: CGFloat

    var body: some View {
        Path { path in
            path.addArc(
                center: center,
                radius: radius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: false
            )
        }
        .stroke(
            isFilled ? Color.accentColor : Color(.systemGray5),
            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
        )
    }
}

// MARK: - Center year label
private struct CenterLabel: View {
    let frames: [FilmFrame]

    var body: some View {
        VStack(spacing: 4) {
            let year = Calendar.current.component(.year, from: frames.first?.date ?? .now)
            Text("\(year)")
                .font(.title2).fontWeight(.bold)
            Text("\(frames.filter(\.isFilled).count) 帧回忆")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
