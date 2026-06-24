import Foundation
import SwiftData

/// One row per (day, symptom) pair — replaces `AppState.SymptomDay`'s
/// `[Symptom: Int]` dictionary, which SwiftData can't persist directly.
/// Reassembled into that grouped shape at read time in `AppState`.
@Model
final class SymptomSeverityModel {
    /// Always calendar-day-normalized (`Calendar.startOfDay`) before storing.
    var day: Date
    var symptomRaw: String
    var severity: Int

    init(day: Date, symptomRaw: String, severity: Int) {
        self.day = day
        self.symptomRaw = symptomRaw
        self.severity = severity
    }
}
