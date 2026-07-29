import SwiftUI

// MARK: - Sprocket Holes
struct SprocketHoles: View {
    let height: CGFloat
    let glowIndex: Int?

    init(height: CGFloat = 343, glowIndex: Int? = nil) {
        self.height = height
        self.glowIndex = glowIndex
    }

    var body: some View {
        VStack(spacing: 50) {
            ForEach(0 ..< 5) { i in
                RoundedRectangle(cornerRadius: 6)
                    .fill(glowIndex == i ? Color.textPrimary : Color(hex: "#C8963E").opacity(0.2))
                    .frame(width: 12, height: 12)
                    .shadow(
                        color: glowIndex == i ? Color.textPrimary.opacity(0.6) : .clear,
                        radius: glowIndex == i ? 6 : 0
                    )
            }
        }
        .frame(width: 32, height: height)
        .background(Color.bgPrimary)
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
