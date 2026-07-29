import SwiftUI
import SwiftData

struct ReelView: View {
    @Bindable var roll: FilmRoll
    @State private var refreshID = UUID()

    private var sortedFrames: [FilmFrame] {
        roll.frames.sorted { $0.date < $1.date }
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.borderStandard)

            // Frame list
            ScrollView {
                LazyVStack(spacing: 24) {
                    ForEach(sortedFrames) { frame in
                        FilmFrameCard(frame: frame, onUpdate: {
                            refreshID = UUID()
                        })
                        .padding(.horizontal, Spacing.lg)
                    }
                }
                .padding(.vertical, Spacing.lg)
            }
        }
        .id(refreshID)
        .background(Color.bgPrimary)
        .toolbarBackground(Color.bgPrimary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("\(roll.yearFormatted) 年")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.textPrimary)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    RingView(year: roll.year)
                } label: {
                    Image(systemName: "circle.dotted")
                        .foregroundColor(.textSecondary)
                }
            }
        }
    }
}
