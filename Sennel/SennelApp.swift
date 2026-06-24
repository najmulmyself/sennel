import SwiftUI
import SwiftData

@main
struct SennelApp: App {
    private let modelContainer: ModelContainer
    @State private var appState: AppState

    init() {
        let container = SennelPersistence.makeContainer()
        modelContainer = container
        _appState = State(initialValue: AppState(modelContext: ModelContext(container)))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .preferredColorScheme(appState.isDarkMode ? .dark : .light)
        }
        .modelContainer(modelContainer)
    }
}
