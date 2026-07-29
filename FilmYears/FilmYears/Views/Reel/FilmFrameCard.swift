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
                    if frame.isFilled, let path = frame.photoPath {
                        FramePhoto(path: path)
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: 272)
                            .clipped()
                    } else {
                        ZStack {
                            // Inviting capture icon
                            VStack(spacing: 16) {
                                Image("CaptureIcon")
                                    .resizable()
                                    .frame(width: 40, height: 36)
                                Text("等待曝光")
                                    .foregroundColor(.textTertiary)
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .background(Color.clear)
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
                .background(Color(hex: "131313").opacity(0.3))

                // Bottom info bar (film edge marking style)
                HStack {
                    Text(frame.displayDate)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    Spacer()
                    if let note = frame.note, !note.isEmpty {
                        Text(note)
                            .font(.caption2)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                    }
                }
                .frame(height: 57)
                .padding(.horizontal, 16)
                .background(Color.bgCard)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(0.05), style: StrokeStyle(
                        lineWidth: 1,
                        dash: frame.isFilled ? [] : [4]
                    ))
            )

            // Right sprocket holes
            SprocketHoles(highlighted: frame.focusActive ?? false, height: 343)
        }
        .frame(height: 343)
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
