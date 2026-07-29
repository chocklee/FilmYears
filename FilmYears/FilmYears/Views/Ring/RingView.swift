import SwiftUI
import SwiftData

struct RingView: View {
    let year: Int
    @Environment(\.dismiss) private var dismiss
    @State private var exportedImage: UIImage?
    @State private var showExportSuccess = false
    @Query private var rolls: [FilmRoll]

    init(year: Int) {
        self.year = year
        let predicate = #Predicate<FilmRoll> { $0.year == year }
        _rolls = Query(filter: predicate)
    }

    var body: some View {
        VStack(spacing: 24) {
            if let roll = rolls.first {
                // Exportable ring snapshot
                RingChart(frames: roll.frames) { _ in
                    // Tap to go back to reel
                    dismiss()
                }
                .frame(width: 280, height: 280)

                Text("\(roll.filledCount)/\(roll.totalCount) 天已填充")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Legend
                HStack(spacing: 20) {
                    Label("已填充", systemImage: "circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.caption)
                    Label("空白", systemImage: "circle")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }

                // Export button
                Button {
                    exportRing(roll: roll)
                } label: {
                    Label("导出年轮图片", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)

                Text("点击年轮色块跳转至对应日期")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            } else {
                ContentUnavailableView("暂无数据", systemImage: "circle.dotted")
            }
        }
        .padding()
        .navigationTitle("\(year) 年轮")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    if let roll = rolls.first { exportRing(roll: roll) }
                } label: {
                    Image(systemName: "square.and.arrow.down")
                }
            }
        }
        .alert("已保存", isPresented: $showExportSuccess) {
            Button("好的", role: .cancel) { }
        } message: {
            Text("年轮图片已保存到相册")
        }
    }

    private func exportRing(roll: FilmRoll) {
        let chart = RingChart(frames: roll.frames)
            .frame(width: 280, height: 280)

        let renderer = ImageRenderer(content: chart)
        renderer.scale = UIScreen.main.scale

        if let image = renderer.uiImage {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            showExportSuccess = true
        }
    }
}
