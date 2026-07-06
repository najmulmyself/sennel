import ActivityKit
import Foundation

struct SennelScheduleActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var nextEligibleSlot: Date
        var usedToday: Int
        var dailyLimit: Int
    }

    var irrelevantAdContent: String
}
