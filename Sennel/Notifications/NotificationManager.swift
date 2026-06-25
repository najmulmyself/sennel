import UserNotifications

/// Owns notification permission plus the single pending "next eligible slot"
/// reminder — there's never more than one request in flight. `reschedule(for:)`
/// cancels whatever's pending and re-derives the next slot from `AppState`, so
/// it's safe to call after every pouch log, every limit edit, and on foreground.
@MainActor
@Observable
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    private static let requestIdentifier = "com.sennel.app.nextSlot"

    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    /// Set when the user taps the delivered notification — `MainTabView` observes
    /// this to route to the Schedule tab, then clears it.
    var pendingScheduleTap = false

    func refreshAuthorizationStatus() async {
        authorizationStatus = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        await refreshAuthorizationStatus()
        return granted
    }

    func reschedule(for appState: AppState, at date: Date = .now) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.requestIdentifier])

        guard appState.remindersOn,
              authorizationStatus == .authorized || authorizationStatus == .provisional,
              let slot = appState.nextEligibleSlot(at: date), slot > date else { return }

        let content = UNMutableNotificationContent()
        content.title = "Next pouch slot is up"
        content.body = "Hold off a little longer if you can — you're doing fine."
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: slot)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: Self.requestIdentifier, content: content, trigger: trigger)
        center.add(request)
    }

    func cancelPending() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.requestIdentifier])
    }

    // MARK: UNUserNotificationCenterDelegate

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        Task { @MainActor in
            pendingScheduleTap = true
        }
        completionHandler()
    }
}
