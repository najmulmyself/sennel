import SwiftUI

/// Step 2: set the daily pouch goal via a circular stepper around a hero number.
struct DailyGoalStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            OnboardingStepHeading(
                eyebrow: "Step 2 of 2",
                headline: "What's your daily goal to start?",
                subtitle: "Reduce gradually — you can change this anytime."
            )

            Spacer(minLength: Spacing.xl)

            VStack(spacing: Spacing.md) {
                HStack(spacing: Spacing.lg) {
                    OnboardingStepperButton(symbolName: "minus", isProminent: false) {
                        viewModel.decrementDailyGoal()
                    }
                    .accessibilityLabel("Decrease daily goal")

                    Text("\(viewModel.dailyGoal)")
                        .font(.heroNumber(size: 84))
                        .foregroundStyle(.white)
                        .frame(minWidth: 100)
                        .lineLimit(1)

                    OnboardingStepperButton(symbolName: "plus", isProminent: true) {
                        viewModel.incrementDailyGoal()
                    }
                    .accessibilityLabel("Increase daily goal")
                }

                Text("pouches per day")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer(minLength: Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
                .frame(width: 64, height: 64)
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
