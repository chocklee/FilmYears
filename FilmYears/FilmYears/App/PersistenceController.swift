import SwiftData
import Foundation

@MainActor
struct PersistenceController {
    let container: ModelContainer

    static let shared: PersistenceController = {
        // Try primary config first, then in-memory fallback
        if let instance = try? PersistenceController() {
            return PersistenceController(container: instance.container)
        }
        // Fallback: in-memory using variadic init
        if let container = try? ModelContainer(for: FilmRoll.self, FilmFrame.self, AppSettings.self) {
            return PersistenceController(container: container)
        }
        // Last resort: empty in-memory container (data loss on restart)
        let single = Schema([FilmRoll.self])
        let config = ModelConfiguration(schema: single, isStoredInMemoryOnly: true)
        if let container = try? ModelContainer(for: single, configurations: [config]) {
            return PersistenceController(container: container)
        }
        // Absolute last resort: minimal in-memory container
        // If even this fails, SwiftData is broken on this system.
        let lastSchema = Schema([FilmRoll.self])
        let lastConfig = ModelConfiguration(schema: lastSchema, isStoredInMemoryOnly: true)
        do {
            let container = try ModelContainer(for: lastSchema, configurations: [lastConfig])
            return PersistenceController(container: container)
        } catch {
            // SwiftData is broken on this system (known simulator bug in iOS 26.5).
            // A valid ModelContainer cannot be created by any means.
            // App will show empty state and log the error.
            preconditionFailure("""
            ⚠️ SwiftData unavailable: \(error)
            This is a known simulator issue. To fix:
            1. Xcode -> Product -> Clean Build Folder
            2. Simulator -> Device -> Erase All Content and Settings
            3. Build and run again on a real device
            """)
        }
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
