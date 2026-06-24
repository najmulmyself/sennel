import SwiftUI

/// Step 1: capture when the user last used a pouch, via quick-select chips or a picker sheet.
struct LastPouchStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var showTimePicker = false
    @State private var showEarlierPicker = false

    var body: some View {
        VStack(spacing: 0) {
            OnboardingStepHeading(
                eyebrow: "Step 1 of 2",
                headline: "When did you last use a pouch?",
                subtitle: "Your streak starts from this moment."
            )

            Spacer(minLength: Spacing.xl)

            HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                Text(heroTime.number)
                    .font(.heroNumber(size: 96))
                    .foregroundStyle(.white)
                if !heroTime.suffix.isEmpty {
                    Text(heroTime.suffix)
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)

            Spacer(minLength: Spacing.lg)

            HStack(spacing: Spacing.sm) {
                OnboardingChip(title: "Just now", isSelected: viewModel.selection == .justNow) {
                    viewModel.selectJustNow()
                }
                OnboardingChip(title: specificTimeLabel, isSelected: viewModel.selection == .specificTime) {
                    showTimePicker = true
                }
                OnboardingChip(title: "Earlier", isSelected: viewModel.selection == .earlier) {
                    showEarlierPicker = true
                }
            }

            Spacer(minLength: Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .sheet(isPresented: $showTimePicker) {
            OnboardingDatePickerSheet(date: viewModel.lastPouchTime, components: [.hourAndMinute]) { date in
                viewModel.selectSpecificTime(date)
            }
        }
        .sheet(isPresented: $showEarlierPicker) {
            OnboardingDatePickerSheet(date: viewModel.lastPouchTime, components: [.date, .hourAndMinute]) { date in
                viewModel.selectEarlier(date)
            }
        }
    }

    /// The hero clock — the time-of-day number ("2:30") split from its meridiem ("PM"),
    /// so the suffix can render smaller and baseline-aligned per the design.
    private var heroTime: (number: String, suffix: String) {
        let formatted = viewModel.lastPouchTime.formatted(date: .omitted, time: .shortened)
        let parts = formatted.split(separator: " ", maxSplits: 1).map(String.init)
        if parts.count == 2 {
            return (parts[0], parts[1])
        }
        return (formatted, "")
    }

    private var specificTimeLabel: String {
        viewModel.lastPouchTime.formatted(date: .omitted, time: .shortened)
    }
}

/// Capsule quick-select control — solid white when selected, translucent otherwise.
/// Hugs its content (no stretch), so the row centers as a group beneath the hero.
private struct OnboardingChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isSelected ? Color.black : Color.white)
                .lineLimit(1)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(
                    Capsule().fill(isSelected ? Color.white : Color.white.opacity(0.15))
                )
                .overlay(
                    Capsule().strokeBorder(Color.white.opacity(isSelected ? 0 : 0.25), lineWidth: 1)
                )
        }
    }
}

/// Wheel-style date/time picker sheet used by the "specific time" and "earlier" chips.
private struct OnboardingDatePickerSheet: View {
    @State var date: Date
    let components: DatePickerComponents
    let onConfirm: (Date) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            DatePicker("Last pouch", selection: $date, displayedComponents: components)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding(Spacing.md)
                .navigationTitle("Last Pouch")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            onConfirm(date)
                            dismiss()
                        }
                    }
                }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    LastPouchStepView(viewModel: OnboardingViewModel())
        .padding(Spacing.md)
        .background(LinearGradient(colors: [.onboardingGradientTop, .onboardingGradientBottom], startPoint: .top, endPoint: .bottom))
}
