import SwiftUI
import PhotosUI

struct FilmFrameCard: View {
    @Bindable var frame: FilmFrame
    let onUpdate: (() -> Void)?
    @State private var showEditor = false

    init(frame: FilmFrame, onUpdate: (() -> Void)? = nil) {
        self.frame = frame
        self.onUpdate = onUpdate
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left sprocket holes
            SprocketHoles(highlighted: frame.focusActive ?? false)

            // Frame body
            VStack(spacing: 0) {
                // Photo / empty area
                ZStack {
                    Rectangle()
                        .fill(Color(.systemGray6))
                        .aspectRatio(3 / 2, contentMode: .fit)

                    if frame.isFilled, let path = frame.photoPath {
                        FramePhoto(path: path)
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.badge.plus")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            Text("空白底片")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Grain overlay
                    FilmGrainOverlay()

                    // Focus / ScreenTime tint
                    FrameTintOverlay(
                        focusActive: frame.focusActive,
                        screenTimeScore: frame.screenTimeScore
                    )
                }

                // Bottom info bar (film edge marking style)
                HStack {
                    Text(frame.displayDate)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                    Spacer()
                    if let note = frame.note, !note.isEmpty {
                        Text(note)
                            .font(.caption2)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
            }
            .clipShape(RoundedRectangle(cornerRadius: 4))

            // Right sprocket holes
            SprocketHoles(highlighted: frame.focusActive ?? false)
        }
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        .onTapGesture { showEditor = true }
        .sheet(isPresented: $showEditor) {
            EditFrameSheet(frame: frame)
                .onDisappear {
                    onUpdate?()
                }
        }
    }
}

// MARK: - Image loader from local path
private struct FramePhoto: View {
    let path: String

    var body: some View {
        let url = PhotoManager.documentsDir
            .deletingLastPathComponent()
            .appendingPathComponent(path)
        if let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Color(.systemGray4)
                .overlay {
                    Image(systemName: "photo")
                        .foregroundColor(.secondary)
                }
        }
    }
}
