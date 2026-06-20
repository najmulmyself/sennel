import SwiftUI

/// "Next pouch eligible at [time]" card, per design doc §10. Countdown styling and
/// notification-permission gating land in the UI pass; degrades to in-app-only if
/// notification permission is denied (PRD §10 edge case).
struct IntervalSchedulerView: View {
    var body: some View {
        VStack(spacing: Spacing.md) {
            Text("Interval Scheduler")
        }
        .padding(Spacing.md)
    }
}

#Preview {
    IntervalSchedulerView()
}
