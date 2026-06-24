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

    // MARK: Phase 2 — lifetime stats (survive a restart, unlike `startDate`)

    /// Days/money banked from streaks that ended before this one — added to the
    /// current streak's numbers so a restart never erases earned badges or "this
    /// stays yours" totals (sennel_design.md Section 14: no shame-coded relapse UI).
    private(set) var priorStreakDays = 0
    private(set) var priorMoneySaved: Double = 0
    private(set) var streakShieldsRemaining = 2
    private(set) var streakShieldsTotal = 3
    private(set) var breathingSessionsCompleted = 0

    func lifetimeDaysClean(at date: Date) -> Int { priorStreakDays + daysClean(at: date) }
    func lifetimeMoneySaved(at date: Date) -> Double { priorMoneySaved + moneySaved(at: date) }

    /// "Use a shield" — keeps the streak intact at the cost of one of this month's
    /// shields. "Restart, no judgment" — banks the current streak's days/money into
    /// the lifetime totals, then starts a fresh one from now.
    func resolveRelapse(useShield: Bool) {
        if useShield, streakShieldsRemaining > 0 {
            streakShieldsRemaining -= 1
        } else {
            priorStreakDays += daysClean(at: .now)
            priorMoneySaved += moneySaved(at: .now)
            startDate = .now
            usedToday = 0
        }
    }

    func completeBreathingSession() {
        breathingSessionsCompleted += 1
    }

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

    // MARK: Craving logger (SennelCraving.dc.html)

    struct CravingEntry: Identifiable {
        let id = UUID()
        var date: Date
        var intensity: Int // 1...5
        var trigger: String
        var outcome: Outcome
        enum Outcome { case rodeItOut, used }
    }

    static let cravingTriggers = ["After meals", "Coffee", "Stress", "Boredom", "Driving", "Social", "Alcohol", "Phone"]

    var cravingEntries: [CravingEntry] = AppState.seedCravingEntries()

    func logCraving(intensity: Int, trigger: String, outcome: CravingEntry.Outcome) {
        cravingEntries.append(CravingEntry(date: .now, intensity: intensity, trigger: trigger, outcome: outcome))
    }

    /// 30 days of sample entries weighted toward afternoon/after-meal cravings, so
    /// Insights has something real to chart on first launch (no SwiftData yet).
    private static func seedCravingEntries() -> [CravingEntry] {
        let calendar = Calendar.current
        let now = Date()
        let weighted: [(String, Int)] = [
            ("After meals", 13), ("After meals", 14), ("Coffee", 9), ("Coffee", 15),
            ("Stress", 10), ("Boredom", 21), ("Driving", 17), ("Social", 20),
            ("After meals", 8), ("Alcohol", 19), ("Phone", 22), ("After meals", 13),
        ]
        return (0..<30).map { dayOffset in
            let (trigger, hour) = weighted[dayOffset % weighted.count]
            let day = calendar.date(byAdding: .day, value: -dayOffset, to: now) ?? now
            let date = calendar.date(bySettingHour: hour, minute: (dayOffset * 7) % 60, second: 0, of: day) ?? day
            let intensity = max(1, 5 - dayOffset / 10 + (dayOffset % 3 == 0 ? 1 : 0))
            return CravingEntry(date: date, intensity: min(5, intensity), trigger: trigger, outcome: dayOffset % 4 == 0 ? .used : .rodeItOut)
        }
    }

    func cravingIntensityLabel(_ intensity: Int) -> String {
        switch intensity {
        case ...1: return "Mild"
        case 2: return "Noticeable"
        case 3: return "Strong"
        case 4: return "Intense"
        default: return "Overwhelming"
        }
    }

    // MARK: Withdrawal symptom log (SennelSymptoms.dc.html)

    enum Symptom: String, CaseIterable, Identifiable {
        case irritability = "Irritability", brainFog = "Brain fog", insomnia = "Insomnia"
        case anxiety = "Anxiety", cravings = "Cravings"
        var id: String { rawValue }
    }

    struct SymptomDay {
        var day: Date
        var severities: [Symptom: Int] // 0 none, 1 mild, 2 strong
    }

    var symptomDays: [SymptomDay] = AppState.seedSymptomDays()

    private static func seedSymptomDays() -> [SymptomDay] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        // Generally trending down across the last 7 days, matching the prototype.
        let matrix: [Symptom: [Int]] = [
            .irritability: [2, 2, 2, 1, 1, 1, 0],
            .brainFog: [2, 2, 1, 1, 1, 0, 1],
            .insomnia: [1, 2, 1, 1, 0, 0, 0],
            .anxiety: [2, 1, 1, 1, 1, 0, 0],
            .cravings: [2, 2, 2, 1, 1, 1, 1],
        ]
        return (0..<7).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            var severities = [Symptom: Int]()
            for (symptom, values) in matrix {
                severities[symptom] = values[6 - offset]
            }
            return SymptomDay(day: day, severities: severities)
        }
    }

    func severity(for symptom: Symptom, on date: Date, calendar: Calendar = .current) -> Int? {
        let day = calendar.startOfDay(for: date)
        return symptomDays.first { calendar.isDate($0.day, inSameDayAs: day) }?.severities[symptom]
    }

    func logSymptom(_ symptom: Symptom, severity: Int, on date: Date = .now, calendar: Calendar = .current) {
        let day = calendar.startOfDay(for: date)
        if let index = symptomDays.firstIndex(where: { calendar.isDate($0.day, inSameDayAs: day) }) {
            symptomDays[index].severities[symptom] = severity
        } else {
            symptomDays.append(SymptomDay(day: day, severities: [symptom: severity]))
        }
    }

    /// Last 7 days, oldest first, padding in empty days so the grid always has 7 columns.
    func recentSymptomDays(at date: Date, calendar: Calendar = .current) -> [SymptomDay] {
        let today = calendar.startOfDay(for: date)
        return (0..<7).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            return symptomDays.first { calendar.isDate($0.day, inSameDayAs: day) } ?? SymptomDay(day: day, severities: [:])
        }
    }

    func symptomTrendIsDown(at date: Date, calendar: Calendar = .current) -> Bool {
        let days = recentSymptomDays(at: date, calendar: calendar)
        guard let first = days.first, let last = days.last else { return false }
        let firstTotal = first.severities.values.reduce(0, +)
        let lastTotal = last.severities.values.reduce(0, +)
        return lastTotal <= firstTotal
    }

    // MARK: Insights (SennelInsights.dc.html)

    /// Per-day pouch counts going back from `date`, plus first-half-vs-second-half % change.
    func pouchTrend(at date: Date, spanDays: Int = 14, calendar: Calendar = .current) -> (days: [(date: Date, count: Int)], percentChange: Int) {
        let today = calendar.startOfDay(for: date)
        let days: [(Date, Int)] = (0..<spanDays).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            let count = calendar.isDate(day, inSameDayAs: today) ? usedToday : (dailyPouchCounts[day] ?? 0)
            return (day, count)
        }
        let half = spanDays / 2
        let firstHalf = days.prefix(half).reduce(0) { $0 + $1.1 }
        let secondHalf = days.suffix(half).reduce(0) { $0 + $1.1 }
        let percent = firstHalf > 0 ? Int(((Double(firstHalf) - Double(secondHalf)) / Double(firstHalf) * 100).rounded()) : 0
        return (days, percent)
    }

    func topTrigger(at date: Date, days: Int = 30) -> (label: String, percent: Int)? {
        let cutoff = date.addingTimeInterval(-Double(days) * 86_400)
        let recent = cravingEntries.filter { $0.date >= cutoff }
        guard !recent.isEmpty else { return nil }
        let counts = Dictionary(grouping: recent, by: \.trigger).mapValues(\.count)
        guard let top = counts.max(by: { $0.value < $1.value }) else { return nil }
        return (top.key, Int((Double(top.value) / Double(recent.count) * 100).rounded()))
    }

    func avgCravingIntensity(at date: Date, days: Int = 7) -> Double? {
        let cutoff = date.addingTimeInterval(-Double(days) * 86_400)
        let recent = cravingEntries.filter { $0.date >= cutoff }
        guard !recent.isEmpty else { return nil }
        return Double(recent.map(\.intensity).reduce(0, +)) / Double(recent.count)
    }

    func cravingsByTimeOfDay(at date: Date, days: Int = 30, calendar: Calendar = .current) -> [(label: String, count: Int)] {
        let labels = ["6a", "9a", "12p", "3p", "6p", "9p"]
        let cutoff = date.addingTimeInterval(-Double(days) * 86_400)
        var counts = [Int](repeating: 0, count: labels.count)
        for entry in cravingEntries where entry.date >= cutoff {
            let hour = calendar.component(.hour, from: entry.date)
            counts[min(labels.count - 1, hour / 4)] += 1
        }
        return zip(labels, counts).map { ($0, $1) }
    }

    // MARK: Badges (SennelBadges.dc.html)

    struct Badge: Identifiable {
        let title: String
        let detail: String
        let isEarned: (AppState, Date) -> Bool
        var id: String { title }
    }

    static let badgeCatalog: [Badge] = [
        Badge(title: "First Day", detail: "Made it through day one.") { s, d in s.lifetimeDaysClean(at: d) >= 1 },
        Badge(title: "3 Days", detail: "The hardest stretch, behind you.") { s, d in s.lifetimeDaysClean(at: d) >= 3 },
        Badge(title: "One Week", detail: "Seven days clean.") { s, d in s.lifetimeDaysClean(at: d) >= 7 },
        Badge(title: "Two Weeks", detail: "14 days clean. The hardest part is behind you.") { s, d in s.lifetimeDaysClean(at: d) >= 14 },
        Badge(title: "One Month", detail: "A full month clean.") { s, d in s.lifetimeDaysClean(at: d) >= 30 },
        Badge(title: "50 Days", detail: "Fifty days clean.") { s, d in s.lifetimeDaysClean(at: d) >= 50 },
        Badge(title: "$50 Saved", detail: "Fifty dollars back in your pocket.") { s, d in s.lifetimeMoneySaved(at: d) >= 50 },
        Badge(title: "$100 Saved", detail: "A hundred dollars saved.") { s, d in s.lifetimeMoneySaved(at: d) >= 100 },
        Badge(title: "$250 Saved", detail: "Two-fifty saved and counting.") { s, d in s.lifetimeMoneySaved(at: d) >= 250 },
        Badge(title: "10 Resisted", detail: "Ten cravings you rode out.") { s, _ in s.cravingEntries.filter { $0.outcome == .rodeItOut }.count >= 10 },
        Badge(title: "Under Limit", detail: "Stayed under today's limit.") { s, _ in s.usedToday < s.dailyLimit },
        Badge(title: "Breathe 10x", detail: "Ten guided breathing sessions.") { s, _ in s.breathingSessionsCompleted >= 10 },
    ]

    func earnedBadges(at date: Date) -> [Badge] {
        AppState.badgeCatalog.filter { $0.isEarned(self, date) }
    }

    /// The most advanced badge currently earned — shown as the hero "Just earned" card.
    func heroBadge(at date: Date) -> Badge? {
        earnedBadges(at: date).last
    }

    // MARK: Actions

    private(set) var dailyPouchCounts: [Date: Int] = AppState.seedDailyPouchCounts()

    private static func seedDailyPouchCounts() -> [Date: Int] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        // 13 days before today, trending down — matches the Insights prototype's sample.
        let counts = [8, 8, 7, 8, 7, 6, 7, 6, 5, 5, 4, 5, 3]
        var result = [Date: Int]()
        for (offset, count) in counts.reversed().enumerated() {
            if let day = calendar.date(byAdding: .day, value: -(offset + 1), to: today) {
                result[day] = count
            }
        }
        return result
    }

    func logPouch() {
        usedToday += 1
        let day = Calendar.current.startOfDay(for: .now)
        dailyPouchCounts[day] = usedToday
    }
}
