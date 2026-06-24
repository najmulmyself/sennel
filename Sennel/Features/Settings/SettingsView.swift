import SwiftUI
import SwiftData

/// Standard iOS list style, flat, no glass — utility screen (design doc §10).
struct SettingsView: View {
    @Query private var settingsList: [UserSettings]
    @State private var storeKit = StoreKitService.shared
    @State private var showPaywall = false

    var body: some View {
        List {
            if let settings = settingsList.first {
                Section("Daily Goal") {
                    Stepper(value: bindableDailyGoal(settings), in: 1...40) {
                        Text("\(settings.dailyGoal) pouches / day")
                    }
                }

                Section("Cost Tracking") {
                    Stepper(value: bindableCostPerPouch(settings), in: 0.05...2.0, step: 0.05) {
                        Text("Cost per pouch: \(settings.baselineCostPerPouch, format: .currency(code: "USD"))")
                    }
                    Stepper(value: bindableBaselinePouchesPerDay(settings), in: 1...40) {
                        Text("Baseline use: \(settings.baselinePouchesPerDay) / day")
                    }
                }

                Section("Streak Shields") {
                    LabeledContent("Used this month", value: "\(settings.streakShieldsUsedThisMonth) of 3")
                }

                Section("Premium") {
                    if storeKit.isPremium {
                        Label("Premium Active", systemImage: "checkmark.seal.fill")
                    } else {
                        Button("Upgrade to Premium") { showPaywall = true }
                    }
                    Button("Restore Purchases") {
                        Task { await storeKit.restorePurchases() }
                    }
                }
            }

            Section("Notifications") {
                Button("Enable Notifications") {
                    Task { await NotificationService.shared.requestPermissionIfNeeded() }
                }
            }

            Section("Legal") {
                Link("Privacy Policy", destination: URL(string: "https://sennel.app/privacy")!)
                Link("Terms of Service", destination: URL(string: "https://sennel.app/terms")!)
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private func bindableDailyGoal(_ settings: UserSettings) -> Binding<Int> {
        Binding(get: { settings.dailyGoal }, set: { settings.dailyGoal = $0 })
    }

    private func bindableCostPerPouch(_ settings: UserSettings) -> Binding<Double> {
        Binding(get: { settings.baselineCostPerPouch }, set: { settings.baselineCostPerPouch = $0 })
    }

    private func bindableBaselinePouchesPerDay(_ settings: UserSettings) -> Binding<Int> {
        Binding(get: { settings.baselinePouchesPerDay }, set: { settings.baselinePouchesPerDay = $0 })
    }
}

#Preview {
    NavigationStack { SettingsView() }
        .modelContainer(for: [UserSettings.self, PouchLog.self, RelapseEvent.self], inMemory: true)
}
