import SwiftUI

/// Milestones / badge grid (SennelBadges.dc.html). The "Just earned" hero card
/// reuses the app icon's ring-and-dot glyph rather than the grid's leaf icon —
/// matching the prototype's own SVG, which draws a partial ring + two dots there.
struct BadgesView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            content(date: context.date)
        }
    }

    private func content(date: Date) -> some View {
        let theme = SennelTheme(dark: colorScheme == .dark, stage: appState.stage(at: date))
        let accent = SennelTheme.brandTeal(dark: theme.dark)
        let earned = appState.earnedBadges(at: date)

        return ZStack {
            theme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: SennelSpace.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Milestones")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(theme.textPrimary)
                    Text("\(earned.count) of \(AppState.badgeCatalog.count) earned")
                        .font(.subheadline)
                        .foregroundStyle(theme.textSecondary)
                }

                heroCard(theme: theme, accent: accent, date: date)

                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 3), spacing: 18) {
                        ForEach(AppState.badgeCatalog) { badge in
                            badgeCell(badge: badge, theme: theme, accent: accent, date: date)
                        }
                    }
                }
            }
            .padding(.horizontal, SennelSpace.lg)
            .padding(.top, SennelSpace.lg)
            .padding(.bottom, SennelSpace.md)
        }
    }

    // MARK: Hero card

    private func heroCard(theme: SennelTheme, accent: Color, date: Date) -> some View {
        Group {
            if let hero = appState.heroBadge(at: date) {
                HStack(spacing: 18) {
                    HeroRingGlyph(color: accent)
                        .frame(width: 78, height: 78)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("JUST EARNED")
                            .font(.caption.weight(.semibold))
                            .kerning(1.2)
                            .foregroundStyle(accent)
                        Text(hero.title)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(theme.textPrimary)
                        Text(hero.detail)
                            .font(.subheadline)
                            .foregroundStyle(theme.textSecondary)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Just earned: \(hero.title). \(hero.detail)")
            } else {
                HStack(spacing: 18) {
                    HeroRingGlyph(color: theme.hairline)
                        .frame(width: 78, height: 78)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("UP NEXT")
                            .font(.caption.weight(.semibold))
                            .kerning(1.2)
                            .foregroundStyle(theme.textSecondary)
                        Text("First Day")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(theme.textPrimary)
                        Text("Make it through day one to earn your first badge.")
                            .font(.subheadline)
                            .foregroundStyle(theme.textSecondary)
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(SennelSpace.lg)
        .background(
            LinearGradient(colors: [accent.opacity(theme.dark ? 0.16 : 0.10), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .background(theme.card)
        .overlay(RoundedRectangle(cornerRadius: SennelRadius.card, style: .continuous).strokeBorder(theme.hairline))
        .clipShape(RoundedRectangle(cornerRadius: SennelRadius.card, style: .continuous))
        .shadow(color: accent.opacity(theme.dark ? 0.16 : 0.10), radius: 24, y: 10)
    }

    // MARK: Grid cell

    private func badgeCell(badge: AppState.Badge, theme: SennelTheme, accent: Color, date: Date) -> some View {
        let earned = badge.isEarned(appState, date)
        return VStack(spacing: 8) {
            Circle()
                .fill(earned ? accent : theme.track)
                .overlay(Circle().strokeBorder(earned ? Color.clear : theme.hairline, lineWidth: 1.5))
                .frame(width: 72, height: 72)
                .overlay(
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(earned ? theme.buttonText : theme.textSecondary)
                )
                .shadow(color: earned ? accent.opacity(theme.dark ? 0.22 : 0.16) : .clear, radius: 12, y: 4)
            Text(badge.title)
                .font(.caption.weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(earned ? theme.textPrimary : theme.textSecondary)
                .lineLimit(2)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(badge.title)
        .accessibilityValue(earned ? "Earned. \(badge.detail)" : "Locked")
    }
}

/// The app icon's ring-and-dot glyph, recolored per badge state — the same motif
/// `OnboardingMark`/`StreakRing` use elsewhere, sized down for the hero card.
private struct HeroRingGlyph: View {
    let color: Color

    var body: some View {
        ZStack {
            Circle().fill(color)
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(.white.opacity(0.9), style: StrokeStyle(lineWidth: 6.5, lineCap: .round))
                .rotationEffect(.degrees(135))
            Circle()
                .fill(.white)
                .frame(width: 16, height: 16)
                .offset(x: -17.7, y: 17.7)
            Circle()
                .fill(.white)
                .frame(width: 9, height: 9)
                .offset(x: 16, y: -19)
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    BadgesView()
        .environment(AppState())
}
