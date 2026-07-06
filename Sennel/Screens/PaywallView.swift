import SwiftUI
import StoreKit

/// Presented as a sheet from every premium gate (Insights teaser, Settings'
/// premium banner). `StoreManager` owns the live product/purchase state;
/// `AppState.isPremium` — reconciled by `StoreManager` — is what every other
/// screen actually gates on, not anything read directly from here.
struct PaywallView: View {
    @Environment(AppState.self) private var appState
    @Environment(StoreManager.self) private var storeManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var showingManageSubscriptions = false
    @State private var isPurchasing = false

    var body: some View {
        let theme = SennelTheme(dark: colorScheme == .dark, stage: appState.stage(at: .now))
        let accent = SennelTheme.brandTeal(dark: theme.dark)

        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: SennelSpace.lg) {
                        header(theme: theme, accent: accent)

                        if appState.isPremium {
                            subscribedCard(theme: theme, accent: accent)
                        } else {
                            productList(theme: theme, accent: accent)
                            restoreButton(theme: theme)
                        }

                        legalLinks(theme: theme)
                    }
                    .padding(.horizontal, SennelSpace.lg)
                    .padding(.top, SennelSpace.lg)
                    .padding(.bottom, SennelSpace.xl)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .manageSubscriptionsSheet(isPresented: $showingManageSubscriptions)
            .task {
                if storeManager.products.isEmpty {
                    await storeManager.loadProducts()
                }
            }
        }
    }

    // MARK: Header

    private func header(theme: SennelTheme, accent: Color) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 36))
                .foregroundStyle(accent)
            Text("Sennel Premium")
                .font(.title.weight(.bold))
                .foregroundStyle(theme.textPrimary)
            Text("Full Insights analytics, home screen widgets, and a Live Activity countdown.")
                .font(.subheadline)
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, SennelSpace.md)
    }

    // MARK: Subscribed state

    private func subscribedCard(theme: SennelTheme, accent: Color) -> some View {
        VStack(spacing: SennelSpace.md) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(accent)
                Text("You're subscribed")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(theme.textPrimary)
            }
            Button("Manage Subscription") { showingManageSubscriptions = true }
                .buttonStyle(.bordered)
        }
        .padding(SennelSpace.lg)
        .frame(maxWidth: .infinity)
        .background(theme.card)
        .overlay(RoundedRectangle(cornerRadius: SennelRadius.card, style: .continuous).strokeBorder(theme.hairline))
        .clipShape(RoundedRectangle(cornerRadius: SennelRadius.card, style: .continuous))
    }

    // MARK: Product list

    private func productList(theme: SennelTheme, accent: Color) -> some View {
        VStack(spacing: 12) {
            if storeManager.products.isEmpty {
                ProgressView()
                    .padding(.vertical, SennelSpace.lg)
            } else {
                ForEach(storeManager.products) { product in
                    productRow(product, theme: theme, accent: accent)
                }
            }
            if let error = storeManager.purchaseError {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
    }

    private func productRow(_ product: Product, theme: SennelTheme, accent: Color) -> some View {
        Button {
            guard !isPurchasing else { return }
            isPurchasing = true
            Task {
                await storeManager.purchase(product)
                isPurchasing = false
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(product.displayName)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(theme.textPrimary)
                    if let subscription = product.subscription {
                        Text(subscription.subscriptionPeriod.sennelLabel)
                            .font(.subheadline)
                            .foregroundStyle(theme.textSecondary)
                    }
                }
                Spacer()
                Text(product.displayPrice)
                    .font(.body.weight(.bold))
                    .foregroundStyle(accent)
            }
            .padding(SennelSpace.md)
            .background(theme.card)
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(theme.hairline))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isPurchasing)
    }

    private func restoreButton(theme: SennelTheme) -> some View {
        Button("Restore Purchases") {
            Task { await storeManager.restorePurchases() }
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(theme.textSecondary)
        .padding(.top, SennelSpace.xs)
    }

    // MARK: Legal

    private func legalLinks(theme: SennelTheme) -> some View {
        HStack(spacing: 16) {
            // TODO: swap for the real hosted Terms/Privacy pages before App Store submission.
            Link("Terms of Service", destination: URL(string: "https://sennel.app/terms")!)
            Link("Privacy Policy", destination: URL(string: "https://sennel.app/privacy")!)
        }
        .font(.caption)
        .foregroundStyle(theme.textTertiary)
        .padding(.top, SennelSpace.sm)
    }
}

private extension Product.SubscriptionPeriod {
    var sennelLabel: String {
        switch unit {
        case .day: return value == 1 ? "Daily" : "\(value)-day"
        case .week: return value == 1 ? "Weekly" : "\(value)-week"
        case .month: return value == 1 ? "Monthly" : "\(value)-month"
        case .year: return value == 1 ? "Yearly" : "\(value)-year"
        @unknown default: return ""
        }
    }
}

#Preview {
    PaywallView()
        .environment(AppState())
        .environment(StoreManager(onEntitlementChange: { _ in }))
}
