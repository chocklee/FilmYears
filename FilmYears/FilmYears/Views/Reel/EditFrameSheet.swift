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
        VStack(spacing: 0) {
            // Drag handle
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white.opacity(0.2))
                .frame(width: 36, height: 4)
                .padding(.top, 12)

            // Date title
            Text(frame.fullDate)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.textPrimary)
                .padding(.top, 20)
                .padding(.bottom, 24)

            // Photo picker area
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "#131313"))
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
                                .foregroundColor(.textTertiary)
                            Text("点击添加照片")
                                .font(.system(size: 13))
                                .foregroundColor(.textTertiary)
                        }
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            hasPhoto ? Color.clear : Color.white.opacity(0.1),
                            style: StrokeStyle(lineWidth: 1, dash: [4])
                        )
                )
            }
            .onChange(of: selectedPhoto) { _, newItem in
                Task {
                    guard let data = try? await newItem?.loadTransferable(type: Data.self) else { return }
                    photoData = data
                    hasPhoto = true
                }
            }
            .padding(.horizontal, 24)

            // Note input
            VStack(spacing: 8) {
                TextField("添加一行备注（最多 80 字符）", text: $note, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .foregroundColor(.textPrimary)
                    .padding(12)
                    .background(Color(hex: "#131313"))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .onChange(of: note) { _, newValue in
                        if newValue.count > 80 { note = String(newValue.prefix(80)) }
                    }

                HStack {
                    Spacer()
                    Text("\(note.count)/80")
                        .font(.system(size: 11))
                        .foregroundColor(.textTertiary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            Spacer()

            // Action buttons
            HStack(spacing: 12) {
                Button(action: {
                    hasPhoto = false
                    photoData = nil
                    selectedPhoto = nil
                }) {
                    Text("删除照片")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(hex: "#E74C3C"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "#131313"))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: "#E74C3C").opacity(0.3), lineWidth: 1)
                        )
                }

                Button(action: saveFrame) {
                    Text("保存")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.accentGold)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color.bgPrimary)
        .task {
            note = frame.note ?? ""
            hasPhoto = frame.isFilled
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
            let fileURL = PhotoManager.documentsDir
                .appendingPathComponent("\(frame.date.timeIntervalSince1970).jpg")
            try? FileManager.default.createDirectory(at: PhotoManager.documentsDir, withIntermediateDirectories: true)
            try? data.write(to: fileURL)
            frame.photoPath = "frames/\(frame.date.timeIntervalSince1970).jpg"
        } else {
            if let path = frame.photoPath {
                PhotoManager.deletePhoto(at: path)
            }
            frame.photoPath = nil
        }

        try? context.save()
        dismiss()
    }
}
