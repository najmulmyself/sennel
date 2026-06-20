import Foundation
import SwiftData
import Observation

/// 2-question onboarding per PRD §7: last pouch time + daily goal only.
@Observable
final class OnboardingViewModel {
    var lastPouchTime: Date = .now
    var dailyGoal: Int = 5
    var step: Int = 0

    func completeOnboarding(modelContext: ModelContext) {
        let settings = UserSettings(quitStartDate: lastPouchTime, dailyGoal: dailyGoal)
        modelContext.insert(settings)
        try? modelContext.save()
    }
}
