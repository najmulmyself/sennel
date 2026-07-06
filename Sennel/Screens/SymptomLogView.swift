import SwiftUI

/// The withdrawal symptom log (SennelSymptoms.dc.html) — a 7-day severity matrix
/// plus today's quick-log row. Day columns use real weekday labels rather than the
/// prototype's "D6"–"D12" streak-day numbers, since a freshly onboarded streak has
/// no history yet to label that way.
struct SymptomLogView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    private let weekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEEE" // single-letter weekday
        return f
    }()

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            content(date: context.date)
        }
    }

    private func content(date: Date) -> some View {
        let theme = SennelTheme(dark: colorScheme == .dark, stage: appState.stage(at: date))
        let accent = SennelTheme.brandTeal(dark: theme.dark)
        let days = appState.recentSymptomDays(at: date)
        let calendar = Calendar.current

        return ZStack {
            theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: SennelSpace.lg) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Withdrawal")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(theme.textPrimary)
                        Text("Symptoms easing over time.")
                            .font(.subheadline)
                            .foregroundStyle(theme.textSecondary)
                    }

                    historyGrid(theme: theme, accent: accent, days: days, today: date, calendar: calendar)
                    legend(theme: theme, accent: accent)
                    todayCard(theme: theme, accent: accent, date: date)

                    Text(trendText(theme: theme, accent: accent, date: date))
                        .font(.subheadline)
                        .foregroundStyle(theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, SennelSpace.lg)
                .padding(.top, SennelSpace.lg)
                .padding(.bottom, SennelSpace.lg)
            }
        }
    }

    // MARK: History grid

    private func historyGrid(theme: SennelTheme, accent: Color, days: [AppState.SymptomDay], today: Date, calendar: Calendar) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                Color.clear.frame(width: 92)
                ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                    let isToday = calendar.isDate(day.day, inSameDayAs: today)
                    Text(weekdayFormatter.string(from: day.day))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isToday ? accent : theme.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            ForEach(AppState.Symptom.allCases) { symptom in
                HStack(spacing: 0) {
                    Text(symptom.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(theme.textPrimary)
                        .frame(width: 92, alignment: .leading)
                    ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                        let severity = day.severities[symptom] ?? 0
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(severityFill(severity, theme: theme, accent: accent))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .strokeBorder(severity == 0 ? theme.hairline : .clear)
                            )
                            .frame(width: 26, height: 26)
                            .frame(maxWidth: .infinity)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(symptom.rawValue)
                .accessibilityValue(days.map { severityLabel($0.severities[symptom] ?? 0) }.joined(separator: ", "))
            }
        }
        .padding(SennelSpace.md)
        .background(theme.card)
        .overlay(RoundedRectangle(cornerRadius: SennelRadius.card, style: .continuous).strokeBorder(theme.hairline))
        .clipShape(RoundedRectangle(cornerRadius: SennelRadius.card, style: .continuous))
    }

    private func legend(theme: SennelTheme, accent: Color) -> some View {
        HStack(spacing: 16) {
            legendSwatch(label: "None", color: severityFill(0, theme: theme, accent: accent), bordered: true, theme: theme)
            legendSwatch(label: "Mild", color: severityFill(1, theme: theme, accent: accent), bordered: false, theme: theme)
            legendSwatch(label: "Strong", color: severityFill(2, theme: theme, accent: accent), bordered: false, theme: theme)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .accessibilityHidden(true)
    }

    private func legendSwatch(label: String, color: Color, bordered: Bool, theme: SennelTheme) -> some View {
        HStack(spacing: 7) {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(color)
                .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous).strokeBorder(bordered ? theme.hairline : .clear))
                .frame(width: 14, height: 14)
            Text(label)
                .font(.caption)
                .foregroundStyle(theme.textSecondary)
        }
    }

    // MARK: Today card

    private func todayCard(theme: SennelTheme, accent: Color, date: Date) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("How are you today?")
                .font(.body.weight(.semibold))
                .foregroundStyle(theme.textPrimary)

            ForEach([AppState.Symptom.irritability, .brainFog, .insomnia, .anxiety]) { symptom in
                let picked = appState.severity(for: symptom, on: date)
                HStack {
                    Text(symptom.rawValue)
                        .font(.body)
                        .foregroundStyle(theme.textPrimary)
                    Spacer()
                    HStack(spacing: 7) {
                        ForEach(0...2, id: \.self) { level in
                            let selected = picked == level
                            Button {
                                appState.logSymptom(symptom, severity: level, on: date)
                            } label: {
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(severityFill(level, theme: theme, accent: accent))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                                            .strokeBorder(selected ? accent : (level == 0 ? theme.hairline : .clear), lineWidth: selected ? 2 : 1)
                                    )
                                    .frame(width: 30, height: 30)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(symptom.rawValue), \(severityLabel(level))")
                            .accessibilityAddTraits(selected ? .isSelected : [])
                        }
                    }
                }
            }
        }
        .padding(SennelSpace.md)
        .background(theme.card)
        .overlay(RoundedRectangle(cornerRadius: SennelRadius.card, style: .continuous).strokeBorder(theme.hairline))
        .clipShape(RoundedRectangle(cornerRadius: SennelRadius.card, style: .continuous))
    }

    // MARK: Helpers

    private func severityFill(_ severity: Int, theme: SennelTheme, accent: Color) -> Color {
        switch severity {
        case 0: return theme.dark ? Color.white.opacity(0.05) : theme.textPrimary.opacity(0.04)
        case 1: return accent.opacity(0.28)
        default: return accent
        }
    }

    private func severityLabel(_ severity: Int) -> String {
        switch severity {
        case 0: return "None"
        case 1: return "Mild"
        default: return "Strong"
        }
    }

    private func trendText(theme: SennelTheme, accent: Color, date: Date) -> AttributedString {
        let down = appState.symptomTrendIsDown(at: date)
        var text = AttributedString(down ? "Your symptoms are trending down — today is lighter than a week ago." : "Your symptoms are holding steady — keep logging to spot the pattern.")
        if let range = text.range(of: down ? "trending down" : "holding steady") {
            text[range].foregroundColor = accent
            text[range].font = .subheadline.weight(.semibold)
        }
        return text
    }
}

#Preview {
    SymptomLogView()
        .environment(AppState())
}
