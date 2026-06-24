import SwiftUI
import SwiftData

@main
@MainActor
struct SennelApp: App {
    private let modelContainer: ModelContainer
    @State private var appState: AppState
    @State private var storeManager: StoreManager

    init() {
        let container = SennelPersistence.makeContainer()
        modelContainer = container
        let state = AppState(modelContext: ModelContext(container))
        _appState = State(initialValue: state)
        _storeManager = State(initialValue: StoreManager(onEntitlementChange: { isPremium in
            state.setPremium(isPremium)
        }))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(storeManager)
                .preferredColorScheme(appState.isDarkMode ? .dark : .light)
                .task { storeManager.start() }
        }
        .modelContainer(modelContainer)
    }
}
