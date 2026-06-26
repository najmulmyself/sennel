import ActivityKit
import Foundation

/// Manages Live Activity lifecycle for the next-slot countdown. Starts when the
/// user logs the first pouch of the day, updates when usage/limit changes, ends
/// at end-of-day. Uses `Text(timerInterval:)` for native countdown rendering
/// so we don't need constant update() calls.
@MainActor
final class LiveActivityManager {
    private var currentActivity: Activity<SennelScheduleActivityAttributes>?

    func updateActivity(for appState: AppState, at date: Date = .now) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }

        // End activity if past end-of-day or no next slot
        if date >= endOfDay || appState.nextEligibleSlot(at: date) == nil {
            endActivity()
            return
        }

        // Request new activity if none exists and there's a next slot
        guard let nextSlot = appState.nextEligibleSlot(at: date) else {
            endActivity()
            return
        }

        if let activity = currentActivity {
            // Update existing activity
            let contentState = SennelScheduleActivityAttributes.ContentState(
                nextEligibleSlot: nextSlot,
                usedToday: appState.usedToday,
                dailyLimit: appState.dailyLimit
            )
            Task {
                await activity.update(ActivityContent(state: contentState, staleDate: endOfDay))
            }
        } else if ActivityAuthorizationInfo().areActivitiesEnabled {
            // Request new activity
            let attributes = SennelScheduleActivityAttributes(irrelevantAdContent: "")
            let contentState = SennelScheduleActivityAttributes.ContentState(
                nextEligibleSlot: nextSlot,
                usedToday: appState.usedToday,
                dailyLimit: appState.dailyLimit
            )
            let content = ActivityContent(state: contentState, staleDate: endOfDay)

            do {
                let activity = try Activity.request(
                    attributes: attributes,
                    content: content,
                    pushType: nil
                )
                currentActivity = activity
            } catch {
                // Activities not enabled or error occurred
                currentActivity = nil
            }
        }
    }

    func endActivity() {
        guard let activity = currentActivity else { return }
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            currentActivity = nil
        }
    }
}
