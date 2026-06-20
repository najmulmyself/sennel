import SwiftUI

extension Color {
    // Brand gradient
    static let brandTealLight = Color(light: "#2DD4BF", dark: "#2DD4BF")
    static let brandEmeraldDeep = Color(light: "#047857", dark: "#047857")

    // Progressive streak stages
    static let streakStage0 = Color(light: "#94A3B8", dark: "#94A3B8")
    static let streakStage1 = Color(light: "#5EEAD4", dark: "#5EEAD4")
    static let streakStage2 = Color(light: "#2DD4BF", dark: "#2DD4BF")
    static let streakStage3 = Color(light: "#047857", dark: "#047857")

    static func color(for stage: StreakStage) -> Color {
        switch stage {
        case .stage0: return .streakStage0
        case .stage1: return .streakStage1
        case .stage2: return .streakStage2
        case .stage3: return .streakStage3
        }
    }

    // Surfaces & text — these DO differ light/dark, per the design doc
    static let surfaceBackground = Color(light: "#FAFAF9", dark: "#0B1410")
    static let surfaceCard = Color(light: "#FFFFFF", dark: "#13201C")
    static let textPrimary = Color(light: "#0F172A", dark: "#ECFDF5")
    static let textSecondary = Color(light: "#64748B", dark: "#9CA8A4")

    // Functional accents
    static let accentShield = Color(light: "#F59E0B", dark: "#F59E0B")
    static let accentLock = Color(light: "#94A3B8", dark: "#94A3B8")

    // Onboarding full-bleed gradient (design doc §10 stage-0 slate) — fixed regardless
    // of system appearance, since onboarding precedes any user theme preference.
    static let onboardingGradientTop = Color(light: "#6B7686", dark: "#6B7686")
    static let onboardingGradientBottom = Color(light: "#3D4654", dark: "#3D4654")

    /// Helper: build a Color that resolves differently per light/dark mode from hex strings.
    init(light: String, dark: String) {
        self.init(uiColor: UIColor(dynamicProvider: { trait in
            UIColor(hex: trait.userInterfaceStyle == .dark ? dark : light)
        }))
    }
}

extension UIColor {
    convenience init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        s = s.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        self.init(
            red: CGFloat((rgb & 0xFF0000) >> 16) / 255,
            green: CGFloat((rgb & 0x00FF00) >> 8) / 255,
            blue: CGFloat(rgb & 0x0000FF) / 255,
            alpha: 1
        )
    }
}
