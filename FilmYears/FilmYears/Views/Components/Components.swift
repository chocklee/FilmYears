import SwiftUI

// MARK: - Sprocket Holes (rectangular like real 35mm film)
struct SprocketHoles: View {
    let highlighted: Bool
    var accentOpacity: Double { highlighted ? 0.5 : 0.15 }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0 ..< 8) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.accentColor.opacity(accentOpacity))
                    .frame(width: 8, height: 5)
                if i < 7 {
                    Spacer()
                }
            }
        }
        .padding(.vertical, 6)
        .frame(width: 14)
    }
}

// MARK: - Film Grain Overlay (SVG noise)
struct FilmGrainOverlay: View {
    var body: some View {
        Rectangle()
            .fill(Color.black.opacity(0.03))
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

// MARK: - Mini Film Strip (for home list rows)
struct MiniFilmStrip: View {
    let filledCount: Int
    let totalCount: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(.systemGray5))
                .frame(width: 48, height: 48)

            // Mini sprocket decoration
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

// MARK: - Focus/ScreenTime color indicator
struct FrameTintOverlay: View {
    let focusActive: Bool?
    let screenTimeScore: Double?

    var body: some View {
        ZStack(alignment: .top) {
            if focusActive == true {
                Color.accentColor.opacity(0.12)
            }
            if let score = screenTimeScore, score > 0.5 {
                VStack {
                    Rectangle()
                        .fill(Color.orange.opacity(0.3))
                        .frame(height: 3)
                    Spacer()
                }
            }
        }
        .allowsHitTesting(false)
    }
}
