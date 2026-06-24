import SwiftUI

/// Switches between the 2-question onboarding and the real app shell based on
/// `AppState.hasOnboarded` — the only piece of navigation that lives above the tab bar.
struct RootView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if appState.hasOnboarded {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.4), value: appState.hasOnboarded)
    }
}

#Preview {
    RootView()
        .environment(AppState())
}
