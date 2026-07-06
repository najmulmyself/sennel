import SwiftUI

/// The core reusable component (sennel_design.md Section 9) — a 270° progress ring,
/// the same geometry as the app icon: a small dim dot marks the start, a bright
/// "today" dot breathes gently at the leading edge.
///
/// Angle convention matches the original design prototype's SVG math directly
/// (0° = +x axis, increasing = clockwise) so the ring/dot geometry lines up exactly:
/// `Circle().trim` already starts at 0° = 3 o'clock and sweeps clockwise, which is
/// why the arcs need no extra rotation math beyond the shared `startAngle`.
struct StreakRing: View {
    var progress: Double
    var stageColor: Color
    var trackColor: Color
    var dotHaloColor: Color
    var lineWidth: CGFloat = 13

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathe = false

    private let startAngle: Double = 135
    private let sweep: Double = 270

    private var clamped: Double { max(0.02, min(1, progress)) }
    private var leadAngle: Double { startAngle + sweep * clamped }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            // Matches the prototype's 220pt viewBox with a 92pt ring radius.
            let radius = size * (92.0 / 220.0)
            let center = CGPoint(x: size / 2, y: size / 2)

            ZStack {
                Circle()
                    .trim(from: 0, to: sweep / 360)
                    .stroke(trackColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(startAngle))

                Circle()
                    .trim(from: 0, to: (sweep * clamped) / 360)
                    .stroke(stageColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(startAngle))
                    .animation(reduceMotion ? nil : .easeInOut(duration: 1.2), value: clamped)

                Circle()
                    .fill(stageColor.opacity(0.55))
                    .frame(width: size * (11.0 / 220), height: size * (11.0 / 220))
                    .position(point(angle: startAngle, center: center, radius: radius))

                Circle()
                    .fill(dotHaloColor)
                    .frame(width: size * (22.0 / 220), height: size * (22.0 / 220))
                    .position(point(angle: leadAngle, center: center, radius: radius))

                Circle()
                    .fill(stageColor)
                    .frame(width: size * (17.0 / 220), height: size * (17.0 / 220))
                    .opacity(reduceMotion ? 1 : (breathe ? 0.5 : 1))
                    .position(point(angle: leadAngle, center: center, radius: radius))
                    .animation(
                        reduceMotion ? nil : .easeInOut(duration: 1.7).repeatForever(autoreverses: true),
                        value: breathe
                    )
            }
            .onAppear { if !reduceMotion { breathe = true } }
        }
    }

    private func point(angle: Double, center: CGPoint, radius: CGFloat) -> CGPoint {
        let rad = angle * .pi / 180
        return CGPoint(x: center.x + radius * cos(rad), y: center.y + radius * sin(rad))
    }
}
