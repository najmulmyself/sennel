import SwiftUI
import SwiftData

/// "Next pouch eligible at [time]" detail screen, per design doc §10. Notification
/// scheduling happens at log time (see NotificationService); this view degrades to an
/// in-app-only countdown if notification permission was denied (PRD edge case).
struct IntervalSchedulerView: View {
    @Query(sort: \PouchLog.timestamp, order: .reverse) private var allLogs: [PouchLog]
    @Query private var settingsList: [UserSettings]

    var body: some View {
        VStack(spacing: Spacing.lg) {
            VStack(spacing: Spacing.xs) {
                Text("Next pouch eligible at")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(nextEligibleTime.formatted(date: .omitted, time: .shortened))
                    .font(.heroNumber(size: 40))
            }
            .padding(.top, Spacing.lg)

            List {
                Section("Today") {
                    if todayLogs.isEmpty {
                        Text("No pouches logged today.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(todayLogs) { log in
                            Text(log.timestamp.formatted(date: .omitted, time: .shortened))
                        }
                    }
                }
            }
        }
        .navigationTitle("Interval Scheduler")
    }

    private var todayLogs: [PouchLog] {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        return allLogs.filter { $0.timestamp >= startOfDay }
    }

    private var nextEligibleTime: Date {
        let dailyGoal = settingsList.first?.dailyGoal ?? 5
        let anchor = todayLogs.first?.timestamp ?? settingsList.first?.quitStartDate ?? .now
        return StreakCalculator.nextEligibleTime(lastLogTime: anchor, dailyGoal: dailyGoal)
    }
}

#Preview {
    NavigationStack { IntervalSchedulerView() }
        .modelContainer(for: [UserSettings.self, PouchLog.self, RelapseEvent.self], inMemory: true)
}
