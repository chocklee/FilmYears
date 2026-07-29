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
    @State private var originalNote: String = ""
    @State private var originalHasPhoto: Bool = false
    @State private var originalPhotoData: Data? = nil

    private var previewImage: UIImage? {
        guard let data = photoData else { return nil }
        return UIImage(data: data)
    }

    private var hasChanges: Bool {
        note != originalNote || hasPhoto != originalHasPhoto || photoData != originalPhotoData
    }

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(hex: "#353534"))
                .frame(width: 48, height: 6)
                .padding(.top, 16)

            // Date title
            Text(frame.fullDate)
                .font(.system(size: 28, weight: .regular))
                .foregroundColor(.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 16)

            // Photo picker area
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.bgPrimary)
                        .frame(height: 218)

                    if hasPhoto, let image = previewImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: 218)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        VStack(spacing: 8) {
                            Image("PhotoPlaceholder")
                                .resizable()
                                .frame(width: 33, height: 30)
                            Text("点击添加照片")
                                .font(.system(size: 13))
                                .foregroundColor(.textTertiary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            hasPhoto ? Color.clear : Color(hex: "#4F4537"),
                            style: StrokeStyle(lineWidth: 2, dash: [4])
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
            .padding(24)

            // Note input
            VStack(spacing: 8) {
                TextField("添加一行备注（最多 80 字符）", text: $note, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16))
                    .foregroundColor(Color.textPrimary)
                    .padding(16)
                    .frame(height: 100, alignment: .top)
                    .background(Color.bgPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "#4F4537"), lineWidth: 1)
                    )
                    .onChange(of: note) { _, newValue in
                        if newValue.count > 80 { note = String(newValue.prefix(80)) }
                    }

                HStack {
                    Spacer()
                    Text("\(note.count)/80")
                        .font(.system(size: 13))
                        .foregroundColor(.textTertiary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)

            // Action buttons
            HStack(spacing: 16) {
                Button(action: {
                    hasPhoto = false
                    photoData = nil
                    selectedPhoto = nil
                }) {
                    Text("删除照片")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(hasPhoto ? Color(hex: "#E74C3C") : Color(hex: "#E74C3C").opacity(0.3))
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Color(hex: "#131313"))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    hasPhoto ? Color(hex: "#E74C3C").opacity(0.3) : Color(hex: "#E74C3C").opacity(0.1),
                                    lineWidth: 1
                                )
                        )
                }
                .disabled(!hasPhoto)

                Button(action: saveFrame) {
                    Text("保存")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(hasChanges ? .black : .black.opacity(0.3))
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(hasChanges ? Color.accentGold : Color.accentGold.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(!hasChanges)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.bgCardStrong)
        .ignoresSafeArea(.all, edges: .bottom)
        .task {
            note = frame.note ?? ""
            hasPhoto = frame.isFilled
            originalNote = note
            originalHasPhoto = hasPhoto
            if hasPhoto, let path = frame.photoPath {
                let data = try? Data(contentsOf: PhotoManager.documentsDir
                    .deletingLastPathComponent()
                    .appendingPathComponent(path))
                photoData = data
                originalPhotoData = data
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
