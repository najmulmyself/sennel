import SwiftUI
import SwiftData

/// The PRD's "first 30 seconds" screen — proof-of-value on cold launch.
struct HomeView: View {
    let settings: UserSettings

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HomeViewModel?
    @State private var showSettings = false
    @State private var showScheduler = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                if let viewModel {
                    HomeHeaderBar(onSettingsTap: { showSettings = true })

                    GlassEffectContainer {
                        HomeStreakCard(viewModel: viewModel)
                        PouchLogButton(viewModel: viewModel)
                    }
                    .sensoryFeedback(trigger: viewModel.logTrigger) { _, _ in
                        viewModel.lastLogWasShielded ? .impact(weight: .medium) : .impact(weight: .soft)
                    }

                    Button(action: { showScheduler = true }) {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "clock")
                            Text("Next pouch eligible at ")
                                + Text(viewModel.nextEligibleTime.formatted(date: .omitted, time: .shortened)).bold()
                        }
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .sensoryFeedback(.impact(weight: .light), trigger: viewModel.schedulerUnlockTrigger)
                }
            }
            .padding(Spacing.md)
        }
        .background(Color.surfaceBackground)
        .onAppear {
            if viewModel == nil {
                viewModel = HomeViewModel(modelContext: modelContext, settings: settings)
            } else {
                viewModel?.refresh()
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack { SettingsView() }
        }
        .sheet(isPresented: $showScheduler) {
            NavigationStack { IntervalSchedulerView() }
        }
    }
}

/// Eyebrow + headline + settings entry point, top of the Home chrome.
private struct HomeHeaderBar: View {
    let onSettingsTap: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("A FRESH START")
                    .font(.caption.weight(.semibold))
                    .tracking(1.2)
                    .foregroundStyle(Color.textSecondary)
                Text("Keep going.")
                    .font(.title2)
                    .foregroundStyle(Color.textPrimary)
            }

            Spacer()

            Button(action: onSettingsTap) {
                Image(systemName: "gearshape.fill")
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.surfaceCard))
            }
            .accessibilityLabel("Settings")
        }
    }
}

/// The hero card: streak ring, elapsed-time readout, money saved, today's usage vs. goal.
/// Glass-tinted with the current progressive streak color, per design doc §5.
private struct HomeStreakCard: View {
    let viewModel: HomeViewModel

    var body: some View {
        GlassCard(tint: Color.color(for: viewModel.streakStage)) {
            cardContent
        }
    }

    private var cardContent: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                StreakRingView(progress: viewModel.ringProgress, stage: viewModel.streakStage, days: viewModel.currentStreakDays, lineWidth: 14)
                    .frame(width: 220, height: 220)

                VStack(spacing: Spacing.xs) {
                    Text("\(viewModel.currentStreakDays)")
                        .font(.heroNumber(size: 64))
                        .foregroundStyle(Color.textPrimary)
                    Text("DAYS CLEAN")
                        .font(.caption.weight(.semibold))
                        .tracking(1.0)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .padding(.top, Spacing.md)

            Text(viewModel.elapsedCleanLabel)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(Color.textSecondary)

            Divider()

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("SAVED")
                        .font(.caption.weight(.semibold))
                        .tracking(1.0)
                        .foregroundStyle(Color.textSecondary)
                    Text(viewModel.moneySaved, format: .currency(code: "USD"))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.textPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    HStack(spacing: Spacing.xs) {
                        Text("Today")
                            .foregroundStyle(Color.textSecondary)
                        Text("\(viewModel.todayPouchCount) of \(viewModel.dailyGoal)")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.textPrimary)
                    }
                    .font(.subheadline)

                    ProgressView(value: Double(viewModel.todayPouchCount), total: Double(max(viewModel.dailyGoal, 1)))
                        .frame(width: 140)
                        .tint(Color.textSecondary)
                }
            }
        }
        .padding(Spacing.lg)
    }
}

/// "I just used a pouch" — the one primary action on the screen. Glass-tinted per
/// design doc §5, scale+spring on tap, brief glow pulse on log (design doc §7).
private struct PouchLogButton: View {
    let viewModel: HomeViewModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isGlowing = false

    var body: some View {
        Button {
            viewModel.logPouch()
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) { isGlowing = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) { isGlowing = false }
            }
        } label: {
            Text("I just used a pouch")
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
        }
        .buttonStyle(PouchLogButtonStyle(reduceMotion: reduceMotion))
        .glassEffect(.regular.tint(Color.color(for: viewModel.streakStage)).interactive(), in: RoundedRectangle(cornerRadius: Radius.button))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.button)
                .stroke(Color.color(for: viewModel.streakStage), lineWidth: 3)
                .opacity(isGlowing ? 0.8 : 0)
        )
    }
}

/// Scales to 0.96 and springs back on press, per design doc §7 — skipped under Reduce Motion.
private struct PouchLogButtonStyle: ButtonStyle {
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1.0)
            .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

#Preview {
    HomeView(settings: UserSettings(quitStartDate: .now.addingTimeInterval(-86400 * 10), dailyGoal: 5))
        .modelContainer(for: [UserSettings.self, PouchLog.self, RelapseEvent.self], inMemory: true)
}
