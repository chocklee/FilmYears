import SwiftUI
import SwiftData

struct RingOverviewView: View {
    @Query(sort: \FilmRoll.year, order: .reverse) private var rolls: [FilmRoll]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Section header
                    Text("全部胶卷 · 年轮总览")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)

                    if rolls.isEmpty {
                        ContentUnavailableView(
                            "暂无胶卷",
                            systemImage: "circle.dotted",
                            description: Text("完成引导后胶卷将自动生成")
                        )
                    } else {
                        // Concentric rings overview
                        ConcentricRingView(rolls: rolls)
                            .frame(height: 260)
                            .padding(.horizontal, 20)

                        // Legend
                        HStack(spacing: 20) {
                            Label("已填充", systemImage: "circle.fill")
                                .foregroundColor(.accentColor)
                                .font(.caption)
                            Label("空白", systemImage: "circle")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }

                        // Per-year rows
                        LazyVStack(spacing: 0) {
                            ForEach(rolls) { roll in
                                NavigationLink {
                                    ReelView(roll: roll)
                                } label: {
                                    RingOverviewRow(roll: roll)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 16)
            }
            .tint(.textSecondary)
            .navigationTitle("FilmYears")
        }
    }
}

// MARK: - Concentric Rings SVG
private struct ConcentricRingView: View {
    let rolls: [FilmRoll]
    let size: CGFloat = 240

    var body: some View {
        let sorted = rolls.sorted { $0.year < $1.year }
        let spacing: CGFloat = min(22, max(14, 160 / CGFloat(max(sorted.count, 1))))
        let baseRadius: CGFloat = 18

        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)

            for (index, roll) in sorted.enumerated() {
                let radius = baseRadius + CGFloat(index) * spacing
                let total = max(roll.totalCount, 1)
                let filled = roll.filledCount

                // Full circle background
                var emptyPath = Path()
                emptyPath.addArc(
                    center: center,
                    radius: radius,
                    startAngle: .degrees(-90),
                    endAngle: .degrees(270),
                    clockwise: false
                )
                context.stroke(emptyPath, with: .color(Color(.systemGray6)), lineWidth: spacing - 2)

                // Filled portion
                let filledRatio = Double(filled) / Double(total)
                if filledRatio > 0 {
                    var filledPath = Path()
                    filledPath.addArc(
                        center: center,
                        radius: radius,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(-90 + 360 * filledRatio),
                        clockwise: false
                    )
                    context.stroke(filledPath, with: .color(Color.accentColor), lineWidth: spacing - 2)
                }
            }

            // Center year label
            let mostRecent = sorted.last?.year ?? Calendar.current.component(.year, from: .now)
            context.draw(Text("\(mostRecent)")
                .font(.headline.weight(.bold))
                .foregroundColor(.primary),
                at: center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Per-Year Row
private struct RingOverviewRow: View {
    let roll: FilmRoll

    var body: some View {
        HStack(spacing: 16) {
            MiniRing(roll: roll, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(roll.year)")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Text("\(roll.filledCount)/\(roll.totalCount) 帧")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

// MARK: - Mini Ring Preview
private struct MiniRing: View {
    let roll: FilmRoll
    let size: CGFloat

    var body: some View {
        let total = max(roll.totalCount, 1)
        let filledRatio = Double(roll.filledCount) / Double(total)

        ZStack {
            Circle()
                .stroke(Color(.systemGray6), lineWidth: 4)

            Circle()
                .trim(from: 0, to: CGFloat(min(filledRatio, 1)))
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}
