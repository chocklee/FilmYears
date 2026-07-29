import SwiftUI
import SwiftData

@main
struct FilmYearsApp: App {
    let persistenceController = PersistenceController.shared

    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backButtonAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Color.textSecondary)
        ]
        UINavigationBar.appearance().tintColor = UIColor(Color.textSecondary)
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(persistenceController.container)
    }
}
