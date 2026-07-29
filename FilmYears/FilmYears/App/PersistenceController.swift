import SwiftData
import Foundation

@MainActor
struct PersistenceController {
    static let shared = PersistenceController()

    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        Task { @MainActor in
            try? PreviewData.inject(into: result.container.mainContext)
        }
        return result
    }()

    let container: ModelContainer

    init(inMemory: Bool = false) {
        let schema = Schema([
            FilmRoll.self,
            FilmFrame.self,
            AppSettings.self
        ])

        let config: ModelConfiguration
        if inMemory {
            config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        } else {
            config = ModelConfiguration(
                schema: schema,
                groupContainer: .identifier("group.com.yourcompany.filmyears"),
                cloudKitDatabase: .private("iCloud.com.yourcompany.filmyears")
            )
        }

        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }

    func makeBackgroundActor() -> FilmRollActor {
        FilmRollActor(modelContainer: container)
    }
}

@ModelActor
actor FilmRollActor {
    func insertInitialRolls(from birthDate: Date, to endDate: Date) throws {
        let calendar = Calendar.current
        let birthYear = calendar.component(.year, from: birthDate)
        let endYear = calendar.component(.year, from: endDate)

        for year in birthYear ... endYear {
            let roll = FilmRoll(year: year)
            modelContext.insert(roll)

            let yearStart: Date = year == birthYear
                ? birthDate
                : calendar.date(from: DateComponents(year: year, month: 1, day: 1))!

            let yearEnd: Date = year == endYear
                ? endDate
                : calendar.date(from: DateComponents(year: year, month: 12, day: 31))!

            var currentDate = yearStart
            while currentDate <= yearEnd {
                let frame = FilmFrame(date: currentDate)
                frame.roll = roll
                modelContext.insert(frame)
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            }
            roll.isInitialized = true
        }
        try modelContext.save()
    }

    func ensureTodayFrame() throws {
        let today = Calendar.current.startOfDay(for: .now)
        let currentYear = Calendar.current.component(.year, from: today)

        let predicate = #Predicate<FilmFrame> { frame in
            frame.date >= today
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        guard try modelContext.fetch(descriptor).isEmpty else { return }

        let yearPredicate = #Predicate<FilmRoll> { $0.year == currentYear }
        let yearDescriptor = FetchDescriptor(predicate: yearPredicate)
        let rolls = try modelContext.fetch(yearDescriptor)

        let roll: FilmRoll
        if let existingRoll = rolls.first {
            roll = existingRoll
        } else {
            roll = FilmRoll(year: currentYear)
            modelContext.insert(roll)
        }

        let frame = FilmFrame(date: today)
        frame.roll = roll
        modelContext.insert(frame)
        try modelContext.save()
    }
}
