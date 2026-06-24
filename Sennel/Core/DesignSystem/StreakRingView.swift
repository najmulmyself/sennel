import SwiftUI

/// Shared core component (also the basis of the app icon). Circular progress ring,
/// ~270° sweep, rounded caps, leading-edge dot represents "today."
struct StreakRingView: View {
    var progress: Double // 0...1, total fill — see StreakCalculator.ringFillProgress
    var stage: StreakStage
    var days: Int = 0
    var lineWidth: CGFloat = 12

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let sweepFraction: Double = 0.75 // ~270°
    private let rotationDegrees: Double = 135 // moves the start point to ~7:30/8 o'clock

    var body: some View {
        GeometryReader { geo in
            let radius = min(geo.size.width, geo.size.height) / 2 - lineWidth / 2
            let clamped = min(max(progress, 0), 1)
            // Same start (3 o'clock, 0°) + rotation + sweep-so-far as the trimmed arc below,
            // so the dot always sits exactly on the fill's leading edge.
            let angle = Angle.degrees(rotationDegrees + 360 * sweepFraction * clamped)
            let dotCenter = CGPoint(
                x: geo.size.width / 2 + radius * cos(angle.radians),
                y: geo.size.height / 2 + radius * sin(angle.radians)
            )

            ZStack {
                // Unfilled track — deliberately neutral, never tinted with the stage color,
                // so the colored fill always reads clearly against it.
                Circle()
                    .trim(from: 0, to: sweepFraction)
                    .stroke(Color.ringTrack, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(rotationDegrees))

                Circle()
                    .trim(from: 0, to: sweepFraction * clamped)
                    .stroke(Color.color(for: stage), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(rotationDegrees))

                // Leading "today" dot — soft glow halo, then a solid near-white core.
                Circle()
                    .fill(Color.color(for: stage).opacity(0.35))
                    .frame(width: lineWidth * 2.6, height: lineWidth * 2.6)
                    .blur(radius: lineWidth * 0.35)
                    .position(dotCenter)
                Circle()
                    .fill(Color.white)
                    .frame(width: lineWidth * 1.1, height: lineWidth * 1.1)
                    .position(dotCenter)
            }
        }
        .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8), value: progress)
        .animation(reduceMotion ? nil : .easeInOut(duration: 1.2), value: stage)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Streak progress")
        .accessibilityValue("Day \(days)")
    }
}

#Preview("Day 0") {
    StreakRingView(progress: StreakCalculator.ringFillProgress(forDays: 0), stage: .stage0, days: 0, lineWidth: 14)
        .frame(width: 220, height: 220)
        .padding(40)
}

#Preview("Day 12") {
    StreakRingView(progress: StreakCalculator.ringFillProgress(forDays: 12), stage: .stage2, days: 12, lineWidth: 14)
        .frame(width: 220, height: 220)
        .padding(40)
}

#Preview("Day 34") {
    StreakRingView(progress: StreakCalculator.ringFillProgress(forDays: 34), stage: .stage3, days: 34, lineWidth: 14)
        .frame(width: 220, height: 220)
        .padding(40)
}
