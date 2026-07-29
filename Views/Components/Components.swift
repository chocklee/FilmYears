import SwiftUI

// MARK: - Film Sprocket Holes
struct SprocketHoles: View {
    let highlighted: Bool

    var body: some View {
        VStack(spacing: 8) {
            ForEach(0 ..< 6) { i in
                Circle()
                    .fill(highlighted && (i == 1 || i == 4)
                        ? Color.accentColor.opacity(0.6)
                        : Color.accentColor.opacity(0.2))
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.vertical, 8)
        .frame(width: 12)
    }
}

// MARK: - Film Grain Overlay
struct FilmGrainOverlay: View {
    var body: some View {
        Rectangle()
            .fill(Color.black.opacity(0.03))
            .overlay(
                Rectangle()
                    .fill(Color.black.opacity(0.04))
                    .blendMode(.overlay)
            )
            .allowsHitTesting(false)
    }
}

// MARK: - Density Bar
struct DensityBar: View {
    let ratio: Double

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color(.systemGray5))
            .frame(width: 4, height: 32)
            .overlay(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.accentColor)
                    .frame(height: 32 * ratio)
            }
    }
}

// MARK: - Mini Film Strip
struct MiniFilmStrip: View {
    let filledCount: Int
    let totalCount: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(.systemGray5))
                .frame(width: 48, height: 48)

            VStack(spacing: 2) {
                ForEach(0 ..< 3) { _ in
                    HStack(spacing: 2) {
                        ForEach(0 ..< 4) { _ in
                            Circle()
                                .fill(Color.accentColor.opacity(0.3))
                                .frame(width: 3, height: 3)
                        }
                    }
                }
            }

            Text("\(filledCount)")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
        }
        .frame(width: 48, height: 48)
    }
}
