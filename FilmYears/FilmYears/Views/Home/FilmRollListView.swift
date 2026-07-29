import SwiftUI
import SwiftData

struct FilmRollListView: View {
    @Query(sort: \FilmRoll.year, order: .reverse) private var rolls: [FilmRoll]

    var body: some View {
        NavigationStack {
            List(rolls) { roll in
                NavigationLink {
                    ReelView(roll: roll)
                } label: {
                    RollRowView(roll: roll)
                }
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .navigationTitle("FilmYears")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
    }
}

// MARK: - Roll Row
private struct RollRowView: View {
    let roll: FilmRoll

    var body: some View {
        HStack(spacing: 16) {
            MiniFilmStrip(filledCount: roll.filledCount, totalCount: roll.totalCount)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(roll.year)")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("\(roll.filledCount)/\(roll.totalCount) 帧已填充")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            DensityBar(ratio: roll.fillRatio)
        }
        .padding(.vertical, 8)
    }
}
