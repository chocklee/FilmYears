import SwiftUI
import PhotosUI

struct EditFrameSheet: View {
    let frame: FilmFrame
    @Environment(\.dismiss) private var dismiss
    @State private var note: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var hasPhoto: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            // Drag handle
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 4)
                .padding(.top, 8)

            // Date title
            Text(frame.fullDate)
                .font(.headline)
                .fontWeight(.semibold)

            // Photo picker area
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            hasPhoto ? Color.accentColor : Color(.systemGray4),
                            style: StrokeStyle(lineWidth: hasPhoto ? 2 : 1.5, dash: hasPhoto ? [] : [6])
                        )
                        .aspectRatio(4 / 3, contentMode: .fit)

                    if hasPhoto {
                        Color(.systemGray5)
                            .overlay(
                                Image(systemName: "photo.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.badge.plus")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            Text("点击添加照片")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            .onChange(of: selectedPhoto) { _, _ in
                hasPhoto = true
            }

            // Note input
            VStack(spacing: 8) {
                TextField("添加一行备注（最多 80 字符）", text: $note, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onChange(of: note) { _, newValue in
                        if newValue.count > 80 { note = String(newValue.prefix(80)) }
                    }

                HStack {
                    Spacer()
                    Text("\(note.count)/80")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            // Action buttons
            HStack(spacing: 12) {
                Button("删除照片", role: .destructive) {
                    hasPhoto = false
                    selectedPhoto = nil
                }
                .buttonStyle(.bordered)
                .tint(.red)

                Button("保存") {
                    saveFrame()
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
            }
        }
        .padding()
        .padding(.bottom, 16)
        .task {
            note = frame.note ?? ""
            hasPhoto = frame.isFilled
        }
    }

    private func saveFrame() {
        frame.note = note.isEmpty ? nil : note
        if hasPhoto {
            // In a real app, save the selected photo via PhotoManager
            frame.photoPath = "placeholder_path"
        } else {
            frame.photoPath = nil
            if let path = frame.photoPath {
                PhotoManager.deletePhoto(at: path)
            }
        }
        dismiss()
    }
}
