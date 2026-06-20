import SwiftUI
import SwiftData

/// The PRD's "first 30 seconds" screen — proof-of-value on cold launch.
/// Structural scaffold only; streak ring, glass hero card, and motion land in the UI pass.
struct HomeView: View {
    let settings: UserSettings

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HomeViewModel?

    var body: some View {
        VStack(spacing: Spacing.lg) {
            if let viewModel {
                StreakRingView(progress: 1, stage: viewModel.streakStage)
                    .frame(width: 160, height: 160)

                Text("\(viewModel.currentStreakDays)")
                    .font(.heroNumber(size: 72))
                Text("days clean")
                    .font(.body)
                    .foregroundStyle(.secondary)

                Text(viewModel.moneySaved, format: .currency(code: "USD"))
                    .font(.headline)

                Button("I just used a pouch") {
                    viewModel.logPouch()
                }
                .buttonStyle(.borderedProminent)

                Button("Log a relapse", role: .destructive) {
                    viewModel.logRelapse()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(Spacing.md)
        .onAppear {
            if viewModel == nil {
                viewModel = HomeViewModel(modelContext: modelContext, settings: settings)
            }
        }
    }
}
