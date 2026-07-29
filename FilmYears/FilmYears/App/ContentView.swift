import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var settings: [AppSettings]
    @State private var showOnboarding = true

    private var onboardingCompleted: Bool {
        settings.first?.onboardingCompleted ?? false
    }

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
        .onChange(of: onboardingCompleted) { _, completed in
            if completed { showOnboarding = false }
        }
        .onAppear {
            if onboardingCompleted { showOnboarding = false }
        }
    }
}
