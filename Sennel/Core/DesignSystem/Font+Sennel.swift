import SwiftUI

extension Font {
    /// SF Pro Rounded Bold, 72–96pt base — used only for Hero Numbers (streak days, money saved).
    /// Callers should scale the base size via @ScaledMetric so it still respects Dynamic Type.
    static func heroNumber(size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
}
