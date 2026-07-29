import SwiftUI
import PhotosUI
import SwiftData

struct EditFrameSheet: View {
    let frame: FilmFrame
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var note: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var hasPhoto: Bool = false

    private var previewImage: UIImage? {
        guard let data = photoData else { return nil }
        return UIImage(data: data)
    }

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

                    if hasPhoto, let image = previewImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.badge.plus")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            Text(hasPhoto ? "点击更换照片" : "点击添加照片")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            .onChange(of: selectedPhoto) { _, newItem in
                Task {
                    guard let data = try? await newItem?.loadTransferable(type: Data.self) else { return }
                    photoData = data
                    hasPhoto = true
                }
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
                    photoData = nil
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
            // Load existing photo data for preview
            if hasPhoto, let path = frame.photoPath {
                photoData = try? Data(contentsOf: PhotoManager.documentsDir
                    .deletingLastPathComponent()
                    .appendingPathComponent(path))
            }
        }
    }

    private func saveFrame() {
        frame.note = note.isEmpty ? nil : note

        if hasPhoto, let data = photoData {
            // Save photo to disk
            let fileURL = PhotoManager.documentsDir
                .appendingPathComponent("\(frame.date.timeIntervalSince1970).jpg")
            try? FileManager.default.createDirectory(at: PhotoManager.documentsDir, withIntermediateDirectories: true)
            try? data.write(to: fileURL)
            frame.photoPath = "frames/\(frame.date.timeIntervalSince1970).jpg"
        } else {
            // Delete existing photo
            if let path = frame.photoPath {
                PhotoManager.deletePhoto(at: path)
            }
            frame.photoPath = nil
        }

        try? context.save()
        dismiss()
    }
}
