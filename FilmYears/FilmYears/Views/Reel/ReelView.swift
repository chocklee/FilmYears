import SwiftUI
import SwiftData

struct ReelView: View {
    @Bindable var roll: FilmRoll
    @Environment(\.dismiss) private var dismiss

    private var sortedFrames: [FilmFrame] {
        roll.frames.sorted { $0.date > $1.date }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 32) {
                ForEach(sortedFrames) { frame in
                    FilmFrameCard(frame: frame)
                        .padding(.horizontal, Spacing.xl)
                }
            }
            .padding(.vertical, Spacing.xl)
        }
        .background(Color.bgPrimary)
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("返回")
                    }
                    .foregroundColor(.textSecondary)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("\(roll.yearFormatted) 年")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.textPrimary)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    RingView(year: roll.year, yearFormatted: roll.yearFormatted)
                } label: {
                    Image(systemName: "circle.dotted")
                        .foregroundColor(.textSecondary)
                }
            }
        }
    }
}
