import SwiftUI

/// The Interval Scheduler (SennelScheduler.dc.html) — the PRD's "headline
/// differentiator." Uses a fixed brand-teal accent rather than the streak stage
/// color, since the schedule is its own steady-state feature independent of stage.
struct ScheduleView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            content(date: context.date)
        }
    }

    private func content(date: Date) -> some View {
        let theme = SennelTheme(dark: colorScheme == .dark, stage: appState.stage(at: date))
        let accent = SennelTheme.brandTealLight
        let slots = appState.todaysSlots(at: date)

        return ZStack {
            theme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: SennelSpace.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Schedule")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(theme.textPrimary)
                    Text("\(appState.dailyLimit) pouches, spread from 8 AM to 10 PM.")
                        .font(.subheadline)
                        .foregroundStyle(theme.textSecondary)
                }

                countdownCard(theme: theme, accent: accent, date: date, slots: slots)

                Text("TODAY'S SLOTS")
                    .font(.caption.weight(.semibold))
                    .kerning(1.5)
                    .foregroundStyle(theme.textSecondary)

                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(slots) { slot in
                            slotRow(slot: slot, theme: theme, accent: accent)
                        }
                    }
                }
            }
            .padding(.horizontal, SennelSpace.lg)
            .padding(.top, SennelSpace.lg)
        }
    }

    // MARK: Countdown card

    private func countdownCard(theme: SennelTheme, accent: Color, date: Date, slots: [AppState.ScheduleSlot]) -> some View {
        let next = appState.nextEligibleSlot(at: date)
        let previous = slots.last(where: { $0.status == .done })?.time
        let progress = countdownProgress(date: date, next: next, previous: previous)
        let timeLeft = next.map { format(interval: $0.timeIntervalSince(date)) } ?? "0m"

        return HStack(spacing: SennelSpace.lg) {
            ZStack {
                Circle()
                    .stroke(theme.hairline, lineWidth: 10)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(accent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(reduceMotion ? nil : .easeInOut(duration: 1.2), value: progress)
                VStack(spacing: 1) {
                    HeroNumber(timeLeft, baseSize: 26)
                        .foregroundStyle(theme.textPrimary)
                    Text("LEFT")
                        .font(.caption2.weight(.semibold))
                        .kerning(1.5)
                        .foregroundStyle(theme.textSecondary)
                }
            }
            .frame(width: 130, height: 130)

            VStack(alignment: .leading, spacing: 7) {
                Text("NEXT ELIGIBLE")
                    .font(.caption.weight(.semibold))
                    .kerning(1.2)
                    .foregroundStyle(accent)
                if let next {
                    HeroNumber(next.formatted(date: .omitted, time: .shortened), baseSize: 30)
                        .foregroundStyle(theme.textPrimary)
                } else {
                    HeroNumber("Done", baseSize: 30)
                        .foregroundStyle(theme.textPrimary)
                }
                Text(next != nil ? "Hold off a little longer — you're doing fine." : "You've used today's allowance.")
                    .font(.subheadline)
                    .foregroundStyle(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(SennelSpace.lg)
        .background(
            LinearGradient(colors: [accent.opacity(theme.dark ? 0.16 : 0.10), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .background(theme.card)
        .overlay(RoundedRectangle(cornerRadius: SennelRadius.card, style: .continuous).strokeBorder(theme.hairline))
        .clipShape(RoundedRectangle(cornerRadius: SennelRadius.card, style: .continuous))
        .shadow(color: .black.opacity(theme.dark ? 0 : 0.06), radius: 24, y: 10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Next eligible pouch")
        .accessibilityValue(next != nil ? "\(timeLeft) left, at \(next!.formatted(date: .omitted, time: .shortened))" : "You've used today's allowance")
    }

    private func countdownProgress(date: Date, next: Date?, previous: Date?) -> Double {
        guard let next else { return 1 }
        let start = previous ?? next.addingTimeInterval(-1)
        let total = next.timeIntervalSince(start)
        guard total > 0 else { return 1 }
        return max(0, min(1, date.timeIntervalSince(start) / total))
    }

    private func format(interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        let h = total / 3600, m = (total % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }

    // MARK: Slot row

    private func slotRow(slot: AppState.ScheduleSlot, theme: SennelTheme, accent: Color) -> some View {
        HStack(spacing: 14) {
            ZStack {
                switch slot.status {
                case .done:
                    Circle().fill(accent)
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(theme.buttonText)
                case .next:
                    Circle().strokeBorder(accent, lineWidth: 2)
                case .upcoming:
                    Circle().strokeBorder(theme.hairline, lineWidth: 1.5)
                }
            }
            .frame(width: 26, height: 26)

            Text(slot.time, format: .dateTime.hour().minute())
                .font(.body.weight(slot.status == .next ? .bold : .medium))
                .foregroundStyle(slot.status == .upcoming || slot.status == .done ? theme.textSecondary : theme.textPrimary)

            Spacer()

            switch slot.status {
            case .done:
                Text("Logged").font(.subheadline.weight(.semibold)).foregroundStyle(theme.textSecondary)
            case .next:
                Text("Next").font(.subheadline.weight(.semibold)).foregroundStyle(accent)
            case .upcoming:
                EmptyView()
            }
        }
        .padding(.vertical, 11)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ScheduleView()
        .environment(AppState())
}
