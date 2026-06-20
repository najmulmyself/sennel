import SwiftUI

/// Reusable glass container wrapper for hero elements (streak card, money-saved card,
/// floating log button, paywall card — per design doc §5). Tinted with the current
/// progressive streak color. Placeholder fill for now; swap to .glassEffect() in the UI pass.
struct GlassCard<Content: View>: View {
    var tint: Color
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Radius.card)
                    .fill(tint.opacity(0.15))
            )
    }
}
