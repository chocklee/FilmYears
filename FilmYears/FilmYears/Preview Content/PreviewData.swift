import SwiftData
import Foundation

enum PreviewData {
    @MainActor
    static func inject(into context: ModelContext) throws {
        let calendar = Calendar.current
        guard let birthDate = calendar.date(from: DateComponents(year: 1995, month: 6, day: 15)) else {
            throw PreviewError.invalidDate
        }

        let settings = AppSettings(birthDate: birthDate)
        settings.onboardingCompleted = true
        context.insert(settings)

        let years = [2024, 2025, 2026]
        let sampleNotes = ["日落时分的天空", "和 old friend 喝了咖啡",
                           "今天跑了 5km", "读完了一本书", "海边散步"]

        for year in years {
            let roll = FilmRoll(year: year)
            context.insert(roll)

            guard let startDate = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
                  let endDate = calendar.date(from: DateComponents(year: year, month: 12, day: 31)) else {
                throw PreviewError.invalidDate
            }

            var currentDate = startDate
            while currentDate <= endDate {
                let frame = FilmFrame(date: currentDate)
                frame.roll = roll

                if currentDate.day % 5 == 0 {
                    frame.photoPath = "preview/\(year)/\(currentDate.day).jpg"
                    frame.note = sampleNotes.randomElement()
                }

                context.insert(frame)
                guard let next = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                    throw PreviewError.invalidDate
                }
                currentDate = next
            }
            roll.isInitialized = true
        }
        try context.save()
    }
}

enum PreviewError: Error {
    case invalidDate
}

fileprivate extension Date {
    var day: Int {
        Calendar.current.component(.day, from: self)
    }
}
