import SwiftUI

/// Global app state
@MainActor
@Observable
final class NavigationState {
    var path = NavigationPath()

    func handleDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let host = components.host else { return }
        switch host {
        case "open-today-frame":
            let currentYear = Calendar.current.component(.year, from: .now)
            path.append(AppRoute.reel(year: currentYear))
        default:
            break
        }
    }
}

enum AppRoute: Hashable {
    case reel(year: Int)
    case frame(year: Int, date: Date)
    case ring(year: Int)
    case settings
}

// iOS 18 @Entry syntax
extension EnvironmentValues {
    @Entry var navigationState = NavigationState()
}
