import Foundation
import SwiftData
import Observation

@Observable
final class HomeViewModel {
    var currentStreakDays: Int = 0
    var moneySaved: Double = 0
    var streakStage: StreakStage = .stage0
    var ringProgress: Double = 0
    var elapsedCleanLabel: String = ""
    var todayPouchCount: Int = 0
    var dailyGoal: Int = 0
    var nextEligibleTime: Date = .now

    /// Bump on every log so a view can attach `.sensoryFeedback(trigger:)`; the haptic
    /// itself lives in the view layer per design doc §8, not fired imperatively here.
    var logTrigger: Int = 0
    var lastLogWasShielded: Bool = false
    /// Bumps the moment "next pouch eligible" time is crossed while the screen is open.
    var schedulerUnlockTrigger: Int = 0

    private var modelContext: ModelContext
    private var settings: UserSettings
    private var timer: Timer?
    private var wasSchedulerEligible = true

    init(modelContext: ModelContext, settings: UserSettings) {
        self.modelContext = modelContext
        self.settings = settings
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    deinit {
        timer?.invalidate()
    }

    func refresh() {
        currentStreakDays = StreakCalculator.currentStreakDays(from: settings.quitStartDate)
        streakStage = StreakCalculator.streakStage(forDays: currentStreakDays)
        ringProgress = StreakCalculator.ringFillProgress(forDays: currentStreakDays)
        moneySaved = StreakCalculator.moneySaved(
            daysClean: currentStreakDays,
            pouchesPerDay: settings.baselinePouchesPerDay,
            costPerPouch: settings.baselineCostPerPouch
        )
        dailyGoal = settings.dailyGoal
        todayPouchCount = fetchTodayPouchCount()
        nextEligibleTime = StreakCalculator.nextEligibleTime(
            lastLogTime: fetchLastPouchLog()?.timestamp ?? settings.quitStartDate,
            dailyGoal: settings.dailyGoal
        )
        wasSchedulerEligible = Date.now >= nextEligibleTime
        tick()
    }

    /// Logging a pouch is, in this app, the relapse event itself — full abstinence is the
    /// goal, so any use breaks the clean streak unless a monthly shield absorbs it (no judgment,
    /// history preserved either way). The interval scheduler then paces how soon the next one
    /// is "eligible" if it happens again.
    func logPouch() {
        let log = PouchLog()
        modelContext.insert(log)

        let shieldAvailable = settings.streakShieldsUsedThisMonth < 3
        let event = RelapseEvent(shieldUsed: shieldAvailable, previousStreakDays: currentStreakDays)
        modelContext.insert(event)

        if shieldAvailable {
            settings.streakShieldsUsedThisMonth += 1
        } else {
            settings.quitStartDate = .now
        }

        try? modelContext.save()
        lastLogWasShielded = shieldAvailable
        logTrigger += 1
        NotificationService.shared.scheduleNextEligibleNotification(from: log.timestamp, dailyGoal: settings.dailyGoal)
        refresh()
    }

    private func tick() {
        let totalSeconds = max(Int(Date.now.timeIntervalSince(settings.quitStartDate)), 0)
        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        elapsedCleanLabel = String(format: "%dd %dh %02dm %02ds clean", days, hours, minutes, seconds)

        let isEligibleNow = Date.now >= nextEligibleTime
        if isEligibleNow && !wasSchedulerEligible {
            schedulerUnlockTrigger += 1
        }
        wasSchedulerEligible = isEligibleNow
    }

    private func fetchTodayPouchCount() -> Int {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        let predicate = #Predicate<PouchLog> { $0.timestamp >= startOfDay }
        let descriptor = FetchDescriptor<PouchLog>(predicate: predicate)
        return (try? modelContext.fetch(descriptor))?.count ?? 0
    }

    private func fetchLastPouchLog() -> PouchLog? {
        var descriptor = FetchDescriptor<PouchLog>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        descriptor.fetchLimit = 1
        return (try? modelContext.fetch(descriptor))?.first
    }
}
