import SwiftUI
import SwiftData

struct FilmRollListView: View {
    @Query(sort: \FilmRoll.year, order: .reverse) private var rolls: [FilmRoll]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(rolls) { roll in
                        NavigationLink {
                            ReelView(roll: roll)
                        } label: {
                            RollRowView(roll: roll)
                        }
                        .buttonStyle(.plain)

                        if roll != rolls.last {
                            Divider()
                                .background(Color.borderStandard)
                                .padding(.leading, 72)
                        }
                    }
                }
                .padding(.top, Spacing.sm)
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

// MARK: - Roll Row
private struct RollRowView: View {
    let roll: FilmRoll

    var body: some View {
        HStack(spacing: Spacing.lg) {
            // Film strip icon
            ZStack {
                RoundedRectangle(cornerRadius: Radius.sm)
                    .fill(Color.bgCard)
                    .frame(width: 52, height: 52)

                // Sprocket holes
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

                // Frame count in center
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
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.lg)
        .background(Color.bgPrimary)
    }
}
