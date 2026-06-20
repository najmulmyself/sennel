import Foundation
import SwiftData
import Observation

/// 2-question onboarding per PRD §7: last pouch time + daily goal only.
@Observable
final class OnboardingViewModel {
    enum LastPouchSelection: Equatable {
        case justNow
        case specificTime
        case earlier
    }

    var lastPouchTime: Date = .now
    var selection: LastPouchSelection = .specificTime
    var dailyGoal: Int = 5
    var step: Int = 0

    var totalSteps: Int { 2 }

    func selectJustNow() {
        selection = .justNow
        lastPouchTime = .now
    }

    func selectSpecificTime(_ date: Date) {
        selection = .specificTime
        lastPouchTime = date
    }

    func selectEarlier(_ date: Date) {
        selection = .earlier
        lastPouchTime = date
    }

    func incrementDailyGoal() {
        dailyGoal = min(dailyGoal + 1, 40)
    }

    func decrementDailyGoal() {
        dailyGoal = max(dailyGoal - 1, 1)
    }

    func advance() {
        step = min(step + 1, totalSteps - 1)
    }

    func resetCurrentStep() {
        switch step {
        case 0:
            selection = .specificTime
            lastPouchTime = .now
        default:
            dailyGoal = 5
        }
    }

    func completeOnboarding(modelContext: ModelContext) {
        let settings = UserSettings(quitStartDate: lastPouchTime, dailyGoal: dailyGoal)
        modelContext.insert(settings)
        try? modelContext.save()
    }
}
