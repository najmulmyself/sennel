import SwiftUI
import SwiftData

/// Flat milestone list (no glass, per design doc §10) — nicotine recovery timeline,
/// checked off as elapsed time since quitStartDate passes each threshold.
struct HealthTimelineView: View {
    @Query private var settingsList: [UserSettings]

    var body: some View {
        List(Self.milestones) { milestone in
            HStack(alignment: .top, spacing: Spacing.sm) {
                Image(systemName: "leaf.fill")
                    .foregroundStyle(isReached(milestone) ? Color.color(for: .stage2) : Color.textSecondary)
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(milestone.title)
                        .font(.headline)
                    Text(milestone.detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, Spacing.xs)
        }
        .navigationTitle("Health Timeline")
    }

    private var elapsedHours: Double {
        guard let settings = settingsList.first else { return 0 }
        return max(Date.now.timeIntervalSince(settings.quitStartDate), 0) / 3600
    }

    private func isReached(_ milestone: Milestone) -> Bool {
        elapsedHours >= milestone.thresholdHours
    }

    struct Milestone: Identifiable {
        let id = UUID()
        let thresholdHours: Double
        let title: String
        let detail: String
    }

    static let milestones: [Milestone] = [
        Milestone(thresholdHours: 1.0 / 3, title: "Heart rate begins to drop", detail: "Within 20 minutes, your heart rate and blood pressure start returning to normal."),
        Milestone(thresholdHours: 1, title: "Nicotine levels drop", detail: "One hour in, nicotine has already started clearing from your bloodstream."),
        Milestone(thresholdHours: 24, title: "Oxygen levels normalize", detail: "Oxygen levels in your blood have returned to a healthy range."),
        Milestone(thresholdHours: 72, title: "Nicotine fully cleared", detail: "All nicotine has left your system — withdrawal symptoms typically peak around now."),
        Milestone(thresholdHours: 168, title: "Cravings start to ease", detail: "One week in, cravings become noticeably less frequent and intense."),
        Milestone(thresholdHours: 720, title: "Mood stabilizes", detail: "One month clean — sleep quality and mood swings continue to improve."),
        Milestone(thresholdHours: 2160, title: "Healing continues", detail: "Three months clean — oral tissue healing is well underway.")
    ]
}

#Preview {
    NavigationStack { HealthTimelineView() }
        .modelContainer(for: [UserSettings.self, PouchLog.self, RelapseEvent.self], inMemory: true)
}
