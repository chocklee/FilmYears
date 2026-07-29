import SwiftUI

struct FilmFrameCard: View {
    let frame: FilmFrame
    @State private var showEditor = false

    var body: some View {
        HStack(spacing: 0) {
            SprocketHoles(highlighted: false)

            VStack(spacing: 0) {
                ZStack {
                    Rectangle()
                        .fill(Color(.systemGray6))
                        .aspectRatio(1, contentMode: .fill)

                    if frame.isFilled {
                        if let path = frame.photoPath {
                            ImageLoader(path: path)
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .clipped()
                        }
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.badge.plus")
                                .font(.title)
                                .foregroundColor(.secondary)
                            Text("空白底片")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    FilmGrainOverlay()
                }

                HStack {
                    Text(frame.displayDate)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    if let note = frame.note {
                        Text(note)
                            .font(.caption)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }

            SprocketHoles(highlighted: false)
        }
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .onTapGesture { showEditor = true }
        .sheet(isPresented: $showEditor) {
            EditFrameSheet(frame: frame)
        }
    }
}

/// Placeholder: image loader from local path
struct ImageLoader: View {
    let path: String
    var body: some View {
        Color(.systemGray4)
            .overlay(Image(systemName: "photo").foregroundColor(.secondary))
    }
}
