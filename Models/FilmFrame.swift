import SwiftData
import Foundation

@Model
final class FilmFrame {
    @Attribute(.unique) var date: Date
    var photoPath: String?
    var note: String?
    var photoModifiedAt: Date?

    var focusActive: Bool?
    var screenTimeScore: Double?

    @Relationship(inverse: \FilmRoll.frames) var roll: FilmRoll?

    init(date: Date) {
        self.date = date
    }
}

extension FilmFrame {
    var isFilled: Bool { photoPath != nil }

    var displayDate: String {
        let df = DateFormatter()
        df.dateFormat = "MM/dd EEE"
        df.locale = Locale(identifier: "zh_CN")
        return df.string(from: date)
    }

    var fullDate: String {
        let df = DateFormatter()
        df.dateFormat = "yyyy年M月d日"
        df.locale = Locale(identifier: "zh_CN")
        return df.string(from: date)
    }
}
