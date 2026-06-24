import SwiftUI

/// 2-screen flow only, per PRD §7: last pouch time, then daily goal.
/// Full-bleed gradient chrome + slide/crossfade transition per design doc §7 & §10.
struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel = OnboardingViewModel()

    var body: some View {
        ZStack {
            OnboardingBackground()

            VStack(spacing: Spacing.xl) {
                OnboardingHeaderBar(
                    currentStep: viewModel.step,
                    totalSteps: viewModel.totalSteps,
                    onReset: { viewModel.resetCurrentStep() }
                )

                Group {
                    if viewModel.step == 0 {
                        LastPouchStepView(viewModel: viewModel)
                    } else {
                        DailyGoalStepView(viewModel: viewModel)
                    }
                }
                .id(viewModel.step)
                .transition(stepTransition)

                Spacer()

                OnboardingPrimaryButton(title: viewModel.step == 0 ? "Continue" : "Start my streak") {
                    if viewModel.step == 0 {
                        viewModel.advance()
                    } else {
                        viewModel.completeOnboarding(modelContext: modelContext)
                        Task { await NotificationService.shared.requestPermissionIfNeeded() }
                    }
                }
            }
            .padding(Spacing.md)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: viewModel.step)
        }
    }

    private var stepTransition: AnyTransition {
        reduceMotion ? .opacity : .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
}

/// Full-bleed slate gradient — fixed regardless of system appearance (design doc §10).
private struct OnboardingBackground: View {
    var body: some View {
        LinearGradient(
            colors: [.onboardingGradientTop, .onboardingGradientBottom],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

/// Page dots + reset icon, top of the onboarding chrome.
private struct OnboardingHeaderBar: View {
    let currentStep: Int
    let totalSteps: Int
    let onReset: () -> Void

    var body: some View {
        HStack {
            HStack(spacing: Spacing.xs) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Capsule()
                        .fill(index == currentStep ? Color.white : Color.white.opacity(0.3))
                        .frame(width: index == currentStep ? 24 : 8, height: 8)
                }
            }

            Spacer()

            Button(action: onReset) {
                Image(systemName: "arrow.counterclockwise")
                    .foregroundStyle(.white.opacity(0.8))
            }
            .accessibilityLabel("Reset this step")
        }
    }
}

/// Eyebrow / headline / subtitle block shared by both onboarding steps.
struct OnboardingStepHeading: View {
    let eyebrow: String
    let headline: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(eyebrow.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.6))
            Text(headline)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.body)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Full-width white rounded CTA — bottom of both onboarding steps.
struct OnboardingPrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(Color.white, in: RoundedRectangle(cornerRadius: Radius.button))
        }
    }
}

#Preview {
    OnboardingView()
        .modelContainer(for: [UserSettings.self, PouchLog.self, RelapseEvent.self], inMemory: true)
}
