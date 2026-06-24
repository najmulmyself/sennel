import Foundation
import SwiftData

/// Persisted mirror of `AppState.CravingEntry`. `outcome` is stored as its raw
/// string rather than the enum directly since SwiftData's enum support is
/// inconsistent — round-tripped back into `AppState.CravingEntry.Outcome` on read.
@Model
final class CravingEntryModel {
    var date: Date
    var intensity: Int
    var trigger: String
    var outcomeRaw: String

    init(date: Date, intensity: Int, trigger: String, outcomeRaw: String) {
        self.date = date
        self.intensity = intensity
        self.trigger = trigger
        self.outcomeRaw = outcomeRaw
    }
}
