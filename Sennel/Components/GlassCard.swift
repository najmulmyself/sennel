import SwiftUI

/// Liquid Glass, tinted with the current stage color (sennel_design.md Section 5).
/// Reserved for the hero streak/money card, the floating log button, and the
/// paywall card — never for list rows or dense text containers.
extension View {
    func sennelGlass(tint: Color, cornerRadius: CGFloat = SennelRadius.card, interactive: Bool = false) -> some View {
        var glass = Glass.regular.tint(tint)
        if interactive { glass = glass.interactive() }
        return self.glassEffect(glass, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
