import SwiftUI

/// The real 5-tab shell (Home/Schedule/Insights/Health/Settings) that replaces
/// the prototype's disconnected screen gallery. Tab bar stays native system
/// glass per sennel_design.md Section 5 — no custom tint.
struct MainTabView: View {
    private enum Tab { case home, schedule, insights, health, settings }

    @Environment(AppState.self) private var appState
    @Environment(NotificationManager.self) private var notificationManager
    @Environment(\.scenePhase) private var scenePhase

    @State private var selection: Tab = .home
    @State private var showingPaywall = false

    var body: some View {
        TabView(selection: $selection) {
            HomeView(onSettingsTap: { selection = .settings })
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(Tab.home)

            ScheduleView()
                .tabItem { Label("Schedule", systemImage: "clock.fill") }
                .tag(Tab.schedule)

            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }
                .tag(Tab.insights)

            HealthView()
                .tabItem { Label("Health", systemImage: "heart.fill") }
                .tag(Tab.health)

            SettingsView(onPremiumTap: { showingPaywall = true })
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(Tab.settings)
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .task {
            await notificationManager.refreshAuthorizationStatus()
            notificationManager.reschedule(for: appState)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    await notificationManager.refreshAuthorizationStatus()
                    notificationManager.reschedule(for: appState)
                }
            }
        }
        .onChange(of: appState.dailyLimit) { _, _ in notificationManager.reschedule(for: appState) }
        .onChange(of: appState.usedToday) { _, _ in notificationManager.reschedule(for: appState) }
        .onChange(of: notificationManager.pendingScheduleTap) { _, tapped in
            guard tapped else { return }
            selection = .schedule
            notificationManager.pendingScheduleTap = false
        }
    }
}

#Preview {
    MainTabView()
        .environment(AppState())
        .environment(StoreManager(onEntitlementChange: { _ in }))
        .environment(NotificationManager())
}
