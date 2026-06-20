import SwiftData
import Foundation

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
