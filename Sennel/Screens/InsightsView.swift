import SwiftUI

/// The Insights tab (SennelInsights.dc.html) — real charts driven by AppState's
/// craving/pouch history, replacing Phase 1's blurred paywall teaser. StoreKit2 and
/// a real paywall gate are out of Phase 2 scope, so this is just the full picture.
struct InsightsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    private enum Range: Int, CaseIterable { case sevenDay = 7, thirtyDay = 30
        var label: String { self == .sevenDay ? "7D" : "30D" }
    }

    @State private var range: Range = .thirtyDay

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            content(date: context.date)
        }
    }

    private func content(date: Date) -> some View {
        let theme = SennelTheme(dark: colorScheme == .dark, stage: appState.stage(at: date))
        let accent = SennelTheme.brandTeal(dark: theme.dark)
        let trend = appState.pouchTrend(at: date, spanDays: range.rawValue)

        return ZStack {
            theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: SennelSpace.md) {
                    header(theme: theme, accent: accent)
                    pouchChart(theme: theme, accent: accent, trend: trend)
                    statRow(theme: theme, accent: accent, date: date)
                    timeOfDayCard(theme: theme, accent: accent, date: date)

                    Text(footerText(theme: theme, accent: accent, date: date))
                        .font(.subheadline)
                        .foregroundStyle(theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                        .padding(.top, SennelSpace.xs)
                }
                .padding(.horizontal, SennelSpace.lg)
                .padding(.top, SennelSpace.lg)
                .padding(.bottom, SennelSpace.lg)
            }
        }
    }

    // MARK: Header

    private func header(theme: SennelTheme, accent: Color) -> some View {
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Insights")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(theme.textPrimary)
                Text("Last \(range.rawValue) days")
                    .font(.subheadline)
                    .foregroundStyle(theme.textSecondary)
            }
            Spacer()
            HStack(spacing: 6) {
                ForEach(Range.allCases, id: \.self) { option in
                    Button {
                        range = option
                    } label: {
                        Text(option.label)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .foregroundStyle(option == range ? theme.textPrimary : theme.textSecondary)
                            .background(option == range ? theme.card : Color.clear, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(option == range ? .isSelected : [])
                }
            }
            .padding(4)
            .background(theme.track, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    // MARK: Pouches per day

    private func pouchChart(theme: SennelTheme, accent: Color, trend: (days: [(date: Date, count: Int)], percentChange: Int)) -> some View {
        let maxCount = max(1, trend.days.map(\.count).max() ?? 1)
        let highlightCount = min(3, trend.days.count)

        return VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                Text("POUCHES PER DAY")
                    .font(.caption.weight(.semibold))
                    .kerning(1.2)
                    .foregroundStyle(theme.textSecondary)
                Spacer()
                HStack(spacing: 5) {
                    Image(systemName: trend.percentChange >= 0 ? "arrow.down.right" : "arrow.up.right")
                    Text(trend.percentChange >= 0 ? "Down \(trend.percentChange)%" : "Up \(-trend.percentChange)%")
                }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(accent)
            }

            HStack(alignment: .bottom, spacing: 5) {
                ForEach(Array(trend.days.enumerated()), id: \.offset) { index, day in
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(index >= trend.days.count - highlightCount ? accent : accent.opacity(theme.dark ? 0.30 : 0.28))
                        .frame(height: max(4, 120 * CGFloat(day.count) / CGFloat(maxCount)))
                }
            }
            .frame(height: 120, alignment: .bottom)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Pouches per day, last \(trend.days.count) days")
            .accessibilityValue("Most recent day \(trend.days.last?.count ?? 0)")

            HStack {
                Text("\(trend.days.count / 7) wks ago")
                Spacer()
                Text("Today")
            }
            .font(.caption)
            .foregroundStyle(theme.textSecondary)
        }
        .padding(SennelSpace.md)
        .background(theme.card)
        .overlay(RoundedRectangle(cornerRadius: SennelRadius.card, style: .continuous).strokeBorder(theme.hairline))
        .clipShape(RoundedRectangle(cornerRadius: SennelRadius.card, style: .continuous))
    }

    // MARK: Stat row

    private func statRow(theme: SennelTheme, accent: Color, date: Date) -> some View {
        let top = appState.topTrigger(at: date, days: range.rawValue)
        let avgRecent = appState.avgCravingIntensity(at: date, days: range.rawValue == 7 ? 7 : 14)
        let avgPrior = appState.avgCravingIntensity(at: date, days: range.rawValue == 7 ? 14 : 28)

        return HStack(spacing: SennelSpace.md) {
            statCard(theme: theme, label: "Top trigger", value: top?.label ?? "—", detail: top.map { "\($0.percent)% of cravings" } ?? "Log a craving to see this", accent: accent)
            statCard(
                theme: theme,
                label: "Avg craving",
                value: avgRecent.map { String(format: "%.1f / 5", $0) } ?? "—",
                detail: comparisonDetail(recent: avgRecent, prior: avgPrior),
                accent: accent
            )
        }
    }

    private func comparisonDetail(recent: Double?, prior: Double?) -> String {
        guard let recent, let prior, prior > 0 else { return "Not enough data yet" }
        if recent < prior { return "Down from \(String(format: "%.1f", prior))" }
        if recent > prior { return "Up from \(String(format: "%.1f", prior))" }
        return "Steady"
    }

    private func statCard(theme: SennelTheme, label: String, value: String, detail: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(theme.textSecondary)
            HeroNumber(value, baseSize: 22)
                .foregroundStyle(theme.textPrimary)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(accent)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(SennelSpace.md)
        .background(theme.card)
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(theme.hairline))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: Time of day

    private func timeOfDayCard(theme: SennelTheme, accent: Color, date: Date) -> some View {
        let buckets = appState.cravingsByTimeOfDay(at: date, days: range.rawValue)
        let maxCount = max(1, buckets.map(\.count).max() ?? 1)
        let peakIndex = buckets.enumerated().max(by: { $0.element.count < $1.element.count })?.offset

        return VStack(alignment: .leading, spacing: 16) {
            Text("CRAVINGS BY TIME OF DAY")
                .font(.caption.weight(.semibold))
                .kerning(1.2)
                .foregroundStyle(theme.textSecondary)

            HStack(alignment: .bottom, spacing: 7) {
                ForEach(Array(buckets.enumerated()), id: \.offset) { index, bucket in
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(index == peakIndex ? accent : accent.opacity(theme.dark ? 0.30 : 0.28))
                            .frame(height: max(4, 70 * CGFloat(bucket.count) / CGFloat(maxCount)))
                        Text(bucket.label)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(index == peakIndex ? accent : theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 70, alignment: .bottom)
        }
        .padding(SennelSpace.md)
        .background(theme.card)
        .overlay(RoundedRectangle(cornerRadius: SennelRadius.card, style: .continuous).strokeBorder(theme.hairline))
        .clipShape(RoundedRectangle(cornerRadius: SennelRadius.card, style: .continuous))
    }

    // MARK: Footer

    private func footerText(theme: SennelTheme, accent: Color, date: Date) -> AttributedString {
        let buckets = appState.cravingsByTimeOfDay(at: date, days: range.rawValue)
        let labels: [String: String] = ["6a": "6–9 AM dip", "9a": "9 AM–noon dip", "12p": "noon–3 PM dip", "3p": "2–4 PM dip", "6p": "6–8 PM dip", "9p": "evening dip"]
        let peakLabel = buckets.enumerated().max(by: { $0.element.count < $1.element.count })
            .flatMap { labels[$0.element.label] } ?? "afternoon dip"

        var text = AttributedString("Your \(peakLabel) is the moment to plan for.")
        if let range = text.range(of: peakLabel) {
            text[range].foregroundColor = accent
            text[range].font = .subheadline.weight(.semibold)
        }
        return text
    }
}

#Preview {
    InsightsView()
        .environment(AppState())
}
