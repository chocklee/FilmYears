import SwiftUI
import SwiftData

struct RingView: View {
    let year: Int
    let yearFormatted: String
    @Environment(\.dismiss) private var dismiss
    @State private var exportedImage: UIImage?
    @State private var showExportSuccess = false
    @Query private var rolls: [FilmRoll]

    init(year: Int, yearFormatted: String) {
        self.year = year
        self.yearFormatted = yearFormatted
        let predicate = #Predicate<FilmRoll> { $0.year == year }
        _rolls = Query(filter: predicate)
    }

    var body: some View {
        VStack(spacing: 24) {
            if let roll = rolls.first {
                Text("Ring Overview")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.textPrimary)
                    .padding(.top, 43)

                Text("时间凝练成环，每一帧都是生活的见证。")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.textTertiary)
                    .padding(.top, -16)

                RingChart(frames: roll.frames) { _ in
                    dismiss()
                }
                .frame(width: 280, height: 280)
                .padding(.top, 56)

                Text("\(roll.frameCountFormatted) 天已填充")
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

                Button {
                    exportRing(roll: roll)
                } label: {
                    Label("导出年轮图片", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)

                Spacer()
            } else {
                ContentUnavailableView("暂无数据", systemImage: "circle.dotted")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bgPrimary)
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                    }
                    .foregroundColor(.textSecondary)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("\(yearFormatted) 年轮")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.textPrimary)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    if let roll = rolls.first { exportRing(roll: roll) }
                } label: {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundColor(.textSecondary)
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
