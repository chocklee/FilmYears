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
            SprocketHoles(highlighted: frame.focusActive ?? false, height: 343)

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
                        ZStack {
                            // Film negative base
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(.systemGray6),
                                            Color(.systemGray5).opacity(0.5),
                                            Color(.systemGray6),
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            // Subtle film-edge markings
                            VStack {
                                HStack {
                                    Text(frame.displayDate)
                                        .font(.system(size: 7, design: .monospaced))
                                        .foregroundColor(.secondary.opacity(0.5))
                                        .padding(.leading, 4)
                                    Spacer()
                                    Text("\(frame.roll?.year ?? 0)")
                                        .font(.system(size: 7, design: .monospaced))
                                        .foregroundColor(.secondary.opacity(0.5))
                                        .padding(.trailing, 4)
                                }
                                .padding(.top, 2)

                                Spacer()

                                // Inviting capture icon
                                VStack(spacing: 6) {
                                    Image(systemName: "camera.viewfinder")
                                        .font(.title3)
                                        .foregroundColor(.secondary.opacity(0.4))
                                    Text("轻触记录")
                                        .font(.caption2)
                                        .foregroundColor(.secondary.opacity(0.4))
                                }

                                Spacer()

                                // Film frame number
                                HStack {
                                    Spacer()
                                    Text("✦")
                                        .font(.system(size: 6))
                                        .foregroundColor(.secondary.opacity(0.3))
                                        .padding(.trailing, 4)
                                        .padding(.bottom, 2)
                                }
                            }
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
            SprocketHoles(highlighted: frame.focusActive ?? false, height: 343)
        }
        .frame(height: 343)
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
