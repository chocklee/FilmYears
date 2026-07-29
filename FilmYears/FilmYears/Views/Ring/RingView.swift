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

                let sortedFrames = roll.frames.sorted { $0.date < $1.date }
                RingChart(frames: sortedFrames) { _ in
                    dismiss()
                }
                .frame(width: 300, height: 300)
                .padding(.top, 56)

                HStack(spacing: 16) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.accentGold)
                            .frame(width: 8, height: 8)
                            .shadow(color: Color.accentGold.opacity(0.6), radius: 4)
                        Text("已填充")
                            .foregroundColor(Color(hex: "#E5E2E1"))
                            .font(.system(size: 11, weight: .medium))
                    }
                    Label("空白", systemImage: "circle")
                        .foregroundColor(.textTertiary)
                        .font(.system(size: 11, weight: .medium))
                }
                .padding(.top, 48)

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
        let sorted = roll.frames.sorted { $0.date < $1.date }
        let chart = RingChart(frames: sorted)
            .frame(width: 280, height: 280)

        let renderer = ImageRenderer(content: chart)
        renderer.scale = UIScreen.main.scale

        if let image = renderer.uiImage {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            showExportSuccess = true
        }
    }
}
