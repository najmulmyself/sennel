import SwiftUI

/// The relapse / restart flow (SennelRelapse.dc.html) — presented as a sheet. Per
/// sennel_design.md Section 14's "no shame-coded relapse UI" rule: no red, no streak
/// reset to zero shown, no badge loss. "This stays yours" reads from the lifetime
/// accumulators so a restart never erases what's already been earned.
struct RelapseView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var shieldUsedTrigger = false
    @State private var restartTrigger = false

    var body: some View {
        let theme = SennelTheme(dark: colorScheme == .dark, stage: appState.stage(at: .now))
        let accent = SennelTheme.brandTeal(dark: theme.dark)
        let soft = accent.opacity(theme.dark ? 0.14 : 0.09)
        let currentDays = appState.daysClean(at: .now)

        return ZStack {
            theme.background.ignoresSafeArea()

            VStack(spacing: SennelSpace.lg) {
                heading(theme: theme, accent: accent, soft: soft)
                shieldsCard(theme: theme)

                Spacer()

                statsCard(theme: theme, soft: soft)

                VStack(spacing: 11) {
                    Button {
                        shieldUsedTrigger.toggle()
                        appState.resolveRelapse(useShield: true)
                        dismiss()
                    } label: {
                        Text("Use a shield — keep my \(currentDays) days")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(theme.buttonText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(accent, in: RoundedRectangle(cornerRadius: SennelRadius.button, style: .continuous))
                            .shadow(color: soft, radius: 22, y: 8)
                    }
                    .buttonStyle(.plain)
                    .disabled(appState.streakShieldsRemaining == 0)
                    .opacity(appState.streakShieldsRemaining == 0 ? 0.5 : 1)

                    Button {
                        restartTrigger.toggle()
                        appState.resolveRelapse(useShield: false)
                        dismiss()
                    } label: {
                        Text("Restart, no judgment")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(theme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .overlay(RoundedRectangle(cornerRadius: SennelRadius.button, style: .continuous).strokeBorder(theme.hairline))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, SennelSpace.lg)
            .padding(.top, SennelSpace.xl)
            .padding(.bottom, SennelSpace.md)
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: shieldUsedTrigger)
        .sensoryFeedback(.impact(weight: .light), trigger: restartTrigger)
    }

    // MARK: Heading

    private func heading(theme: SennelTheme, accent: Color, soft: Color) -> some View {
        VStack(spacing: 16) {
            Circle()
                .fill(soft)
                .frame(width: 72, height: 72)
                .overlay(
                    Image(systemName: "heart")
                        .font(.system(size: 30, weight: .regular))
                        .foregroundStyle(accent)
                )
                .accessibilityHidden(true)

            VStack(spacing: 10) {
                Text("It's okay. You're\nstill moving forward.")
                    .font(.title.weight(.bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(theme.textPrimary)
                Text("A slip isn't a failure. Everything you've built so far stays yours.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(theme.textSecondary)
                    .frame(maxWidth: 300)
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Shields

    private func shieldsCard(theme: SennelTheme) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("STREAK SHIELDS")
                    .font(.caption.weight(.semibold))
                    .kerning(1.0)
                    .foregroundStyle(theme.textSecondary)
                Text("Protect your streak — \(appState.streakShieldsRemaining) left this month")
                    .font(.subheadline)
                    .foregroundStyle(theme.textSecondary)
            }
            Spacer()
            HStack(spacing: 7) {
                ForEach(0..<appState.streakShieldsTotal, id: \.self) { index in
                    Image(systemName: "shield.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(index < appState.streakShieldsRemaining ? SennelTheme.accentShield : theme.textSecondary.opacity(0.5))
                }
            }
        }
        .padding(SennelSpace.md)
        .background(theme.card)
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(theme.hairline))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    // MARK: Stats

    private func statsCard(theme: SennelTheme, soft: Color) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            Text("THIS STAYS YOURS")
                .font(.caption.weight(.semibold))
                .kerning(1.0)
                .foregroundStyle(theme.textSecondary)

            HStack {
                statColumn(theme: theme, value: "\(appState.lifetimeDaysClean(at: .now))", label: "days logged")
                Spacer()
                statColumn(theme: theme, value: "$\(Int(appState.lifetimeMoneySaved(at: .now)))", label: "saved")
                Spacer()
                statColumn(theme: theme, value: "\(appState.earnedBadges(at: .now).count)", label: "badges")
            }
        }
        .padding(SennelSpace.md)
        .background(soft, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func statColumn(theme: SennelTheme, value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HeroNumber(value, baseSize: 26)
                .foregroundStyle(theme.textPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(theme.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    RelapseView()
        .environment(AppState())
}
