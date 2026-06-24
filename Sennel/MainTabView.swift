import SwiftUI

/// The real 5-tab shell (Home/Schedule/Insights/Health/Settings) that replaces
/// the prototype's disconnected screen gallery. Tab bar stays native system
/// glass per sennel_design.md Section 5 — no custom tint.
struct MainTabView: View {
    private enum Tab { case home, schedule, insights, health, settings }

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
    }
}

#Preview {
    MainTabView()
        .environment(AppState())
        .environment(StoreManager(onEntitlementChange: { _ in }))
}
