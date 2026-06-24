import SwiftUI

/// The single primary action button used across Home/Onboarding/Paywall.
/// Motion + haptic mapping per sennel_design.md Sections 7-8: scale to 0.96 and
/// spring back on tap, with a light impact haptic on the calling screen's action.
struct PrimaryButton: View {
    let title: String
    let theme: SennelTheme
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pressed = false

    var body: some View {
        Button {
            action()
        } label: {
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(theme.buttonText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
        }
        .buttonStyle(.plain)
        .sennelGlass(tint: theme.stageColor, cornerRadius: SennelRadius.button, interactive: true)
        .shadow(color: theme.stageGlow, radius: 18, y: 8)
        .scaleEffect(pressed ? 0.965 : 1)
        .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8), value: pressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded { _ in pressed = false }
        )
    }
}
