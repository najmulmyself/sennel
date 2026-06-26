import SwiftUI
import SwiftData
import UserNotifications

@main
@MainActor
struct SennelApp: App {
    private let modelContainer: ModelContainer
    @State private var appState: AppState
    @State private var storeManager: StoreManager
    @State private var notificationManager: NotificationManager
    @State private var liveActivityManager: LiveActivityManager

    init() {
        let container = SennelPersistence.makeContainer()
        modelContainer = container
        let state = AppState(modelContext: ModelContext(container))
        _appState = State(initialValue: state)
        _storeManager = State(initialValue: StoreManager(onEntitlementChange: { isPremium in
            state.setPremium(isPremium)
        }))
        let notificationMgr = NotificationManager()
        _notificationManager = State(initialValue: notificationMgr)
        UNUserNotificationCenter.current().delegate = notificationMgr
        let liveActivityMgr = LiveActivityManager()
        _liveActivityManager = State(initialValue: liveActivityMgr)
        state.setLiveActivityManager(liveActivityMgr)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(storeManager)
                .environment(notificationManager)
                .preferredColorScheme(appState.isDarkMode ? .dark : .light)
                .task { storeManager.start() }
        }
        .modelContainer(modelContainer)
    }
}
