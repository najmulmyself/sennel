import SwiftUI
import SwiftData
import StoreKit

/// Soft paywall — real content visible underneath via blur, never a hard lock screen
/// (design doc §10). Compliance requirements baked in per technical spec §8: price +
/// billing period visible, working Restore Purchases, Privacy Policy / Terms links.
/// Card is glass-tinted with the current progressive streak color (design doc §5).
struct PaywallView: View {
    @State private var storeKit = StoreKitService.shared
    @Query private var settingsList: [UserSettings]

    private var stage: StreakStage {
        guard let settings = settingsList.first else { return .stage0 }
        return StreakCalculator.streakStage(forDays: StreakCalculator.currentStreakDays(from: settings.quitStartDate))
    }

    var body: some View {
        GlassCard(tint: Color.color(for: stage)) {
            VStack(spacing: Spacing.lg) {
                Text("Sennel Premium")
                    .font(.largeTitle)

                if let product = storeKit.monthlyProduct {
                    Text("\(product.displayPrice) / month")
                        .font(.headline)
                }

                Button("Subscribe") {
                    guard let product = storeKit.monthlyProduct else { return }
                    Task { try? await storeKit.purchase(product) }
                }
                .buttonStyle(.borderedProminent)

                Button("Restore Purchases") {
                    Task { await storeKit.restorePurchases() }
                }

                HStack(spacing: Spacing.md) {
                    Link("Privacy Policy", destination: URL(string: "https://sennel.app/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://sennel.app/terms")!)
                }
                .font(.caption)
            }
        }
        .padding(Spacing.md)
    }
}

#Preview {
    PaywallView()
        .modelContainer(for: [UserSettings.self, PouchLog.self, RelapseEvent.self], inMemory: true)
}
