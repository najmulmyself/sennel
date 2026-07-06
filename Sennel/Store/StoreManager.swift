import StoreKit

/// Owns the StoreKit2 transaction stream. Never trust a cached premium flag
/// alone — `start()` and the `Transaction.updates` listener both funnel through
/// `refreshEntitlements()`, the only place that calls `onEntitlementChange`.
@MainActor
@Observable
final class StoreManager {
    private(set) var products: [Product] = []
    var purchaseError: String?

    private let onEntitlementChange: (Bool) -> Void
    /// `nonisolated(unsafe)` so `deinit` (always nonisolated for classes) can cancel
    /// it directly — safe because `Task.cancel()` is documented thread-safe.
    private nonisolated(unsafe) var updatesTask: Task<Void, Never>?

    init(onEntitlementChange: @escaping (Bool) -> Void) {
        self.onEntitlementChange = onEntitlementChange
    }

    deinit {
        updatesTask?.cancel()
    }

    func start() {
        updatesTask = listenForTransactionUpdates()
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    func loadProducts() async {
        products = (try? await Product.products(for: ProductIDs.all)) ?? []
    }

    func purchase(_ product: Product) async {
        purchaseError = nil
        do {
            let result = try await product.purchase()
            if case .success(let verification) = result, case .verified(let transaction) = verification {
                await transaction.finish()
                await refreshEntitlements()
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    func restorePurchases() async {
        purchaseError = nil
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    private func refreshEntitlements() async {
        var hasActiveEntitlement = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, ProductIDs.all.contains(transaction.productID) {
                hasActiveEntitlement = true
            }
        }
        onEntitlementChange(hasActiveEntitlement)
    }

    private func listenForTransactionUpdates() -> Task<Void, Never> {
        Task {
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                await transaction.finish()
                await refreshEntitlements()
            }
        }
    }
}
