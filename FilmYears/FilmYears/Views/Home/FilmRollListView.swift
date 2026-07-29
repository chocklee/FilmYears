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
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 8) {
                        Image("AppLogo")
                            .resizable()
                            .frame(width: 20, height: 16)
                        Text("FilmYears")
                            .font(.system(size: 18, weight: .bold))
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
        HStack(spacing: 16) {
            // Film strip image
            Image("FilmStripIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 82)

            // Year info
            VStack(alignment: .leading, spacing: 2) {
                Text(roll.yearFormatted)
                    .font(.system(size: 30, weight: .regular))
                    .foregroundColor(.textPrimary)

                Text(roll.frameCountFormatted)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "#6B6660"))
            }

            Spacer()

            // Density bar
            ZStack {
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.bgCardStrong)
                    .overlay(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.accentGold)
                            .frame(width: 4, height: 48 * roll.fillRatio)
                    }
            }
            .frame(width: 6, height: 48)
        }
        .frame(height: 82)
        .padding(.trailing, Spacing.lg)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}
