import StoreKit

extension StoreKitService {
    var monthlyProduct: Product? {
        products.first { $0.id == SennelProduct.monthly.rawValue }
    }
}
