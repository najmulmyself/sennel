import SwiftUI
import UIKit

/// Standard iOS list style, flat, no glass (sennel_design.md: "this is a utility
/// screen, treat it like one"). Daily limit/spend rows are wired to AppState;
/// Plan and App icon are visual-only since neither has a backing model in Phase 1.
struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(NotificationManager.self) private var notificationManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL

    var onPremiumTap: () -> Void = {}

    @State private var editingLimit = false
    @State private var editingSpend = false
    @State private var showingDeniedAlert = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            content(date: context.date)
        }
    }

    private func content(date: Date) -> some View {
        let theme = SennelTheme(dark: colorScheme == .dark, stage: appState.stage(at: date))

        return ZStack {
            theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: SennelSpace.lg) {
                    Text("Settings")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(theme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    profileRow(theme: theme, date: date)

                    section(title: "GOAL & HABITS", theme: theme) {
                        row(icon: "clock", tint: SennelTheme.brandTealLight, title: "Daily limit", value: "\(appState.dailyLimit) pouches", theme: theme) {
                            editingLimit = true
                        }
                        divider(theme: theme)
                        row(icon: "dollarsign.circle.fill", tint: SennelTheme.brandTealLight.opacity(0.85), title: "Daily spend", value: "$" + String(format: "%.2f", appState.dailySpend), theme: theme) {
                            editingSpend = true
                        }
                        divider(theme: theme)
                        row(icon: "checkmark", tint: SennelTheme.brandTealLight.opacity(0.7), title: "Plan", value: "Taper", theme: theme, action: {})
                    }

                    section(title: "REMINDERS & APPEARANCE", theme: theme) {
                        toggleRow(icon: "bell.fill", tint: SennelTheme.accentShield, title: "Interval reminders", isOn: remindersBinding, theme: theme)
                        divider(theme: theme)
                        toggleRow(icon: "moon.fill", tint: theme.textSecondary, title: "Dark mode", isOn: Binding(get: { appState.isDarkMode }, set: { appState.isDarkMode = $0 }), theme: theme)
                        divider(theme: theme)
                        row(icon: "app.fill", tint: SennelTheme.brandTealLight, title: "App icon", value: "Default", theme: theme, action: {})
                    }

                    premiumBanner(theme: theme)

                    Text("Sennel · v1.0")
                        .font(.caption)
                        .foregroundStyle(theme.textTertiary)
                        .padding(.bottom, SennelSpace.lg)
                }
                .padding(.horizontal, SennelSpace.md)
                .padding(.top, SennelSpace.lg)
            }
        }
        .sheet(isPresented: $editingLimit) {
            stepperSheet(title: "Daily limit", value: appState.dailyLimit, unit: "pouches", range: 1...20) { appState.dailyLimit = $0 }
        }
        .sheet(isPresented: $editingSpend) {
            SpendSheet(value: appState.dailySpend) { appState.dailySpend = $0 }
        }
        .alert("Reminders are off", isPresented: $showingDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enable notifications for Sennel in the Settings app to get interval reminders.")
        }
    }

    // MARK: Reminders toggle

    private var remindersBinding: Binding<Bool> {
        Binding(
            get: { appState.remindersOn },
            set: { newValue in
                if newValue {
                    Task {
                        let granted = await notificationManager.requestAuthorization()
                        appState.remindersOn = granted
                        if granted {
                            notificationManager.reschedule(for: appState)
                        } else {
                            showingDeniedAlert = true
                        }
                    }
                } else {
                    appState.remindersOn = false
                    notificationManager.cancelPending()
                }
            }
        )
    }

    // MARK: Profile row

    private func profileRow(theme: SennelTheme, date: Date) -> some View {
        HStack(spacing: 14) {
            StreakRing(progress: appState.stageProgress(at: date), stageColor: theme.stageColor, trackColor: theme.hairline, dotHaloColor: theme.card, lineWidth: 5)
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(appState.daysClean(at: date)) days clean")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(theme.textPrimary)
                Text("\(appState.money(at: date)) saved · \(appState.stage(at: date).label)")
                    .font(.subheadline)
                    .foregroundStyle(theme.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(theme.textTertiary)
        }
        .padding(SennelSpace.md)
        .background(theme.card)
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(theme.hairline))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    // MARK: Sections

    private func section(title: String, theme: SennelTheme, @ViewBuilder rows: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.caption)
                .foregroundStyle(theme.textSecondary)
                .padding(.leading, 20)

            VStack(spacing: 0) {
                rows()
            }
            .background(theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(theme.hairline))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func divider(theme: SennelTheme) -> some View {
        Rectangle().fill(theme.separator).frame(height: 1).padding(.leading, 57)
    }

    private func row(icon: String, tint: Color, title: String, value: String, theme: SennelTheme, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                iconBadge(icon: icon, tint: tint)
                Text(title)
                    .font(.body)
                    .foregroundStyle(theme.textPrimary)
                Spacer()
                Text(value)
                    .font(.body)
                    .foregroundStyle(theme.textSecondary)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.textTertiary)
            }
            .padding(.horizontal, SennelSpace.md)
            .frame(height: 50)
        }
        .buttonStyle(.plain)
    }

    private func toggleRow(icon: String, tint: Color, title: String, isOn: Binding<Bool>, theme: SennelTheme) -> some View {
        HStack(spacing: 12) {
            iconBadge(icon: icon, tint: tint)
            Text(title)
                .font(.body)
                .foregroundStyle(theme.textPrimary)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(theme.stageColor)
                .accessibilityLabel(title)
        }
        .padding(.horizontal, SennelSpace.md)
        .frame(height: 50)
    }

    private func iconBadge(icon: String, tint: Color) -> some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(tint)
            .frame(width: 29, height: 29)
            .overlay(
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
            )
            .accessibilityHidden(true)
    }

    // MARK: Premium banner

    private func premiumBanner(theme: SennelTheme) -> some View {
        Button(action: onPremiumTap) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(theme.stageColor)
                    .frame(width: 38, height: 38)
                    .overlay(
                        Image(systemName: appState.isPremium ? "checkmark.seal.fill" : "sparkles")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(appState.isPremium ? "Manage subscription" : "Unlock Premium")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(theme.textPrimary)
                    Text(appState.isPremium ? "Sennel Premium is active" : "Full analytics, widgets & more")
                        .font(.subheadline)
                        .foregroundStyle(theme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.textTertiary)
            }
            .padding(SennelSpace.md)
            .background(theme.stageColor.opacity(theme.dark ? 0.10 : 0.07))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(theme.stageColor.opacity(theme.dark ? 0.25 : 0.18)))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: Edit sheets

    private func stepperSheet(title: String, value: Int, unit: String, range: ClosedRange<Int>, onChange: @escaping (Int) -> Void) -> some View {
        StepperSheet(title: title, value: value, unit: unit, range: range, onChange: onChange)
    }
}

private struct StepperSheet: View {
    let title: String
    @State var value: Int
    let unit: String
    let range: ClosedRange<Int>
    let onChange: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            VStack(spacing: SennelSpace.lg) {
                HStack(spacing: 30) {
                    Button { value = max(range.lowerBound, value - 1) } label: {
                        Image(systemName: "minus").font(.title3).frame(width: 54, height: 54)
                    }
                    .buttonStyle(.bordered)
                    .clipShape(Circle())
                    .disabled(value <= range.lowerBound)

                    HeroNumber("\(value)", baseSize: 56)
                        .frame(minWidth: 90)
                        .contentTransition(.numericText())

                    Button { value = min(range.upperBound, value + 1) } label: {
                        Image(systemName: "plus").font(.title3).frame(width: 54, height: 54)
                    }
                    .buttonStyle(.bordered)
                    .clipShape(Circle())
                    .disabled(value >= range.upperBound)
                }
                .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8), value: value)

                Text(unit).foregroundStyle(.secondary)
            }
            .padding(.top, SennelSpace.xl)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { onChange(value); dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

private struct SpendSheet: View {
    @State var value: Double
    let onChange: (Double) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            VStack(spacing: SennelSpace.lg) {
                HStack(spacing: 30) {
                    Button { value = max(0, value - 0.5) } label: {
                        Image(systemName: "minus").font(.title3).frame(width: 54, height: 54)
                    }
                    .buttonStyle(.bordered)
                    .clipShape(Circle())

                    HeroNumber("$" + String(format: "%.2f", value), baseSize: 48)
                        .frame(minWidth: 130)
                        .contentTransition(.numericText())

                    Button { value += 0.5 } label: {
                        Image(systemName: "plus").font(.title3).frame(width: 54, height: 54)
                    }
                    .buttonStyle(.bordered)
                    .clipShape(Circle())
                }
                .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8), value: value)

                Text("per day").foregroundStyle(.secondary)
            }
            .padding(.top, SennelSpace.xl)
            .navigationTitle("Daily spend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { onChange(value); dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    SettingsView()
        .environment(AppState())
        .environment(NotificationManager())
}
