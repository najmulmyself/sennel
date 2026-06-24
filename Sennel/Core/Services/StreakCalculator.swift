import Foundation

struct StreakCalculator {
    /// Days since quitStartDate, accounting for relapses that consumed a shield (no reset)
    /// vs. relapses that didn't (quitStartDate already moved forward by the caller in that case).
    static func currentStreakDays(from quitStartDate: Date, now: Date = .now) -> Int {
        Calendar.current.dateComponents([.day], from: quitStartDate, to: now).day ?? 0
    }

    static func streakStage(forDays days: Int) -> StreakStage {
        switch days {
        case 0...2: return .stage0
        case 3...7: return .stage1
        case 8...29: return .stage2
        default: return .stage3
        }
    }

    /// Phase 1 model: assumes full cessation from quitStartDate.
    /// Phase 2 should refine using actual logged taper data once craving/usage logging exists —
    /// don't over-build this now.
    static func moneySaved(daysClean: Int, pouchesPerDay: Int, costPerPouch: Double) -> Double {
        Double(daysClean) * Double(pouchesPerDay) * costPerPouch
    }

    /// 0...1 progress from the current stage's lower bound toward the next stage's threshold.
    /// Drives the streak ring fill — caps at 1 once stage3 (no further stage to progress toward).
    static func progressTowardNextStage(forDays days: Int) -> Double {
        let bounds = [0, 3, 8, 30]
        guard let index = bounds.lastIndex(where: { $0 <= days }) else { return 0 }
        guard index < bounds.count - 1 else { return 1 }
        let lower = bounds[index]
        let upper = bounds[index + 1]
        return Double(days - lower) / Double(upper - lower)
    }

    /// Interval scheduler: evenly distributes dailyGoal across a waking-hours window.
    static func nextEligibleTime(
        lastLogTime: Date,
        dailyGoal: Int,
        wakingHoursStart: Int = 7,
        wakingHoursEnd: Int = 23,
        calendar: Calendar = .current
    ) -> Date {
        let wakingSeconds = Double(wakingHoursEnd - wakingHoursStart) * 3600
        let interval = wakingSeconds / Double(max(dailyGoal, 1))
        return lastLogTime.addingTimeInterval(interval)
    }
}

enum StreakStage {
    case stage0, stage1, stage2, stage3

    /// Eyebrow label shown on Home, per design doc §2's "Feel" column for each stage.
    var eyebrowLabel: String {
        switch self {
        case .stage0: return "A FRESH START"
        case .stage1: return "WARMING UP"
        case .stage2: return "BUILDING"
        case .stage3: return "ARRIVED"
        }
    }
}
