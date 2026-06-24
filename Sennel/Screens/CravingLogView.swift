import SwiftUI

/// The craving logger (SennelCraving.dc.html) — presented as a sheet from Home.
/// Intensity is a 5-level meter rather than a free slider, matching the prototype's
/// discrete bar chart exactly.
struct CravingLogView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var intensity = 3
    @State private var selectedTrigger: String?
    @State private var outcome: AppState.CravingEntry.Outcome?

    private let barHeights: [CGFloat] = [0.34, 0.52, 0.72, 0.90, 1.0]
    private let timeRanges = ["12–4 AM", "4–8 AM", "8 AM–12 PM", "12–4 PM", "4–8 PM", "8 PM–12 AM"]

    private var canSave: Bool { selectedTrigger != nil && outcome != nil }

    var body: some View {
        let theme = SennelTheme(dark: colorScheme == .dark, stage: appState.stage(at: .now))
        let accent = SennelTheme.brandTeal(dark: theme.dark)

        ZStack {
            theme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: SennelSpace.lg) {
                header(theme: theme)
                intensityCard(theme: theme, accent: accent)
                triggerSection(theme: theme, accent: accent)
                outcomeSection(theme: theme, accent: accent)

                Spacer()

                insightBanner(theme: theme, accent: accent)

                Button {
                    appState.logCraving(intensity: intensity, trigger: selectedTrigger ?? "", outcome: outcome ?? .rodeItOut)
                    dismiss()
                } label: {
                    Text("Save craving")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(theme.buttonText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(accent, in: RoundedRectangle(cornerRadius: SennelRadius.button, style: .continuous))
                        .shadow(color: accent.opacity(theme.dark ? 0.22 : 0.16), radius: 22, y: 8)
                }
                .buttonStyle(.plain)
                .disabled(!canSave)
                .opacity(canSave ? 1 : 0.5)
            }
            .padding(.horizontal, SennelSpace.lg)
            .padding(.top, SennelSpace.lg)
            .padding(.bottom, SennelSpace.md)
        }
    }

    // MARK: Header

    private func header(theme: SennelTheme) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Log a craving")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(theme.textPrimary)
                Text("No judgment — just noticing.")
                    .font(.subheadline)
                    .foregroundStyle(theme.textSecondary)
            }
            Spacer()
            Button("Cancel") { dismiss() }
                .font(.body.weight(.semibold))
                .foregroundStyle(theme.stageColor)
        }
    }

    // MARK: Intensity

    private func intensityCard(theme: SennelTheme, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .lastTextBaseline) {
                Text("INTENSITY")
                    .font(.caption.weight(.semibold))
                    .kerning(1.2)
                    .foregroundStyle(theme.textSecondary)
                Spacer()
                Text(appState.cravingIntensityLabel(intensity))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(accent)
            }

            HStack(alignment: .bottom, spacing: 10) {
                ForEach(1...5, id: \.self) { level in
                    Button {
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.15)) { intensity = level }
                    } label: {
                        VStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(level <= intensity ? accent : theme.track)
                                .frame(height: 64 * barHeights[level - 1])
                            Text("\(level)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(level == intensity ? accent : theme.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 64, alignment: .bottom)
        }
        .padding(SennelSpace.md)
        .background(theme.card)
        .overlay(RoundedRectangle(cornerRadius: SennelRadius.card, style: .continuous).strokeBorder(theme.hairline))
        .clipShape(RoundedRectangle(cornerRadius: SennelRadius.card, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Intensity")
        .accessibilityValue(appState.cravingIntensityLabel(intensity))
        .accessibilityAdjustableAction { direction in
            if direction == .increment, intensity < 5 { intensity += 1 }
            if direction == .decrement, intensity > 1 { intensity -= 1 }
        }
    }

    // MARK: Trigger

    private func triggerSection(theme: SennelTheme, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            Text("WHAT TRIGGERED IT?")
                .font(.caption.weight(.semibold))
                .kerning(1.2)
                .foregroundStyle(theme.textSecondary)

            FlowLayout(spacing: 9) {
                ForEach(AppState.cravingTriggers, id: \.self) { trigger in
                    let selected = selectedTrigger == trigger
                    Button {
                        selectedTrigger = trigger
                    } label: {
                        Text(trigger)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .foregroundStyle(selected ? theme.buttonText : theme.textSecondary)
                            .background(Capsule().fill(selected ? accent : Color.clear))
                            .overlay(Capsule().strokeBorder(selected ? Color.clear : theme.hairline))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
        }
    }

    // MARK: Outcome

    private func outcomeSection(theme: SennelTheme, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            Text("WHAT HAPPENED?")
                .font(.caption.weight(.semibold))
                .kerning(1.2)
                .foregroundStyle(theme.textSecondary)

            HStack(spacing: 10) {
                outcomeButton(title: "I rode it out", value: .rodeItOut, filled: true, theme: theme, accent: accent)
                outcomeButton(title: "I used one", value: .used, filled: false, theme: theme, accent: accent)
            }
        }
    }

    private func outcomeButton(title: String, value: AppState.CravingEntry.Outcome, filled: Bool, theme: SennelTheme, accent: Color) -> some View {
        let selected = outcome == value
        return Button {
            outcome = value
        } label: {
            Text(title)
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .foregroundStyle(selected ? theme.buttonText : theme.textSecondary)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(selected ? accent : Color.clear))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(selected ? Color.clear : theme.hairline))
                .shadow(color: selected ? accent.opacity(theme.dark ? 0.22 : 0.16) : .clear, radius: 16, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: Insight banner

    private func insightBanner(theme: SennelTheme, accent: Color) -> some View {
        let buckets = appState.cravingsByTimeOfDay(at: .now)
        let peakRange = buckets.enumerated().max(by: { $0.element.count < $1.element.count })
            .map { timeRanges[$0.offset] } ?? "the afternoon"

        return HStack(spacing: 12) {
            Image(systemName: "scope")
                .font(.system(size: 18))
                .foregroundStyle(accent)
            Text("Most of your cravings hit around **\(peakRange)**. They usually pass in under 5 minutes.")
                .font(.subheadline)
                .foregroundStyle(theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(SennelSpace.md)
        .background(accent.opacity(theme.dark ? 0.16 : 0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

#Preview {
    CravingLogView()
        .environment(AppState())
}
