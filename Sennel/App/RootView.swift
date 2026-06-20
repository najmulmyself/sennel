import SwiftUI
import SwiftData

struct RootView: View {
    @Query private var settings: [UserSettings]

    var body: some View {
        if let settings = settings.first {
            HomeView(settings: settings)
        } else {
            OnboardingView()
        }
    }
}
