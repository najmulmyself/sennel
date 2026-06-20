import SwiftUI

/// Step 2: set the daily pouch goal via a circular stepper around a hero number.
struct DailyGoalStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: Spacing.xl) {
            OnboardingStepHeading(
                eyebrow: "Step 2 of 2",
                headline: "What's your daily goal?",
                subtitle: "Set a target to taper down to."
            )

            HStack(spacing: Spacing.xl) {
                OnboardingStepperButton(symbolName: "minus", isProminent: false) {
                    viewModel.decrementDailyGoal()
                }
                .accessibilityLabel("Decrease daily goal")

                VStack(spacing: Spacing.xs) {
                    Text("\(viewModel.dailyGoal)")
                        .font(.heroNumber(size: 64))
                        .foregroundStyle(.white)
                    Text("pouches / day")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .frame(minWidth: 120)

                OnboardingStepperButton(symbolName: "plus", isProminent: true) {
                    viewModel.incrementDailyGoal()
                }
                .accessibilityLabel("Increase daily goal")
            }
        }
    }
}

/// Circular +/- control — muted for decrement, solid white for increment.
private struct OnboardingStepperButton: View {
    let symbolName: String
    let isProminent: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbolName)
                .font(.title2.weight(.semibold))
                .foregroundStyle(isProminent ? Color.black : Color.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle().fill(isProminent ? Color.white : Color.white.opacity(0.15))
                )
        }
    }
}

#Preview {
    DailyGoalStepView(viewModel: OnboardingViewModel())
        .padding(Spacing.md)
        .background(LinearGradient(colors: [.onboardingGradientTop, .onboardingGradientBottom], startPoint: .top, endPoint: .bottom))
}
