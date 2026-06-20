import SwiftData
import Foundation

final class PersistenceController {
    static let shared = PersistenceController()

    let container: ModelContainer

    private init() {
        let schema = Schema([UserSettings.self, PouchLog.self, RelapseEvent.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        // No CloudKit container in Phase 1 — local-only per the privacy doc.
        // Revisit only alongside the Phase 2 iCloud sync decision (PRD §13 open questions).
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
