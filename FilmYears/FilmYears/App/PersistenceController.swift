import SwiftData
import Foundation

@MainActor
struct PersistenceController {
    let container: ModelContainer

    static let shared: PersistenceController = {
        let schema = Schema([FilmRoll.self, FilmFrame.self, AppSettings.self])
        let instance = try? PersistenceController()
        let container: ModelContainer
        if let instance {
            container = instance.container
        } else {
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            guard let fallback = try? ModelContainer(for: schema, configurations: [config]) else {
                preconditionFailure("SwiftData: in-memory container creation failed")
            }
            container = fallback
        }
        return PersistenceController(container: container)
    }()

    static let preview: PersistenceController = {
        let schema = Schema([FilmRoll.self, FilmFrame.self, AppSettings.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        guard let container = try? ModelContainer(for: schema, configurations: [config]) else {
            preconditionFailure("SwiftData: preview container creation failed")
        }
        let instance = PersistenceController(container: container)
        Task { @MainActor in
            try? PreviewData.inject(into: instance.container.mainContext)
        }
        return instance
    }()

    private init(container: ModelContainer) {
        self.container = container
    }

    init(inMemory: Bool = false, cloudKitEnabled: Bool = false) throws {
        let schema = Schema([
            FilmRoll.self,
            FilmFrame.self,
            AppSettings.self
        ])

        let config: ModelConfiguration
        if inMemory {
            config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        } else if cloudKitEnabled {
            config = ModelConfiguration(
                schema: schema,
                cloudKitDatabase: .private("iCloud.com.chocklee.filmyears")
            )
        } else {
            config = ModelConfiguration(schema: schema)
        }

        container = try ModelContainer(for: schema, configurations: [config])
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

            let yearStartComponents = DateComponents(year: year, month: 1, day: 1)
            let yearStart: Date = year == birthYear
                ? birthDate
                : calendar.date(from: yearStartComponents) ?? birthDate

            let yearEndComponents = DateComponents(year: year, month: 12, day: 31)
            let yearEnd: Date = year == endYear
                ? endDate
                : calendar.date(from: yearEndComponents) ?? endDate

            var currentDate = yearStart
            while currentDate <= yearEnd {
                let frame = FilmFrame(date: currentDate)
                frame.roll = roll
                modelContext.insert(frame)
                guard let next = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
                currentDate = next
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
        guard let rolls = try? modelContext.fetch(yearDescriptor) else { return }

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
