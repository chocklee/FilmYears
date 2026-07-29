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
            // Header strip
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(roll.year) 年")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("\(roll.filledCount)/\(roll.totalCount) 帧 · \(Int(roll.fillRatio * 100))% 已填充")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))

            Divider()

            // Frame list
            ScrollView {
                LazyVStack(spacing: 24) {
                    ForEach(sortedFrames) { frame in
                        FilmFrameCard(frame: frame, onUpdate: {
                            refreshID = UUID()
                        })
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 16)
            }
        }
        .id(refreshID)
        .background(Color(.systemGray6))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    RingView(year: roll.year)
                } label: {
                    Image(systemName: "circle.dotted")
                }
            }
        }
    }
}
