# Sennel — Technical Implementation Spec
**For Claude Code. Source: `Nicotine cessation app prd.md` + `sennel_design.md`. Read both before starting — this doc assumes their decisions and doesn't re-justify them.**

Platform: native Swift/SwiftUI, iOS 26+ minimum deployment target. No third-party dependencies in Phase 1 except dev-only tooling (InjectionIII) which is excluded from Release builds.

---

## 1. Tech Stack

| Layer | Choice | Why (per PRD) |
|---|---|---|
| UI | SwiftUI | Native craft is the core differentiation strategy |
| Persistence | SwiftData | Less boilerplate than CoreData, pairs with `@Observable` |
| State | `@Observable` macro (not `ObservableObject`) | Modern pattern, less ceremony |
| IAP | StoreKit2 | Single $3.99/mo subscription in Phase 1, annual + lifetime in Phase 2 |
| Notifications | `UNUserNotificationCenter` (local only — no push server needed) | Interval scheduler, milestones |
| Charts (Phase 2) | Swift Charts | Native, no dependency |
| Widgets/Live Activity (Phase 2) | WidgetKit + ActivityKit | Dynamic Island countdown |
| Dev loop | VS Code + SweetPad + Xcode (Previews/signing/submission) + InjectionIII | Already established workflow |

---

## 2. Project Structure

Feature-first, not type-first — easier to build and test one PRD phase at a time.

```
Sennel/
├── Sennel.xcodeproj
├── Sennel/
│   ├── App/
│   │   └── SennelApp.swift                 // @main, ModelContainer setup
│   ├── Core/
│   │   ├── DesignSystem/
│   │   │   ├── Color+Sennel.swift          // every token from sennel_design.md §2
│   │   │   ├── Font+Sennel.swift
│   │   │   ├── Spacing+Sennel.swift
│   │   │   ├── StreakRingView.swift        // shared component, used on Home + as icon reference
│   │   │   └── GlassCard.swift             // reusable glass container wrapper
│   │   ├── Persistence/
│   │   │   └── PersistenceController.swift
│   │   └── Services/
│   │       ├── StreakCalculator.swift      // pure logic, no SwiftUI/SwiftData imports — unit test this
│   │       ├── NotificationService.swift
│   │       ├── StoreKitService.swift
│   │       └── HapticService.swift
│   ├── Models/
│   │   ├── PouchLog.swift                  // @Model
│   │   ├── UserSettings.swift              // @Model, singleton row
│   │   └── RelapseEvent.swift              // @Model
│   ├── Features/
│   │   ├── Onboarding/
│   │   │   ├── OnboardingView.swift
│   │   │   └── OnboardingViewModel.swift
│   │   ├── Home/
│   │   │   ├── HomeView.swift
│   │   │   └── HomeViewModel.swift
│   │   ├── HealthTimeline/
│   │   ├── IntervalScheduler/
│   │   ├── Paywall/
│   │   │   ├── PaywallView.swift
│   │   │   └── StoreKitService+Products.swift
│   │   └── Settings/
│   └── Resources/
│       └── Assets.xcassets/                // includes Sennel-AppIcon-1024.png as the single-size app icon
├── SennelWidgets/                          // Phase 2 — separate target, add only when Phase 1 ships
└── SennelTests/
    └── StreakCalculatorTests.swift
```

---

## 3. Data Models (SwiftData)

```swift
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

@Model
final class PouchLog {
    var timestamp: Date
    var brand: String?      // optional, neutral/factual per design doc §6 — never promotional
    var strength: String?

    init(timestamp: Date = .now, brand: String? = nil, strength: String? = nil) {
        self.timestamp = timestamp
        self.brand = brand
        self.strength = strength
    }
}

@Model
final class RelapseEvent {
    var timestamp: Date
    var shieldUsed: Bool       // true if a streak shield absorbed this, false if streak reset
    var previousStreakDays: Int // preserved for history even after reset — "no judgment" requirement

    init(timestamp: Date = .now, shieldUsed: Bool, previousStreakDays: Int) {
        self.timestamp = timestamp
        self.shieldUsed = shieldUsed
        self.previousStreakDays = previousStreakDays
    }
}
```

**Phase 2 additions (don't build yet):** `CravingLog` (timestamp, intensity, trigger), `WithdrawalSymptomEntry` (date, symptom matrix). Stub these out only when Phase 2 starts — building them early violates the PRD's "cut anything not in the Phase 1 table" rule.

```swift
// SennelApp.swift
import SwiftUI
import SwiftData

@main
struct SennelApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([UserSettings.self, PouchLog.self, RelapseEvent.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        // No CloudKit container in Phase 1 — local-only per the privacy doc.
        // Revisit only alongside the Phase 2 iCloud sync decision (PRD §13 open questions).
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
```

---

## 4. Core Business Logic — `StreakCalculator.swift`

Keep this file pure (no SwiftUI, no SwiftData imports) so it's trivially unit-testable.

```swift
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
}
```

`SennelTests/StreakCalculatorTests.swift` should cover: stage boundaries (day 2 vs 3, day 7 vs 8, day 29 vs 30), money-saved math, and interval-scheduler math with edge cases (dailyGoal = 0 shouldn't divide by zero — already guarded above with `max(dailyGoal, 1)`).

---

## 5. Design System Bridge — `Color+Sennel.swift`

Pulls every value directly from `sennel_design.md` §2. If a designer (or future you) changes a token, it changes here and nowhere else.

```swift
import SwiftUI

extension Color {
    // Brand gradient
    static let brandTealLight = Color(light: "#2DD4BF", dark: "#2DD4BF")
    static let brandEmeraldDeep = Color(light: "#047857", dark: "#047857")

    // Progressive streak stages
    static let streakStage0 = Color(light: "#94A3B8", dark: "#94A3B8")
    static let streakStage1 = Color(light: "#5EEAD4", dark: "#5EEAD4")
    static let streakStage2 = Color(light: "#2DD4BF", dark: "#2DD4BF")
    static let streakStage3 = Color(light: "#047857", dark: "#047857")

    static func color(for stage: StreakStage) -> Color {
        switch stage {
        case .stage0: return .streakStage0
        case .stage1: return .streakStage1
        case .stage2: return .streakStage2
        case .stage3: return .streakStage3
        }
    }

    // Surfaces & text — these DO differ light/dark, per the design doc
    static let surfaceBackground = Color(light: "#FAFAF9", dark: "#0B1410")
    static let surfaceCard = Color(light: "#FFFFFF", dark: "#13201C")
    static let textPrimary = Color(light: "#0F172A", dark: "#ECFDF5")
    static let textSecondary = Color(light: "#64748B", dark: "#9CA8A4")

    // Functional accents
    static let accentShield = Color(light: "#F59E0B", dark: "#F59E0B")
    static let accentLock = Color(light: "#94A3B8", dark: "#94A3B8")

    /// Helper: build a Color that resolves differently per light/dark mode from hex strings.
    init(light: String, dark: String) {
        self.init(uiColor: UIColor(dynamicProvider: { trait in
            UIColor(hex: trait.userInterfaceStyle == .dark ? dark : light)
        }))
    }
}

extension UIColor {
    convenience init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        s = s.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        self.init(
            red: CGFloat((rgb & 0xFF0000) >> 16) / 255,
            green: CGFloat((rgb & 0x00FF00) >> 8) / 255,
            blue: CGFloat(rgb & 0x0000FF) / 255,
            alpha: 1
        )
    }
}
```

Animate stage transitions per the design doc — never snap:

```swift
// In HomeView:
.animation(.easeInOut(duration: 1.2), value: streakStage)
```

---

## 6. ViewModel Pattern — `HomeViewModel.swift`

```swift
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
```

---

## 7. Notifications — `NotificationService.swift`

Request permission **after** the user's first pouch log or when they first engage the interval scheduler — never on cold launch. The PRD's "first 30 seconds" screen has zero interruptions; a permission dialog on top of it would violate that directly.

```swift
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
```

If permission is denied, the interval scheduler still works **in-app** (countdown shown on the Home/Scheduler screen) — it just degrades gracefully without push reminders. Don't gate the feature on permission being granted.

---

## 8. StoreKit2 — `StoreKitService.swift`

Phase 1 needs exactly one product. Don't build the annual/lifetime product handling until Phase 2 — but do build the entitlement-checking architecture generically so adding products later is a config change, not a rewrite.

```swift
import StoreKit
import Observation

enum SennelProduct: String, CaseIterable {
    case monthly = "com.yourcompany.sennel.premium.monthly"
    // Phase 2: case annual = "com.yourcompany.sennel.premium.annual"
    // Phase 2: case lifetime = "com.yourcompany.sennel.premium.lifetime"
}

@Observable
final class StoreKitService {
    static let shared = StoreKitService()

    var products: [Product] = []
    var isPremium: Bool = false
    private var updateListenerTask: Task<Void, Error>?

    init() {
        updateListenerTask = listenForTransactions()
        Task { await loadProducts(); await refreshEntitlements() }
    }

    func loadProducts() async {
        products = (try? await Product.products(for: SennelProduct.allCases.map(\.rawValue))) ?? []
    }

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            if case .verified(let transaction) = verification {
                await transaction.finish()
                await refreshEntitlements()
            }
        default:
            break
        }
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    func refreshEntitlements() async {
        var premium = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               SennelProduct(rawValue: transaction.productID) != nil {
                premium = true
            }
        }
        isPremium = premium
    }

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await self.refreshEntitlements()
                    await transaction.finish()
                }
            }
        }
    }
}
```

**Compliance reminders baked into the Paywall view (not optional, see compliance doc §5):** price + billing period visible on the paywall card itself, a working "Restore Purchases" button wired to `restorePurchases()` above, and Privacy Policy / Terms links visible on the same screen.

---

## 9. Build Order

Build and get each step running on-device before moving to the next — this is a solo-dev project with a 5–7 week Phase 1 budget, not a big-bang build.

1. **Scaffold:** Xcode project, SwiftData models (§3), design system extensions (§5) — get the app launching to a blank screen with correct colors in both light/dark mode before writing any feature.
2. **Onboarding:** 2-screen flow, writes `UserSettings` on completion.
3. **Home screen core loop:** streak ring + Hero Numbers + log button, wired to `HomeViewModel`. This is the PRD's "first 30 seconds" screen — get it feeling right before anything else.
4. **Money saved + streak stage color animation.**
5. **Health Timeline** (static milestone list, flat per design doc §10).
6. **Interval Scheduler (Lite)** + `NotificationService`.
7. **Relapse/restart flow** — calm fade, shield logic, history preservation.
8. **Soft paywall UI** — build it locked/non-functional first (so the visual design is right), then wire StoreKit.
9. **StoreKit2 integration** (§8) — single monthly SKU.
10. **Accessibility pass** — Dynamic Type at largest size, VoiceOver labels, Reduce Motion fallbacks, across every screen built so far.
11. **Dark mode pass** — verify every screen in both modes.
12. **App icon** — drop `Sennel-AppIcon-1024.png` into the single-size Asset Catalog slot.
13. **TestFlight build** — internal testing before App Store submission.

Phase 2/3 features (widgets, Live Activity, charts, AI coach, Watch app) start only after this list ships and the PRD's Phase 1 success metrics show signal — don't pull them forward.

---

## 10. Edge Cases to Handle Explicitly

- **SwiftData container fails to load:** shouldn't `fatalError` in production — Phase 1 can keep the `fatalError` during development, but add a real recovery path (rebuild store, show a non-technical error screen) before TestFlight.
- **Notification permission denied:** interval scheduler degrades to in-app-only (§7) — never block the feature.
- **Timezone/day-boundary changes** (user travels, DST): `StreakCalculator` uses `Calendar.current` day components rather than raw `TimeInterval` math specifically to avoid off-by-one-day bugs across timezone shifts — keep it that way, don't "simplify" to `Date.timeIntervalSince`.
- **StoreKit transaction fails verification:** treat as not-purchased, don't grant entitlement, don't crash.
- **dailyGoal = 0:** already guarded in `nextEligibleTime` (§4) — don't remove that guard.

---

## 11. Testing

- **Unit test `StreakCalculator` and `StoreKitService` entitlement logic** — pure functions, cheap to test, highest bug-risk-per-line in the app since they're financial/streak-integrity logic.
- **Manual accessibility pass** per design doc §12 checklist — VoiceOver and Dynamic Type are impractical to fully automate for a solo dev; budget real device time for this rather than skipping it.
- UI tests are a nice-to-have, not a Phase 1 requirement — don't spend budget there before the core loop is solid.

---

## 12. What NOT to Build Yet

Mirrors the PRD's explicit Phase 1 exclusions — repeating here so it's unambiguous at the code level: no `CravingLog` or `WithdrawalSymptomEntry` models, no Widget extension target, no ActivityKit, no Swift Charts, no AI coach networking code, no Watch target, no App Intents. Adding any of these before Phase 1 ships is scope creep against the PRD's explicit "ship dirty, ship fast" mandate.
