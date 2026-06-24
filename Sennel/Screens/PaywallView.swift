import SwiftUI

/// The soft paywall (SennelPaywall.dc.html) — the Insights tab's content for
/// Phase 1: a blurred teaser of the (Phase 2) charts behind a glass paywall card.
/// No StoreKit wiring yet, per UI-fidelity-first scope — buttons are visual only.
struct PaywallView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    private let features = [
        "Full history & weekly charts",
        "Craving & trigger analysis",
        "Withdrawal symptom log",
        "Breathing exercises, widgets & badges",
    ]

    private let barHeights: [CGFloat] = [0.80, 0.64, 0.70, 0.48, 0.52, 0.34, 0.26]
    private let barHighlighted = [false, false, false, true, false, true, true]

    var body: some View {
        let theme = SennelTheme(dark: colorScheme == .dark, stage: appState.stage(at: .now))
        let accent = SennelTheme.brandTealLight

        ZStack {
            theme.background.ignoresSafeArea()

            insightsPreview(theme: theme, accent: accent)
                .blur(radius: 7)
                .opacity(0.85)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            LinearGradient(colors: [.clear, theme.background.opacity(0.95)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack {
                Spacer()
                paywallCard(theme: theme, accent: accent)
                    .padding(.horizontal, SennelSpace.md)
                    .padding(.bottom, SennelSpace.lg)
            }
        }
    }

    private func insightsPreview(theme: SennelTheme, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: SennelSpace.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Insights")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(theme.textPrimary)
                Text("Last 30 days")
                    .font(.subheadline)
                    .foregroundStyle(theme.textSecondary)
            }

            VStack(alignment: .leading, spacing: SennelSpace.md) {
                Text("POUCHES PER DAY")
                    .font(.caption.weight(.semibold))
                    .kerning(1.2)
                    .foregroundStyle(theme.textSecondary)
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(0..<barHeights.count, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(barHighlighted[i] ? accent : accent.opacity(theme.dark ? 0.18 : 0.12))
                            .frame(height: 96 * barHeights[i])
                    }
                }
                .frame(height: 96, alignment: .bottom)
            }
            .padding(SennelSpace.md)
            .background(theme.card)
            .overlay(RoundedRectangle(cornerRadius: SennelRadius.card, style: .continuous).strokeBorder(theme.hairline))
            .clipShape(RoundedRectangle(cornerRadius: SennelRadius.card, style: .continuous))

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Top trigger").font(.subheadline).foregroundStyle(theme.textSecondary)
                    Text("After meals").font(.title3.weight(.bold)).foregroundStyle(theme.textPrimary)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 2) {
                    Text("Avg craving").font(.subheadline).foregroundStyle(theme.textSecondary)
                    Text("3.2 / 5").font(.title3.weight(.bold)).foregroundStyle(theme.textPrimary)
                }
            }
            .padding(SennelSpace.md)
            .background(theme.card)
            .overlay(RoundedRectangle(cornerRadius: SennelRadius.card, style: .continuous).strokeBorder(theme.hairline))
            .clipShape(RoundedRectangle(cornerRadius: SennelRadius.card, style: .continuous))

            Spacer()
        }
        .padding(.horizontal, SennelSpace.lg)
        .padding(.top, SennelSpace.lg)
    }

    private func paywallCard(theme: SennelTheme, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: SennelSpace.md) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(accent)
                    .frame(width: 46, height: 46)
                    .overlay(
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text("Unlock the full picture")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(theme.textPrimary)
                    Text("Your core tools stay free, forever.")
                        .font(.subheadline)
                        .foregroundStyle(theme.textSecondary)
                }
            }

            VStack(alignment: .leading, spacing: 11) {
                ForEach(features, id: \.self) { feature in
                    HStack(spacing: 11) {
                        Circle()
                            .fill(accent.opacity(theme.dark ? 0.18 : 0.12))
                            .frame(width: 22, height: 22)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(accent)
                            )
                        Text(feature)
                            .font(.subheadline)
                            .foregroundStyle(theme.textPrimary)
                    }
                }
            }

            Button(action: {}) {
                Text("Go Premium — $3.99/month")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(theme.buttonText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
            }
            .buttonStyle(.plain)
            .background(accent, in: RoundedRectangle(cornerRadius: SennelRadius.button, style: .continuous))
            .shadow(color: accent.opacity(theme.dark ? 0.22 : 0.16), radius: 22, y: 8)

            HStack(spacing: 18) {
                Button("Restore Purchases", action: {})
                    .font(.caption)
                Circle().fill(theme.textSecondary).frame(width: 3, height: 3)
                Button("Maybe later", action: {})
                    .font(.caption)
            }
            .foregroundStyle(theme.textSecondary)
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
        }
        .padding(SennelSpace.lg)
        .sennelGlass(tint: accent, cornerRadius: 30)
        .shadow(color: .black.opacity(0.18), radius: 30, y: 14)
    }
}

#Preview {
    PaywallView()
        .environment(AppState())
}
