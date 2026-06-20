import Foundation
import SwiftData
import Observation

@Observable
final class HomeViewModel {
    var currentStreakDays: Int = 0
    var moneySaved: Double = 0
    var streakStage: StreakStage = .stage0

    private var modelContext: ModelContext
    private var settings: UserSettings

    init(modelContext: ModelContext, settings: UserSettings) {
        self.modelContext = modelContext
        self.settings = settings
        refresh()
    }

    func refresh() {
        currentStreakDays = StreakCalculator.currentStreakDays(from: settings.quitStartDate)
        streakStage = StreakCalculator.streakStage(forDays: currentStreakDays)
        moneySaved = StreakCalculator.moneySaved(
            daysClean: currentStreakDays,
            pouchesPerDay: settings.baselinePouchesPerDay,
            costPerPouch: settings.baselineCostPerPouch
        )
    }

    func logPouch() {
        let log = PouchLog()
        modelContext.insert(log)
        try? modelContext.save()
        HapticService.fire(.pouchLogged)
        // Reschedule interval-scheduler notification — see NotificationService
        NotificationService.shared.scheduleNextEligibleNotification(
            from: log.timestamp,
            dailyGoal: settings.dailyGoal
        )
    }

    func logRelapse() {
        let shieldAvailable = settings.streakShieldsUsedThisMonth < 3
        let event = RelapseEvent(
            shieldUsed: shieldAvailable,
            previousStreakDays: currentStreakDays
        )
        modelContext.insert(event)
        if shieldAvailable {
            settings.streakShieldsUsedThisMonth += 1
            // streak NOT reset — history preserved, no judgment, per PRD
        } else {
            settings.quitStartDate = .now
        }
        try? modelContext.save()
        HapticService.fire(.relapseLogged) // .soft, never harsh — see design doc §8
        refresh()
    }
}
