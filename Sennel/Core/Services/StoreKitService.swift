import StoreKit
import Observation

enum SennelProduct: String, CaseIterable {
    case monthly = "com.najmulmyself.sennel.premium.monthly"
    // Phase 2: case annual = "com.najmulmyself.sennel.premium.annual"
    // Phase 2: case lifetime = "com.najmulmyself.sennel.premium.lifetime"
}

@Observable
final class StoreKitService {
    static let shared = StoreKitService()

    var products: [Product] = []
    var isPremium: Bool = false
    private var updateListenerTask: Task<Void, Error>?

    init() {
        updateListenerTask = listenForTransactions()
        Task { await loadProducts(); await refreshEntitlements() }
    }

    func loadProducts() async {
        products = (try? await Product.products(for: SennelProduct.allCases.map(\.rawValue))) ?? []
    }

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            if case .verified(let transaction) = verification {
                await transaction.finish()
                await refreshEntitlements()
            }
        default:
            break
        }
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    func refreshEntitlements() async {
        var premium = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               SennelProduct(rawValue: transaction.productID) != nil {
                premium = true
            }
        }
        isPremium = premium
    }

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await self.refreshEntitlements()
                    await transaction.finish()
                }
            }
        }
    }
}
