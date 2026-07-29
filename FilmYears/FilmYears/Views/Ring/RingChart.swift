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
            let gap = total <= 1 ? 0 : segmentAngle * 0.15
            let drawAngle = segmentAngle - gap

            ZStack {
                ForEach(Array(frames.enumerated()), id: \.offset) { index, frame in
                    // Align Jan 1st at 12 o'clock based on day of year
                    let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: frame.date) ?? 1
                    let start = Double(dayOfYear - 1) * segmentAngle - .pi / 2

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
            isFilled ? Color.accentGold : Color.bgCardStrong,
            style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt)
        )
    }
}

// MARK: - Center year label
private struct CenterLabel: View {
    let frames: [FilmFrame]

    var body: some View {
        VStack(spacing: 4) {
            let year = Calendar.current.component(.year, from: frames.first?.date ?? .now)
            Text("\(year.formatted(.number.grouping(.never)))")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(Color.textPrimary)
            Text("\(frames.filter(\.isFilled).count) 帧回忆")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(hex: "#D3C4B2"))
        }
    }
}
