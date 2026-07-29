import SwiftUI
import SwiftData

struct FilmRollListView: View {
    @Query(sort: \FilmRoll.year, order: .reverse) private var rolls: [FilmRoll]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 29) {
                    ForEach(rolls) { roll in
                        NavigationLink {
                            ReelView(roll: roll)
                        } label: {
                            RollRowView(roll: roll)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(Spacing.xl)
            }
            .background(Color.bgPrimary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: Spacing.sm) {
                        Text("🎞️")
                            .font(.system(size: 20))
                        Text("FilmYears")
                            .font(AppFont.h2)
                            .foregroundColor(.textPrimary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(.textSecondary)
                    }
                }
            }
        }
    }
}

// MARK: - Roll Row (Card Style)
private struct RollRowView: View {
    let roll: FilmRoll

    var body: some View {
        HStack(spacing: Spacing.lg) {
            // Film strip icon
            ZStack {
                RoundedRectangle(cornerRadius: Radius.sm)
                    .fill(Color.bgCard)
                    .frame(width: 52, height: 52)

                VStack(spacing: 4) {
                    ForEach(0 ..< 3) { _ in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.accentGold.opacity(0.25))
                                .frame(width: 4, height: 4)
                            Circle()
                                .fill(Color.accentGold.opacity(0.25))
                                .frame(width: 4, height: 4)
                        }
                    }
                }

                Text("\(roll.filledCount)")
                    .font(AppFont.caption.weight(.bold))
                    .foregroundColor(.textSecondary)
            }

            // Year info
            VStack(alignment: .leading, spacing: 2) {
                Text("\(roll.year)")
                    .font(AppFont.h1)
                    .foregroundColor(.textPrimary)

                Text("\(roll.filledCount)/\(roll.totalCount) 帧已填充")
                    .font(AppFont.caption)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            // Density bar
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.bgCardStrong)
                .frame(width: 4, height: 40)
                .overlay(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.accentGold)
                        .frame(height: 40 * roll.fillRatio)
                }
        }
        .padding(Spacing.lg)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}
