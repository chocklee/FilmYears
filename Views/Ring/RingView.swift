import SwiftUI
import SwiftData

struct RingView: View {
    let year: Int
    @Query private var rolls: [FilmRoll]

    init(year: Int) {
        self.year = year
        let predicate = #Predicate<FilmRoll> { $0.year == year }
        _rolls = Query(filter: predicate)
    }

    var body: some View {
        VStack(spacing: 24) {
            if let roll = rolls.first {
                RingChart(frames: roll.frames)
                    .frame(width: 280, height: 280)

                Text("\(roll.filledCount)/\(roll.totalCount) 天已填充")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 20) {
                    Label("已填充", systemImage: "circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.caption)
                    Label("空白", systemImage: "circle")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }

                Button("导出年轮图片") {
                    // TODO: ImageRenderer export
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
            } else {
                ContentUnavailableView("暂无数据", systemImage: "circle.dotted")
            }
        }
        .padding()
        .navigationTitle("\(year) 年轮")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { } label: {
                    Image(systemName: "square.and.arrow.down")
                }
            }
        }
    }
}
