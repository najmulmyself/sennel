import SwiftData
import Foundation

@Model
final class UserSettings {
    var quitStartDate: Date
    var dailyGoal: Int                 // max pouches/day, used by progress bar + interval scheduler
    var baselineCostPerPouch: Double   // defaults to 0.35 (market-research average) until user edits it in secondary onboarding
    var baselinePouchesPerDay: Int     // defaults to 12 (≈ one can/day) until user edits it
    var hasCompletedSecondaryOnboarding: Bool
    var streakShieldsUsedThisMonth: Int
    var isPremium: Bool                // mirrors StoreKitService entitlement check; source of truth is StoreKit, this is a cache

    init(quitStartDate: Date = .now, dailyGoal: Int = 5) {
        self.quitStartDate = quitStartDate
        self.dailyGoal = dailyGoal
        self.baselineCostPerPouch = 0.35
        self.baselinePouchesPerDay = 12
        self.hasCompletedSecondaryOnboarding = false
        self.streakShieldsUsedThisMonth = 0
        self.isPremium = false
    }
}
