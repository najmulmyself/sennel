import SwiftUI

/// The health timeline (SennelTimeline.dc.html) — milestones derived from real
/// elapsed time rather than the prototype's hardcoded "5 of 7 reached" snapshot.
struct HealthView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var celebratingIndex: Int?
    @State private var celebrateTask: Task<Void, Never>?
    @State private var showSymptomLog = false

    private struct Milestone {
        let title: String
        let detail: String
        let time: String
        let threshold: TimeInterval
    }

    private let milestones: [Milestone] = [
        .init(title: "20 minutes", detail: "Heart rate & blood pressure settle", time: "20 min", threshold: 20 * 60),
        .init(title: "1 hour", detail: "Restlessness begins to ease", time: "1 hr", threshold: 60 * 60),
        .init(title: "1 day", detail: "Nicotine has left your bloodstream", time: "1 day", threshold: 86_400),
        .init(title: "3 days", detail: "Breathing feels noticeably easier", time: "3 days", threshold: 3 * 86_400),
        .init(title: "1 week", detail: "Taste and smell start to sharpen", time: "1 wk", threshold: 7 * 86_400),
        .init(title: "1 month", detail: "Gum tissue begins to heal", time: "1 mo", threshold: 30 * 86_400),
        .init(title: "3 months", detail: "Circulation meaningfully improves", time: "3 mo", threshold: 90 * 86_400),
    ]

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            content(date: context.date)
        }
    }

    private func content(date: Date) -> some View {
        let theme = SennelTheme(dark: colorScheme == .dark, stage: appState.stage(at: date))
        let elapsed = appState.elapsed(at: date)
        let doneCount = milestones.filter { elapsed >= $0.threshold }.count

        return ZStack {
            theme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Health")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(theme.textPrimary)
                    Text("Your body, recovering.")
                        .font(.subheadline)
                        .foregroundStyle(theme.textSecondary)
                }
                .padding(.horizontal, SennelSpace.lg)
                .padding(.bottom, SennelSpace.md)

                summaryCard(theme: theme, doneCount: doneCount)
                    .padding(.horizontal, SennelSpace.lg)
                    .padding(.bottom, SennelSpace.sm)

                symptomLogRow(theme: theme)
                    .padding(.horizontal, SennelSpace.lg)
                    .padding(.bottom, SennelSpace.md)

                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(milestones.enumerated()), id: \.offset) { index, milestone in
                            milestoneRow(milestone: milestone, theme: theme, done: elapsed >= milestone.threshold, celebrating: celebratingIndex == index)
                            if index < milestones.count - 1 {
                                Rectangle().fill(theme.hairline).frame(height: 1)
                            }
                        }
                    }
                    .padding(.horizontal, SennelSpace.lg)
                }
            }
            .padding(.top, SennelSpace.lg)
        }
        .onChange(of: doneCount) { old, new in
            guard new > old else { return }
            celebrate(index: new - 1)
        }
        .sensoryFeedback(.success, trigger: doneCount) { old, new in new > old }
        .sheet(isPresented: $showSymptomLog) {
            SymptomLogView()
        }
    }

    private func symptomLogRow(theme: SennelTheme) -> some View {
        Button { showSymptomLog = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "list.bullet.clipboard.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(theme.stageColor)
                    .frame(width: 29, height: 29)
                    .background(theme.stageColor.opacity(theme.dark ? 0.18 : 0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .accessibilityHidden(true)
                Text("Log today's symptoms")
                    .font(.body)
                    .foregroundStyle(theme.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.textTertiary)
            }
            .padding(.horizontal, SennelSpace.md)
            .frame(height: 50)
            .background(theme.card)
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(theme.hairline))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func celebrate(index: Int) {
        celebratingIndex = index
        celebrateTask?.cancel()
        celebrateTask = Task {
            try? await Task.sleep(for: .seconds(0.5))
            guard !Task.isCancelled else { return }
            celebratingIndex = nil
        }
    }

    private func summaryCard(theme: SennelTheme, doneCount: Int) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("MILESTONES")
                    .font(.caption.weight(.semibold))
                    .kerning(1.2)
                    .foregroundStyle(theme.textSecondary)
                Text("\(doneCount) of \(milestones.count) reached")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(theme.textPrimary)
            }
            Spacer()
            HStack(spacing: 5) {
                ForEach(0..<milestones.count, id: \.self) { index in
                    Circle()
                        .fill(index < doneCount ? theme.stageColor : theme.hairline)
                        .frame(width: 9, height: 9)
                }
            }
        }
        .padding(SennelSpace.md)
        .background(theme.card)
        .overlay(RoundedRectangle(cornerRadius: SennelRadius.card, style: .continuous).strokeBorder(theme.hairline))
        .clipShape(RoundedRectangle(cornerRadius: SennelRadius.card, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Milestones")
        .accessibilityValue("\(doneCount) of \(milestones.count) reached")
    }

    private func milestoneRow(milestone: Milestone, theme: SennelTheme, done: Bool, celebrating: Bool) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(done ? theme.stageColor : Color.clear)
                    .overlay(Circle().strokeBorder(theme.hairline, lineWidth: done ? 0 : 1.5))
                Image(systemName: "leaf.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(done ? theme.buttonText : theme.textSecondary)
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 2) {
                Text(milestone.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(theme.textPrimary)
                Text(milestone.detail)
                    .font(.caption)
                    .foregroundStyle(theme.textSecondary)
            }

            Spacer()

            Text(milestone.time)
                .font(.caption.weight(.semibold))
                .foregroundStyle(done ? theme.stageColor : theme.textSecondary)
        }
        .padding(.vertical, 13)
        .scaleEffect(celebrating && !reduceMotion ? 1.05 : 1.0)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: celebrating)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(milestone.title)
        .accessibilityValue(done ? "Reached. \(milestone.detail)" : "Not yet reached. \(milestone.detail)")
    }
}

#Preview {
    HealthView()
        .environment(AppState())
}
