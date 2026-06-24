import SwiftUI

/// Reusable glass container wrapper for hero elements (streak card, money-saved card,
/// floating log button, paywall card — per design doc §5). Tinted with the current
/// progressive streak color.
struct GlassCard<Content: View>: View {
    var tint: Color
    @ViewBuilder var content: () -> Content

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        if reduceTransparency {
            // Translucency reads fine in a screenshot but can fail contrast/legibility
            // for users who've turned this on — fall back to a solid tinted card.
            content()
                .padding(Spacing.md)
                .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: Radius.card))
        } else {
            content()
                .padding(Spacing.md)
                .glassEffect(.regular.tint(tint.opacity(0.4)), in: RoundedRectangle(cornerRadius: Radius.card))
        }
    }
}
