import Foundation
import SwiftData

/// One row per calendar day — replaces `AppState`'s `[Date: Int]` dictionary,
/// which SwiftData can't persist directly. "One row per day" is enforced in the
/// write path (query-then-update-or-insert in `AppState.logPouch`), not a DB constraint.
@Model
final class PouchCountModel {
    /// Always calendar-day-normalized (`Calendar.startOfDay`) before storing.
    var day: Date
    var count: Int

    init(day: Date, count: Int) {
        self.day = day
        self.count = count
    }
}
