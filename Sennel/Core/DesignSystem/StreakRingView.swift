import SwiftUI

/// Shared core component (also the basis of the app icon). Circular progress ring,
/// ~270° sweep, rounded caps, leading-edge dot represents "today."
/// Visual polish (glass tint, glow, motion) lands in the later UI pass — this is the
/// structural shape only.
struct StreakRingView: View {
    var progress: Double // 0...1, progress toward next milestone
    var stage: StreakStage
    var lineWidth: CGFloat = 12

    private let sweepFraction: Double = 0.75 // ~270°

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: sweepFraction)
                .stroke(Color.color(for: stage).opacity(0.2), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(135))
            Circle()
                .trim(from: 0, to: sweepFraction * min(max(progress, 0), 1))
                .stroke(Color.color(for: stage), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(135))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Streak progress")
        .accessibilityValue("\(Int(progress * 100)) percent to next milestone")
    }
}
