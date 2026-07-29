import SwiftUI

struct EditFrameSheet: View {
    let frame: FilmFrame
    @Environment(\.dismiss) private var dismiss
    @State private var note: String = ""
    @State private var hasPhoto: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            HandleBar()

            Text(frame.fullDate)
                .font(.headline)
                .fontWeight(.semibold)

            PhotoPickerView(hasPhoto: $hasPhoto)
                .frame(maxWidth: .infinity)
                .aspectRatio(4 / 3, contentMode: .fit)

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
                        .foregroundColor(.tertiary)
                }
            }

            HStack(spacing: 12) {
                Button("删除照片", role: .destructive) {
                    hasPhoto = false
                }
                .buttonStyle(.bordered)
                .tint(.red)

                Button("保存") {
                    save()
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
            }
        }
        .padding()
        .task {
            note = frame.note ?? ""
            hasPhoto = frame.isFilled
        }
    }

    private func save() {
        frame.note = note.isEmpty ? nil : note
        if !hasPhoto { frame.photoPath = nil }
        dismiss()
    }
}

// MARK: - Subviews
private struct HandleBar: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color(.systemGray4))
            .frame(width: 36, height: 4)
    }
}

private struct PhotoPickerView: View {
    @Binding var hasPhoto: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(hasPhoto ? Color.accentColor : Color(.systemGray4), style: StrokeStyle(lineWidth: hasPhoto ? 2 : 1.5, dash: hasPhoto ? [] : [6]))
            .overlay {
                if hasPhoto {
                    Color(.systemGray5)
                        .overlay(Image(systemName: "photo.fill").foregroundColor(.secondary))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.badge.plus")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("点击添加照片")
                            .font(.caption)
                            .foregroundColor(.tertiary)
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { hasPhoto.toggle() }
    }
}
