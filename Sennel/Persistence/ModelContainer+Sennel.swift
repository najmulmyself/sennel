import Foundation
import SwiftData

enum SennelPersistence {
    /// Shared with the future widget/Live Activity extension (Phase 4/5) so the
    /// store only ever has one home — set this up now rather than migrating
    /// real user data off the default app-sandbox location later.
    static let appGroupID = "group.com.sennel.app"

    static let schema = Schema([
        UserProfile.self,
        CravingEntryModel.self,
        SymptomSeverityModel.self,
        PouchCountModel.self,
    ])

    /// The real on-device container. Falls back to the default app-sandbox
    /// location if the App Group entitlement isn't provisioned yet (it isn't,
    /// until the widget extension target in Phase 4 lands) so the app still runs.
    static func makeContainer() -> ModelContainer {
        let groupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appending(path: "Sennel.sqlite")
        let configuration: ModelConfiguration = if let groupURL {
            ModelConfiguration(schema: schema, url: groupURL)
        } else {
            ModelConfiguration(schema: schema)
        }
        return try! ModelContainer(for: schema, configurations: [configuration])
    }

    /// In-memory container for previews and `AppState()`'s default initializer —
    /// never touches disk, never shares state across instances.
    static func makeInMemoryContainer() -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }
}
