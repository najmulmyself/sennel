import UserNotifications

final class NotificationService {
    static let shared = NotificationService()

    func requestPermissionIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        }
        return settings.authorizationStatus == .authorized
    }

    func scheduleNextEligibleNotification(from lastLog: Date, dailyGoal: Int) {
        let eligibleAt = StreakCalculator.nextEligibleTime(lastLogTime: lastLog, dailyGoal: dailyGoal)
        let content = UNMutableNotificationContent()
        content.title = "You're eligible for your next pouch"
        content.body = "Still want it? Your plan says it's been long enough."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: eligibleAt),
            repeats: false
        )
        let request = UNNotificationRequest(identifier: "next-eligible", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
