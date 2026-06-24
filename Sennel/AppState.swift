import SwiftUI

/// In-memory app state shared across every screen. Phase 1 scope is UI fidelity
/// only — no SwiftData/StoreKit yet, so nothing here persists across launches.
@Observable
final class AppState {
    var hasOnboarded = false

    /// The moment the streak started — "last pouch" from onboarding step 1.
    var startDate = Date()

    var dailyLimit = 8
    var dailySpend = 11.4
    var usedToday = 0

    /// Manual override toggled from Settings — re-themes the whole app, the same
    /// way SennelApp's prototype dark-mode switch worked (not tied to system appearance).
    var isDarkMode = false

    // MARK: Time-dependent values

    /// Everything below takes an explicit `date` so call sites can drive it from a
    /// `TimelineView` tick rather than each screen owning its own timer.

    func elapsed(at date: Date) -> TimeInterval {
        max(0, date.timeIntervalSince(startDate))
    }

    func daysClean(at date: Date) -> Int {
        Int(elapsed(at: date) / 86400)
    }

    func moneySaved(at date: Date) -> Double {
        elapsed(at: date) / 86400 * dailySpend
    }

    func stage(at date: Date) -> SennelStage {
        .forDays(daysClean(at: date))
    }

    /// Ring fill = progress toward the *next* stage threshold, so the ring
    /// visibly closes in just as the accent color is about to warm up again.
    func stageProgress(at date: Date) -> Double {
        let days = Double(elapsed(at: date) / 86400)
        switch stage(at: date) {
        case .slate: return days / 3
        case .teal3: return (days - 3) / (8 - 3)
        case .teal4: return (days - 8) / (30 - 8)
        case .emerald: return min(1, (days - 30) / 30)
        }
    }

    func clock(at date: Date) -> String {
        let e = Int(elapsed(at: date))
        let d = e / 86400, h = (e / 3600) % 24, m = (e / 60) % 60, s = e % 60
        return String(format: "%dd %dh %dm %02ds clean", d, h, m, s)
    }

    func money(at date: Date) -> String {
        "$" + String(format: "%.2f", moneySaved(at: date))
    }

    // MARK: Interval scheduler

    /// 8 AM–10 PM window split evenly across the daily limit, matching the
    /// PRD's "distribute daily pouch allowance across waking hours."
    struct ScheduleSlot: Identifiable {
        let id: Int
        let time: Date
        var status: Status
        enum Status { case done, next, upcoming }
    }

    func todaysSlots(at date: Date, calendar: Calendar = .current) -> [ScheduleSlot] {
        let startOfDay = calendar.startOfDay(for: date)
        guard let windowStart = calendar.date(byAdding: .hour, value: 8, to: startOfDay),
              let windowEnd = calendar.date(byAdding: .hour, value: 22, to: startOfDay),
              dailyLimit > 0 else { return [] }

        let interval = windowEnd.timeIntervalSince(windowStart) / Double(dailyLimit)
        return (0..<dailyLimit).map { i in
            let slotTime = windowStart.addingTimeInterval(interval * Double(i))
            let status: ScheduleSlot.Status = i < usedToday ? .done : (i == usedToday ? .next : .upcoming)
            return ScheduleSlot(id: i, time: slotTime, status: status)
        }
    }

    func nextEligibleSlot(at date: Date) -> Date? {
        todaysSlots(at: date).first { $0.status == .next }?.time
    }

    // MARK: Actions

    func logPouch() {
        usedToday += 1
    }
}
