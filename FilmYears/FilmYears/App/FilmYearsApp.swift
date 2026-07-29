import SwiftUI
import SwiftData

@main
struct FilmYearsApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(persistenceController.container)
    }
}
