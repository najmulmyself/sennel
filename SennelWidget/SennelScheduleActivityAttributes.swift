import ActivityKit

struct SennelScheduleActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var nextEligibleSlot: Date
        var usedToday: Int
        var dailyLimit: Int
    }

    var irrelevantAdContent: String
}
