import SwiftUI
import SwiftData

/// App state shared across every screen, backed by SwiftData. `AppState` stays
/// the `@Observable` façade every view binds to via `@Environment(AppState.self)`;
/// underneath, scalar fields live in a single `UserProfile` row and the growing
/// collections (cravings/symptoms/pouch counts) live in their own models, but
/// every existing call site and pure `at(date:)` function is unchanged.
@Observable
@MainActor
final class AppState {
    private let modelContext: ModelContext
    private var profile: UserProfile
    private var liveActivityManager: LiveActivityManager?

    var hasOnboarded: Bool { didSet { saveProfile() } }

    /// The moment the streak started — "last pouch" from onboarding step 1.
    var startDate: Date { didSet { saveProfile() } }

    var dailyLimit: Int { didSet { saveProfile() } }
    var dailySpend: Double { didSet { saveProfile() } }
    var usedToday: Int { didSet { saveProfile() } }

    /// Manual override toggled from Settings — re-themes the whole app, the same
    /// way SennelApp's prototype dark-mode switch worked (not tied to system appearance).
    var isDarkMode: Bool { didSet { saveProfile() } }

    /// Drives `NotificationManager.reschedule(for:)` — flipped from Settings,
    /// gated there on the system permission actually being granted.
    var remindersOn: Bool { didSet { saveProfile() } }

    /// Cached gate for premium screens (Insights, widgets, Live Activity). The
    /// source of truth is StoreKit's transaction stream — `StoreManager` reconciles
    /// this on launch and on every `Transaction.updates` event via `setPremium`.
    private(set) var isPremium: Bool { didSet { saveProfile() } }

    // MARK: Phase 2 — lifetime stats (survive a restart, unlike `startDate`)

    /// Days/money banked from streaks that ended before this one — added to the
    /// current streak's numbers so a restart never erases earned badges or "this
    /// stays yours" totals (sennel_design.md Section 14: no shame-coded relapse UI).
    private(set) var priorStreakDays: Int { didSet { saveProfile() } }
    private(set) var priorMoneySaved: Double { didSet { saveProfile() } }
    private(set) var streakShieldsRemaining: Int { didSet { saveProfile() } }
    private(set) var streakShieldsTotal: Int { didSet { saveProfile() } }
    private(set) var breathingSessionsCompleted: Int { didSet { saveProfile() } }

    init(modelContext: ModelContext = ModelContext(SennelPersistence.makeInMemoryContainer())) {
        self.modelContext = modelContext
        let profile = AppState.fetchOrCreateProfile(in: modelContext)
        self.profile = profile
        self.hasOnboarded = profile.hasOnboarded
        self.startDate = profile.startDate
        self.dailyLimit = profile.dailyLimit
        self.dailySpend = profile.dailySpend
        self.usedToday = profile.usedToday
        self.isDarkMode = profile.isDarkMode
        self.remindersOn = profile.remindersOn
        self.isPremium = profile.isPremium
        self.priorStreakDays = profile.priorStreakDays
        self.priorMoneySaved = profile.priorMoneySaved
        self.streakShieldsRemaining = profile.streakShieldsRemaining
        self.streakShieldsTotal = profile.streakShieldsTotal
        self.breathingSessionsCompleted = profile.breathingSessionsCompleted
        self.cravingEntries = AppState.fetchCravingEntries(in: modelContext)
        self.symptomDays = AppState.fetchSymptomDays(in: modelContext)
        self.dailyPouchCounts = AppState.fetchDailyPouchCounts(in: modelContext)
    }

    private func saveProfile() {
        profile.hasOnboarded = hasOnboarded
        profile.startDate = startDate
        profile.dailyLimit = dailyLimit
        profile.dailySpend = dailySpend
        profile.usedToday = usedToday
        profile.isDarkMode = isDarkMode
        profile.remindersOn = remindersOn
        profile.isPremium = isPremium
        profile.priorStreakDays = priorStreakDays
        profile.priorMoneySaved = priorMoneySaved
        profile.streakShieldsRemaining = streakShieldsRemaining
        profile.streakShieldsTotal = streakShieldsTotal
        profile.breathingSessionsCompleted = breathingSessionsCompleted
        try? modelContext.save()
    }

    private static func fetchOrCreateProfile(in context: ModelContext) -> UserProfile {
        if let existing = try? context.fetch(FetchDescriptor<UserProfile>()).first {
            return existing
        }
        let profile = UserProfile()
        context.insert(profile)
        try? context.save()
        return profile
    }

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

    /// Called by `StoreManager` whenever it reconciles against StoreKit's
    /// transaction stream — never set directly from UI.
    func setPremium(_ value: Bool) {
        isPremium = value
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
        enum Outcome: String { case rodeItOut, used }
    }

    static let cravingTriggers = ["After meals", "Coffee", "Stress", "Boredom", "Driving", "Social", "Alcohol", "Phone"]

    var cravingEntries: [CravingEntry] = []

    func logCraving(intensity: Int, trigger: String, outcome: CravingEntry.Outcome) {
        let entry = CravingEntry(date: .now, intensity: intensity, trigger: trigger, outcome: outcome)
        cravingEntries.append(entry)
        modelContext.insert(CravingEntryModel(date: entry.date, intensity: entry.intensity, trigger: entry.trigger, outcomeRaw: outcome.rawValue))
        try? modelContext.save()
    }

    private static func fetchCravingEntries(in context: ModelContext) -> [CravingEntry] {
        let models = (try? context.fetch(FetchDescriptor<CravingEntryModel>(sortBy: [SortDescriptor(\.date)]))) ?? []
        return models.compactMap { model in
            guard let outcome = CravingEntry.Outcome(rawValue: model.outcomeRaw) else { return nil }
            return CravingEntry(date: model.date, intensity: model.intensity, trigger: model.trigger, outcome: outcome)
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

    var symptomDays: [SymptomDay] = []

    private static func fetchSymptomDays(in context: ModelContext) -> [SymptomDay] {
        let models = (try? context.fetch(FetchDescriptor<SymptomSeverityModel>())) ?? []
        let calendar = Calendar.current
        var byDay = [Date: SymptomDay]()
        for model in models {
            guard let symptom = Symptom(rawValue: model.symptomRaw) else { continue }
            let day = calendar.startOfDay(for: model.day)
            byDay[day, default: SymptomDay(day: day, severities: [:])].severities[symptom] = model.severity
        }
        return byDay.values.sorted { $0.day < $1.day }
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

        let existingRows = (try? modelContext.fetch(FetchDescriptor<SymptomSeverityModel>())) ?? []
        if let row = existingRows.first(where: { $0.symptomRaw == symptom.rawValue && calendar.isDate($0.day, inSameDayAs: day) }) {
            row.severity = severity
        } else {
            modelContext.insert(SymptomSeverityModel(day: day, symptomRaw: symptom.rawValue, severity: severity))
        }
        try? modelContext.save()
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

    enum BadgeKind: String, CaseIterable, Identifiable, Sendable {
        case firstDay, threeDays, oneWeek, twoWeeks, oneMonth, fiftyDays
        case savedFifty, savedHundred, savedTwoFifty
        case tenResisted, underLimit, breatheTenTimes
        var id: String { rawValue }
    }

    struct Badge: Identifiable, Sendable {
        let kind: BadgeKind
        let title: String
        let detail: String
        var id: String { title }

        @MainActor
        func isEarned(_ state: AppState, _ date: Date) -> Bool {
            AppState.isEarned(kind, state: state, at: date)
        }
    }

    static let badgeCatalog: [Badge] = [
        Badge(kind: .firstDay, title: "First Day", detail: "Made it through day one."),
        Badge(kind: .threeDays, title: "3 Days", detail: "The hardest stretch, behind you."),
        Badge(kind: .oneWeek, title: "One Week", detail: "Seven days clean."),
        Badge(kind: .twoWeeks, title: "Two Weeks", detail: "14 days clean. The hardest part is behind you."),
        Badge(kind: .oneMonth, title: "One Month", detail: "A full month clean."),
        Badge(kind: .fiftyDays, title: "50 Days", detail: "Fifty days clean."),
        Badge(kind: .savedFifty, title: "$50 Saved", detail: "Fifty dollars back in your pocket."),
        Badge(kind: .savedHundred, title: "$100 Saved", detail: "A hundred dollars saved."),
        Badge(kind: .savedTwoFifty, title: "$250 Saved", detail: "Two-fifty saved and counting."),
        Badge(kind: .tenResisted, title: "10 Resisted", detail: "Ten cravings you rode out."),
        Badge(kind: .underLimit, title: "Under Limit", detail: "Stayed under today's limit."),
        Badge(kind: .breatheTenTimes, title: "Breathe 10x", detail: "Ten guided breathing sessions."),
    ]

    private static func isEarned(_ kind: BadgeKind, state: AppState, at date: Date) -> Bool {
        switch kind {
        case .firstDay: return state.lifetimeDaysClean(at: date) >= 1
        case .threeDays: return state.lifetimeDaysClean(at: date) >= 3
        case .oneWeek: return state.lifetimeDaysClean(at: date) >= 7
        case .twoWeeks: return state.lifetimeDaysClean(at: date) >= 14
        case .oneMonth: return state.lifetimeDaysClean(at: date) >= 30
        case .fiftyDays: return state.lifetimeDaysClean(at: date) >= 50
        case .savedFifty: return state.lifetimeMoneySaved(at: date) >= 50
        case .savedHundred: return state.lifetimeMoneySaved(at: date) >= 100
        case .savedTwoFifty: return state.lifetimeMoneySaved(at: date) >= 250
        case .tenResisted: return state.cravingEntries.filter { $0.outcome == .rodeItOut }.count >= 10
        case .underLimit: return state.usedToday < state.dailyLimit
        case .breatheTenTimes: return state.breathingSessionsCompleted >= 10
        }
    }

    func earnedBadges(at date: Date) -> [Badge] {
        AppState.badgeCatalog.filter { $0.isEarned(self, date) }
    }

    /// The most advanced badge currently earned — shown as the hero "Just earned" card.
    func heroBadge(at date: Date) -> Badge? {
        earnedBadges(at: date).last
    }

    // MARK: Actions

    private(set) var dailyPouchCounts: [Date: Int] = [:]

    private static func fetchDailyPouchCounts(in context: ModelContext) -> [Date: Int] {
        let models = (try? context.fetch(FetchDescriptor<PouchCountModel>())) ?? []
        var result = [Date: Int]()
        for model in models {
            result[Calendar.current.startOfDay(for: model.day)] = model.count
        }
        return result
    }

    func logPouch() {
        usedToday += 1
        let day = Calendar.current.startOfDay(for: .now)
        dailyPouchCounts[day] = usedToday

        let existingRows = (try? modelContext.fetch(FetchDescriptor<PouchCountModel>())) ?? []
        if let row = existingRows.first(where: { Calendar.current.isDate($0.day, inSameDayAs: day) }) {
            row.count = usedToday
        } else {
            modelContext.insert(PouchCountModel(day: day, count: usedToday))
        }
        try? modelContext.save()

        // Update Live Activity after persistence succeeds
        if let manager = liveActivityManager {
            manager.updateActivity(for: self)
        }
    }

    /// Called at app startup by `SennelApp` to wire in the Live Activity manager.
    func setLiveActivityManager(_ manager: LiveActivityManager) {
        self.liveActivityManager = manager
    }
}
