import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query private var settings: [AppSettings]
    @State private var showOnboarding = true

    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView(completion: {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showOnboarding = false
                    }
                })
                .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .task {
            checkOnboardingStatus()
        }
    }

    private func checkOnboardingStatus() {
        if let setting = settings.first, setting.onboardingCompleted {
            showOnboarding = false
        }
    }
}
