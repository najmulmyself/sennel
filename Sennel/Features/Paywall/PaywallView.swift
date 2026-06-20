import SwiftUI
import StoreKit

/// Soft paywall — real content visible underneath via blur, never a hard lock screen
/// (design doc §10). Compliance requirements baked in per technical spec §8: price +
/// billing period visible, working Restore Purchases, Privacy Policy / Terms links.
struct PaywallView: View {
    @State private var storeKit = StoreKitService.shared

    var body: some View {
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
        .padding(Spacing.md)
    }
}
