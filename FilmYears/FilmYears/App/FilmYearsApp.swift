import SwiftUI
import SwiftData
import UIKit

@main
struct FilmYearsApp: App {
    let persistenceController = PersistenceController.shared

    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        UINavigationBar.appearance().tintColor = UIColor(Color.textSecondary)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(persistenceController.container)
    }
}
