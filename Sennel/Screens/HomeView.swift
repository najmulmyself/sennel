import SwiftUI

/// The main streak screen (SennelHome.dc.html) — hero glass card with the ring,
/// live timer, money saved, today's progress, and the one-tap log button.
struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var onSettingsTap: () -> Void = {}

    @State private var pulseGlow = false
    @State private var pulseTask: Task<Void, Never>?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            content(date: context.date)
        }
    }

    private func content(date: Date) -> some View {
        let stage = appState.stage(at: date)
        let theme = SennelTheme(dark: colorScheme == .dark, stage: stage)

        return ZStack {
            theme.background.ignoresSafeArea()

            VStack(spacing: SennelSpace.md) {
                header(theme: theme, stage: stage)
                heroCard(theme: theme, date: date)
                logButton(theme: theme)
                nextEligibleRow(theme: theme, date: date)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, SennelSpace.lg)
            .padding(.top, SennelSpace.lg)
        }
    }

    // MARK: Header

    private func header(theme: SennelTheme, stage: SennelStage) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text(stage.label.uppercased())
                    .font(.caption.weight(.semibold))
                    .kerning(2)
                    .foregroundStyle(theme.stageColor)
                Text("Keep going.")
                    .font(.subheadline)
                    .foregroundStyle(theme.textSecondary)
            }
            Spacer()
            Button(action: onSettingsTap) {
                Image(systemName: "gearshape.fill")
                    .foregroundStyle(theme.textSecondary)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(theme.card))
                    .overlay(Circle().strokeBorder(theme.hairline))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Hero card

    private func heroCard(theme: SennelTheme, date: Date) -> some View {
        VStack(spacing: 0) {
            ringSection(theme: theme, date: date)

            Text(appState.clock(at: date))
                .font(.subheadline)
                .foregroundStyle(theme.textSecondary)
                .monospacedDigit()
                .padding(.top, SennelSpace.sm)

            Rectangle()
                .fill(theme.hairline)
                .frame(height: 1)
                .padding(.vertical, SennelSpace.md)

            savedTodayRow(theme: theme, date: date)
        }
        .padding(SennelSpace.lg)
        .background(
            LinearGradient(
                colors: [theme.stageSoft, .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .sennelGlass(tint: theme.stageColor, cornerRadius: SennelRadius.card)
        .shadow(color: theme.stageGlow, radius: 24, y: 10)
        .shadow(color: theme.stageColor.opacity(pulseGlow ? 0.45 : 0), radius: 44)
    }

    private func ringSection(theme: SennelTheme, date: Date) -> some View {
        let days = appState.daysClean(at: date)
        let progress = appState.stageProgress(at: date)

        return ZStack {
            StreakRing(
                progress: progress,
                stageColor: theme.stageColor,
                trackColor: theme.track,
                dotHaloColor: theme.card
            )
            .frame(width: 236, height: 236)

            VStack(spacing: 2) {
                HeroNumber("\(days)", baseSize: 78)
                    .foregroundStyle(theme.stageColor)
                    .contentTransition(.numericText())
                Text("DAYS CLEAN")
                    .font(.caption.weight(.bold))
                    .kerning(2)
                    .foregroundStyle(theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Streak progress")
        .accessibilityValue("Day \(days), \(Int(progress * 100)) percent to next milestone")
    }

    private func savedTodayRow(theme: SennelTheme, date: Date) -> some View {
        HStack(alignment: .bottom, spacing: SennelSpace.md) {
            VStack(alignment: .leading, spacing: 3) {
                Text("SAVED")
                    .font(.caption.weight(.semibold))
                    .kerning(1.5)
                    .foregroundStyle(theme.textSecondary)
                HeroNumber(appState.money(at: date), baseSize: 30)
                    .foregroundStyle(theme.textPrimary)
                    .monospacedDigit()
            }

            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text("Today")
                        .font(.subheadline)
                        .foregroundStyle(theme.textSecondary)
                    Spacer()
                    Text("\(appState.usedToday) of \(appState.dailyLimit)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.textPrimary)
                }
                GeometryReader { geo in
                    let fraction = appState.dailyLimit > 0
                        ? min(1, Double(appState.usedToday) / Double(appState.dailyLimit))
                        : 0
                    ZStack(alignment: .leading) {
                        Capsule().fill(theme.track)
                        Capsule()
                            .fill(theme.stageColor)
                            .frame(width: geo.size.width * fraction)
                            .animation(reduceMotion ? nil : .easeOut(duration: 0.45), value: fraction)
                    }
                }
                .frame(height: 8)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Today's progress")
            .accessibilityValue("\(appState.usedToday) of \(appState.dailyLimit) used")
        }
    }

    // MARK: Log button

    private func logButton(theme: SennelTheme) -> some View {
        Button(action: logPouch) {
            Text("I just used a pouch")
                .font(.body.weight(.semibold))
                .foregroundStyle(theme.buttonText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
        }
        .buttonStyle(.plain)
        .background(theme.stageColor, in: RoundedRectangle(cornerRadius: SennelRadius.button, style: .continuous))
        .shadow(color: theme.stageGlow, radius: 18, y: 8)
        .sensoryFeedback(.impact(weight: .light), trigger: appState.usedToday)
    }

    private func logPouch() {
        appState.logPouch()
        if reduceMotion {
            pulseGlow = true
        } else {
            withAnimation(.easeOut(duration: 0.1)) { pulseGlow = true }
        }
        pulseTask?.cancel()
        pulseTask = Task {
            try? await Task.sleep(for: .seconds(0.65))
            guard !Task.isCancelled else { return }
            if reduceMotion {
                pulseGlow = false
            } else {
                withAnimation(.easeOut(duration: 0.55)) { pulseGlow = false }
            }
        }
    }

    // MARK: Next eligible row

    private func nextEligibleRow(theme: SennelTheme, date: Date) -> some View {
        HStack(spacing: SennelSpace.sm) {
            Image(systemName: "clock")
                .foregroundStyle(theme.stageColor)

            if let next = appState.nextEligibleSlot(at: date) {
                (Text("Next pouch eligible at ").foregroundStyle(theme.textSecondary)
                    + Text(next, format: .dateTime.hour().minute())
                    .fontWeight(.semibold)
                    .foregroundStyle(theme.textPrimary))
            } else {
                Text("You've reached today's goal")
                    .foregroundStyle(theme.textSecondary)
            }
        }
        .font(.subheadline)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    HomeView()
        .environment(AppState())
}
