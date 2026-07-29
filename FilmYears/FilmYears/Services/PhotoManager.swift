import UIKit

/// Photo operations using local file storage
enum PhotoManager {
    nonisolated static let documentsDir: URL = {
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Cannot access document directory")
        }
        return url.appendingPathComponent("frames", isDirectory: true)
    }()

    @MainActor
    static func savePhoto(_ image: UIImage, for date: Date) throws -> String {
        try FileManager.default.createDirectory(at: documentsDir, withIntermediateDirectories: true)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let filename = formatter.string(from: date) + ".jpg"
        let fileURL = documentsDir.appendingPathComponent(filename)
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw PhotoError.compressionFailed
        }
        try data.write(to: fileURL)
        return "frames/" + filename
    }

    @MainActor
    static func loadPhoto(at path: String) -> UIImage? {
        let fileURL = documentsDir.deletingLastPathComponent().appendingPathComponent(path)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    static func deletePhoto(at path: String) {
        let fileURL = documentsDir.deletingLastPathComponent().appendingPathComponent(path)
        try? FileManager.default.removeItem(at: fileURL)
    }

    enum PhotoError: Error {
        case compressionFailed
        case fileNotFound
    }
}
