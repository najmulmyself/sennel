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

    /// 0...1 fill for the streak ring. Grows continuously with total days clean — does NOT
    /// reset at stage boundaries (a reset would mean the ring visually snaps from
    /// nearly-full back to nearly-empty the instant you cross into a new stage, which
    /// reads as a regression rather than progress). Saturates asymptotically so the ring
    /// never fully closes — there's always a small gap and somewhere for the leading dot
    /// to sit, even deep into stage3. k=14 means roughly two weeks to half-fill.
    static func ringFillProgress(forDays days: Int) -> Double {
        let k = 14.0
        let raw = 1 - exp(-Double(days) / k)
        return max(raw, 0.04) // small visible nub even on day 0 — "a fresh start," not nothing
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
