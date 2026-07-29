import SwiftUI
import SwiftData

struct ReelView: View {
    @Bindable var roll: FilmRoll
    @State private var refreshID = UUID()
    @State private var scrollTarget: FilmFrame?

    private var sortedFrames: [FilmFrame] {
        roll.frames.sorted { $0.date > $1.date }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 32) {
                    ForEach(sortedFrames) { frame in
                        FilmFrameCard(frame: frame, onUpdate: { edited in
                            scrollTarget = edited
                            refreshID = UUID()
                        })
                        .padding(.horizontal, Spacing.xl)
                        .id(frame.id)
                    }
                }
                .padding(.vertical, Spacing.xl)
            }
            .id(refreshID)
            .onChange(of: refreshID) { _, _ in
                if let target = scrollTarget {
                    withAnimation {
                        proxy.scrollTo(target.id, anchor: .center)
                    }
                    scrollTarget = nil
                }
            }
        }
        .background(Color.bgPrimary)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
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
