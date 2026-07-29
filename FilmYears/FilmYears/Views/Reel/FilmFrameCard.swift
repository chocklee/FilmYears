import SwiftUI
import PhotosUI

struct FilmFrameCard: View {
    @Bindable var frame: FilmFrame
    @State private var showEditor = false
    @State private var leftGlowIndex: Int? = nil
    @State private var rightGlowIndex: Int? = nil

    var body: some View {
        HStack(spacing: 0) {
            SprocketHoles(height: 341, glowIndex: leftGlowIndex)

            VStack(spacing: 0) {
                ZStack {
                    if frame.isFilled, let path = frame.photoPath {
                        FramePhoto(path: path)
                            .id(path)
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: 284)
                            .clipped()
                    } else {
                        VStack(spacing: 16) {
                            Image("CaptureIcon")
                                .resizable()
                                .frame(width: 40, height: 36)
                            Text("等待曝光")
                                .foregroundColor(.textTertiary)
                                .font(.system(size: 11, weight: .medium))
                        }
                        .frame(maxWidth: .infinity, maxHeight: 284)
                    }
                }
                .background(Color(hex: "#131313").opacity(0.3))

                HStack {
                    Text(frame.displayDate)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    Spacer()
                    if let note = frame.note, !note.isEmpty {
                        Text(note)
                            .font(.system(size: 16, weight: .medium))
                            .lineLimit(1)
                            .foregroundColor(.textTertiary)
                    }
                }
                .frame(height: 57)
                .padding(.horizontal, 16)
                .background(Color.bgCard)
            }
            .frame(height: 341)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(0.05), style: StrokeStyle(
                        lineWidth: 1,
                        dash: frame.isFilled ? [] : [4]
                    ))
            )

            SprocketHoles(height: 341, glowIndex: rightGlowIndex)
        }
        .frame(height: 341)
        .onTapGesture { showEditor = true }
        .sheet(isPresented: $showEditor) {
            EditFrameSheet(frame: frame)
                .presentationDetents([.height(556)])
        }
        .onChange(of: frame.isFilled) { _, filled in
            withAnimation(.easeInOut(duration: 0.4)) {
                if filled {
                    leftGlowIndex = Int.random(in: 0...4)
                    repeat { rightGlowIndex = Int.random(in: 0...4) }
                        while rightGlowIndex == leftGlowIndex
                } else {
                    leftGlowIndex = nil
                    rightGlowIndex = nil
                }
            }
        }
        .onAppear {
            if frame.isFilled {
                leftGlowIndex = Int.random(in: 0...4)
                repeat { rightGlowIndex = Int.random(in: 0...4) }
                    while rightGlowIndex == leftGlowIndex
            }
        }
    }
}

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
