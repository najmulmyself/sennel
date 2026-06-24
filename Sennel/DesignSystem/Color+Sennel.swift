import SwiftUI

extension Color {
    /// Parses `#RRGGBB` or `#RGB` hex strings. Centralizing this is the only place
    /// a hex literal should appear — every other file references a token below.
    init(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexString.removeAll { $0 == "#" }

        var value: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&value)

        let r, g, b: UInt64
        if hexString.count == 3 {
            (r, g, b) = ((value >> 8) * 17, (value >> 4 & 0xF) * 17, (value & 0xF) * 17)
        } else {
            (r, g, b) = (value >> 16, value >> 8 & 0xFF, value & 0xFF)
        }

        self = Color(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}

/// The streak stage — the core visual mechanic. The hero card's accent color
/// interpolates through these as the streak grows; see sennel_design.md Section 2.
enum SennelStage: String, CaseIterable, Identifiable {
    case slate, teal3, teal4, emerald

    var id: String { rawValue }

    static func forDays(_ days: Int) -> SennelStage {
        switch days {
        case ..<3: return .slate
        case 3..<8: return .teal3
        case 8..<30: return .teal4
        default: return .emerald
        }
    }

    /// "Keep going." header label — uppercased by the view, not here.
    var label: String {
        switch self {
        case .slate: return "A fresh start"
        case .teal3: return "Warming up"
        case .teal4: return "Building"
        case .emerald: return "Arrived"
        }
    }

    /// Light/dark variants brighten slate and emerald for legibility on dark
    /// backgrounds; teal3/teal4 are already vivid enough to use unchanged.
    func color(dark: Bool) -> Color {
        switch self {
        case .slate: return Color(hex: dark ? "#B0BCC9" : "#94A3B8")
        case .teal3: return Color(hex: "#5EEAD4")
        case .teal4: return Color(hex: "#2DD4BF")
        case .emerald: return Color(hex: dark ? "#10B981" : "#047857")
        }
    }
}

/// Resolved color tokens for a given stage + appearance. One source of truth so
/// every screen shares identical surface/text/accent values (sennel_design.md Section 2).
struct SennelTheme {
    let dark: Bool
    let stage: SennelStage

    /// Brand gradient — app icon + light-mode accent (start) to dark-mode accent/CTA (end).
    static let brandTealLight = Color(hex: "#2DD4BF")
    static let brandEmeraldDeep = Color(hex: "#047857")

    static let accentShield = Color(hex: "#F59E0B")
    static let accentLock = Color(hex: "#94A3B8")

    var stageColor: Color { stage.color(dark: dark) }

    var background: Color { Color(hex: dark ? "#0B1410" : "#FAFAF9") }
    var card: Color { Color(hex: dark ? "#13201C" : "#FFFFFF") }
    var textPrimary: Color { Color(hex: dark ? "#ECFDF5" : "#0F172A") }
    var textSecondary: Color { Color(hex: dark ? "#9CA8A4" : "#64748B") }
    var textTertiary: Color { dark ? Color.white.opacity(0.3) : Color(hex: "#3C3C43").opacity(0.3) }

    var hairline: Color { dark ? Color.white.opacity(0.08) : Color(hex: "#0F172A").opacity(0.07) }
    var track: Color { dark ? Color.white.opacity(0.07) : Color(hex: "#0F172A").opacity(0.06) }
    var separator: Color { dark ? Color.white.opacity(0.08) : Color(hex: "#3C3C43").opacity(0.12) }

    var stageSoft: Color { stageColor.opacity(dark ? 0.20 : 0.13) }
    var stageGlow: Color { stageColor.opacity(dark ? 0.22 : 0.16) }
    var shine: Color { dark ? Color.white.opacity(0.08) : Color.white.opacity(0.8) }

    /// Text color for buttons filled with `stageColor` — near-black on the bright
    /// dark-mode accents, white everywhere else.
    var buttonText: Color { dark ? Color(hex: "#04120C") : .white }
}
