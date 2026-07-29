import SwiftUI

struct RingChart: View {
    let frames: [FilmFrame]

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) / 2 - 20
            let total = max(frames.count, 1)
            let segmentAngle = 2 * .pi / Double(total)

            ZStack {
                ForEach(Array(frames.enumerated()), id: \.offset) { index, frame in
                    let startAngle = Angle(radians: Double(index) * segmentAngle - .pi / 2)
                    let endAngle = Angle(radians: Double(index + 1) * segmentAngle - .pi / 2)

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
                        frame.isFilled ? Color.accentColor : Color(.systemGray5),
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                }

                VStack(spacing: 4) {
                    Text("\(Calendar.current.component(.year, from: frames.first?.date ?? .now))")
                        .font(.title2).fontWeight(.bold)
                    Text("\(frames.filter(\.isFilled).count) 帧回忆")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
