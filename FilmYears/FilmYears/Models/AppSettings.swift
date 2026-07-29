import SwiftData
import Foundation

@Model
final class AppSettings {
    var id: String = "app_settings"

    var birthDate: Date
    var onboardingCompleted: Bool
    var firstLaunchDate: Date
    var isCloudSyncEnabled: Bool = true

    init(birthDate: Date) {
        self.birthDate = birthDate
        self.onboardingCompleted = false
        self.firstLaunchDate = .now
    }
}

extension AppSettings {
    var birthYear: Int {
        Calendar.current.component(.year, from: birthDate)
    }

    static var currentYear: Int {
        Calendar.current.component(.year, from: .now)
    }
}
