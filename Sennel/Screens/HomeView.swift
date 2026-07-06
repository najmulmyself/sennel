import SwiftUI

/// Home screen — variant 1b "Typographic" (Home Variants.dc.html#1b).
/// The giant day count IS the interface — no ring hero card. Stage colour
/// surfaces through the slim gradient progress bar and the accent money figure.
/// Dark mode mirrors the same structure using dark-mode design-system tokens.
struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var onSettingsTap: () -> Void = {}

    @State private var activeSheet: ActiveSheet?
    @ScaledMetric private var heroSize: CGFloat = 190

    private enum ActiveSheet: Identifiable {
        case craving, breathing, relapse, badges
        var id: Self { self }
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            content(date: context.date)
        }
    }

    private func content(date: Date) -> some View {
        let stage = appState.stage(at: date)
        let theme = SennelTheme(dark: colorScheme == .dark, stage: stage)
        let accent = SennelTheme.brandTeal(dark: theme.dark)
        let days = appState.daysClean(at: date)
        let progress = appState.stageProgress(at: date)

        return ZStack {
            theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar(theme: theme, accent: accent)
                    .padding(.horizontal, SennelSpace.lg)

                Spacer(minLength: SennelSpace.xl)

                heroSection(theme: theme, accent: accent, date: date, days: days, progress: progress, stage: stage)
                    .padding(.horizontal, 28)

                Spacer(minLength: SennelSpace.lg)

                bottomSection(theme: theme, accent: accent, date: date)
                    .padding(.horizontal, SennelSpace.lg)
                    .padding(.bottom, SennelSpace.lg)
            }
            .padding(.top, SennelSpace.lg)
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .craving: CravingLogView()
            case .breathing: BreathingView()
            case .relapse: RelapseView()
            case .badges: BadgesView()
            }
        }
    }

    // MARK: Top bar

    private func topBar(theme: SennelTheme, accent: Color) -> some View {
        HStack {
            Text(appState.stage(at: .now).label.uppercased())
                .font(.caption.weight(.semibold))
                .kerning(1.8)
                .foregroundStyle(accent)
            Spacer()
            Button { activeSheet = .badges } label: {
                Image(systemName: "rosette")
                    .foregroundStyle(theme.textSecondary)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(theme.card))
                    .overlay(Circle().strokeBorder(theme.hairline))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Milestones")
            Button(action: onSettingsTap) {
                Image(systemName: "gearshape.fill")
                    .foregroundStyle(theme.textSecondary)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(theme.card))
                    .overlay(Circle().strokeBorder(theme.hairline))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
    }

    // MARK: Hero section

    private func heroSection(theme: SennelTheme, accent: Color, date: Date, days: Int, progress: Double, stage: SennelStage) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(days)")
                .font(.system(size: heroSize, weight: .black, design: .rounded))
                .foregroundStyle(theme.textPrimary)
                .minimumScaleFactor(0.3)
                .lineLimit(1)
                .contentTransition(.numericText())
                .accessibilityLabel("Streak, day \(days)")

            (Text("days clean · ").foregroundStyle(theme.textSecondary)
                + Text(appState.money(at: date)).foregroundStyle(accent).fontWeight(.semibold)
                + Text(" saved").foregroundStyle(theme.textSecondary))
                .font(.title3)
                .accessibilityHidden(true)

            Text(appState.clock(at: date))
                .font(.subheadline)
                .foregroundStyle(theme.textTertiary)
                .monospacedDigit()
                .accessibilityHidden(true)

            progressStrip(theme: theme, accent: accent, progress: progress, stage: stage)
                .padding(.top, 24)
        }
    }

    private func progressStrip(theme: SennelTheme, accent: Color, progress: Double, stage: SennelStage) -> some View {
        let pct = Int(progress * 100)

        return VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(theme.track)
                    Capsule()
                        .fill(LinearGradient(
                            colors: [SennelTheme.accentLock, accent],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: max(4, geo.size.width * min(1, progress)))
                        .animation(reduceMotion ? nil : .easeOut(duration: 0.45), value: progress)
                }
            }
            .frame(height: 4)
            .frame(maxWidth: 280)

            Text("\(pct)% of the way to \(nextMilestoneLabel(for: stage))")
                .font(.caption)
                .foregroundStyle(theme.textTertiary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(pct) percent to \(nextMilestoneLabel(for: stage))")
    }

    private func nextMilestoneLabel(for stage: SennelStage) -> String {
        switch stage {
        case .slate:   return "3 days"
        case .teal3:   return "8 days"
        case .teal4:   return "one month"
        case .emerald: return "3 months"
        }
    }

    // MARK: Bottom section

    private func bottomSection(theme: SennelTheme, accent: Color, date: Date) -> some View {
        VStack(spacing: 12) {
            todayRow(theme: theme, accent: accent, date: date)

            Button { appState.logPouch() } label: {
                Text("I just used a pouch")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(theme.buttonText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        theme.textPrimary,
                        in: RoundedRectangle(cornerRadius: SennelRadius.button, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.impact(weight: .light), trigger: appState.usedToday)

            quickActionsRow(theme: theme)
            slipLink(theme: theme)
        }
    }

    private func todayRow(theme: SennelTheme, accent: Color, date: Date) -> some View {
        let todayText = Text("Today: ").foregroundStyle(theme.textSecondary)
            + Text("\(appState.usedToday) of \(appState.dailyLimit)")
                .foregroundStyle(theme.textPrimary).fontWeight(.semibold)

        return HStack {
            todayText
            Spacer()
            if let next = appState.nextEligibleSlot(at: date) {
                Text("Next at ").foregroundStyle(theme.textSecondary)
                    + Text(next, format: .dateTime.hour().minute())
                        .foregroundStyle(accent).fontWeight(.semibold)
            } else {
                Text("Goal reached")
                    .foregroundStyle(accent)
                    .fontWeight(.semibold)
            }
        }
        .font(.subheadline)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Today \(appState.usedToday) of \(appState.dailyLimit) pouches used")
    }

    // MARK: Quick actions

    private func quickActionsRow(theme: SennelTheme) -> some View {
        HStack(spacing: SennelSpace.sm) {
            quickActionButton(icon: "waveform.path.ecg", title: "Log craving", theme: theme) {
                activeSheet = .craving
            }
            quickActionButton(icon: "wind", title: "Breathe", theme: theme) {
                activeSheet = .breathing
            }
        }
    }

    private func quickActionButton(icon: String, title: String, theme: SennelTheme, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .accessibilityHidden(true)
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(theme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(theme.card)
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(theme.hairline))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: Had a slip

    private func slipLink(theme: SennelTheme) -> some View {
        Button("Had a slip?") { activeSheet = .relapse }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(theme.textSecondary)
    }
}

#Preview {
    HomeView()
        .environment(AppState())
}
