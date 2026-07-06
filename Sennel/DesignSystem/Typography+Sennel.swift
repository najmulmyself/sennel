import SwiftUI

/// The "Hero Number" style (sennel_design.md Section 3) — SF Pro Rounded, used only
/// for streak days / money saved. Scales via `@ScaledMetric` so Dynamic Type still
/// applies to the one style in the app that isn't a system text style.
struct HeroNumber: View {
    let text: String
    let weight: Font.Weight
    @ScaledMetric private var size: CGFloat

    init(_ text: String, baseSize: CGFloat, weight: Font.Weight = .heavy) {
        self.text = text
        self.weight = weight
        self._size = ScaledMetric(wrappedValue: baseSize)
    }

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: weight, design: .rounded))
            .lineSpacing(0)
    }
}

/// Spacing scale — 4pt base grid (sennel_design.md Section 4). No spacing value
/// outside this scale anywhere in the app.
enum SennelSpace {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 40
}

enum SennelRadius {
    static let card: CGFloat = 24
    static let button: CGFloat = 16
}
