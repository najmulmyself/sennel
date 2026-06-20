import SwiftUI

/// Step 1: capture when the user last used a pouch, via quick-select chips or a picker sheet.
struct LastPouchStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var showTimePicker = false
    @State private var showEarlierPicker = false

    var body: some View {
        VStack(spacing: Spacing.xl) {
            OnboardingStepHeading(
                eyebrow: "Step 1 of 2",
                headline: "When was your last pouch?",
                subtitle: "We'll use this to start your streak clock."
            )

            Text(timeLabel)
                .font(.heroNumber(size: 48))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.lg)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

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
        }
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

    private var timeLabel: String {
        switch viewModel.selection {
        case .justNow:
            return "Just now"
        case .specificTime:
            return viewModel.lastPouchTime.formatted(date: .omitted, time: .shortened)
        case .earlier:
            return viewModel.lastPouchTime.formatted(date: .abbreviated, time: .shortened)
        }
    }

    private var specificTimeLabel: String {
        viewModel.lastPouchTime.formatted(date: .omitted, time: .shortened)
    }
}

/// Capsule quick-select control — solid white when selected, translucent otherwise.
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
                .minimumScaleFactor(0.8)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .frame(maxWidth: .infinity)
                .background(
                    Capsule().fill(isSelected ? Color.white : Color.white.opacity(0.15))
                )
                .overlay(
                    Capsule().strokeBorder(Color.white.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
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
