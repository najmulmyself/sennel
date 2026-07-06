import Foundation
import SwiftData

/// The single-row scalar state every other screen reads/writes — there's exactly
/// one user, so `AppState` fetches-or-creates this one instance rather than
/// keying on anything. Replaces what used to be plain stored properties on
/// `AppState` itself before persistence existed.
@Model
final class UserProfile {
    var hasOnboarded: Bool
    var startDate: Date
    var dailyLimit: Int
    var dailySpend: Double
    var usedToday: Int
    var isDarkMode: Bool
    var remindersOn: Bool

    var priorStreakDays: Int
    var priorMoneySaved: Double
    var streakShieldsRemaining: Int
    var streakShieldsTotal: Int
    var breathingSessionsCompleted: Int

    /// Cached locally so gated screens (Insights extras, widgets, Live Activity)
    /// don't need an async StoreKit round-trip just to render. The real source
    /// of truth is still `Transaction.currentEntitlements`, reconciled on launch.
    var isPremium: Bool

    init(
        hasOnboarded: Bool = false,
        startDate: Date = .now,
        dailyLimit: Int = 8,
        dailySpend: Double = 11.4,
        usedToday: Int = 0,
        isDarkMode: Bool = false,
        remindersOn: Bool = true,
        priorStreakDays: Int = 0,
        priorMoneySaved: Double = 0,
        streakShieldsRemaining: Int = 2,
        streakShieldsTotal: Int = 3,
        breathingSessionsCompleted: Int = 0,
        isPremium: Bool = false
    ) {
        self.hasOnboarded = hasOnboarded
        self.startDate = startDate
        self.dailyLimit = dailyLimit
        self.dailySpend = dailySpend
        self.usedToday = usedToday
        self.isDarkMode = isDarkMode
        self.remindersOn = remindersOn
        self.priorStreakDays = priorStreakDays
        self.priorMoneySaved = priorMoneySaved
        self.streakShieldsRemaining = streakShieldsRemaining
        self.streakShieldsTotal = streakShieldsTotal
        self.breathingSessionsCompleted = breathingSessionsCompleted
        self.isPremium = isPremium
    }
}
