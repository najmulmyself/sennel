import SwiftUI

/// 2-screen flow only, per PRD §7. No glass, slide+crossfade transition lands in the UI pass.
struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = OnboardingViewModel()

    var body: some View {
        VStack(spacing: Spacing.lg) {
            if viewModel.step == 0 {
                Text("When was your last pouch?")
                    .font(.headline)
                DatePicker("Last pouch", selection: $viewModel.lastPouchTime)
                    .labelsHidden()
                Button("Next") { viewModel.step = 1 }
                    .buttonStyle(.borderedProminent)
            } else {
                Text("What's your daily goal?")
                    .font(.headline)
                Stepper("\(viewModel.dailyGoal) pouches/day", value: $viewModel.dailyGoal, in: 1...30)
                Button("Get Started") {
                    viewModel.completeOnboarding(modelContext: modelContext)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(Spacing.md)
    }
}

#Preview {
    OnboardingView()
        .modelContainer(for: [UserSettings.self, PouchLog.self, RelapseEvent.self], inMemory: true)
}
