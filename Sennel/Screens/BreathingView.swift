import SwiftUI

/// Guided box breathing (SennelBreathing.dc.html) — presented as a sheet. Always renders
/// in its own fixed dark gradient regardless of system color scheme, matching the
/// prototype's `dark="{{ true }}"` frame: this screen is meant to feel calm and immersive,
/// not to follow the rest of the app's light/dark theming.
struct BreathingView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var startedAt = Date()
    @State private var pausedAt: Date?
    @ScaledMetric private var phaseFontSize: CGFloat = 30

    private let backgroundGradient = LinearGradient(
        colors: [Color(hex: "#0C2420"), Color(hex: "#0A1815"), Color(hex: "#081210")],
        startPoint: .top, endPoint: .bottom
    )

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.25)) { context in
            content(date: context.date)
        }
    }

    private func content(date: Date) -> some View {
        let elapsed = (pausedAt ?? date).timeIntervalSince(startedAt)
        let t = elapsed.truncatingRemainder(dividingBy: 10)
        let cycle = min(6, Int(elapsed / 10) + 1)
        let phase = t < 4 ? "Breathe in" : (t < 6 ? "Hold" : "Breathe out")
        let accent = SennelTheme.breathingAccent
        let isPlaying = pausedAt == nil

        return ZStack {
            backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button("Done") { finish(elapsed: elapsed) }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                    Spacer()
                    Text("Box breathing")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Text("4–2–4")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Text("CYCLE \(cycle) OF 6")
                    .font(.caption.weight(.semibold))
                    .kerning(2.2)
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.top, 30)

                Spacer()

                breathingCircle(t: t, phase: phase, accent: accent, isPlaying: isPlaying)

                Spacer()

                Text("Follow the circle. In as it grows, out as it falls.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)

                Button {
                    toggle(now: date)
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                        .frame(width: 64, height: 64)
                        .background(.white.opacity(0.16), in: Circle())
                }
                .buttonStyle(.plain)
                .padding(.top, 18)
                .accessibilityLabel(isPlaying ? "Pause" : "Play")
            }
            .padding(.horizontal, SennelSpace.lg)
            .padding(.top, 60)
            .padding(.bottom, 34)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(phase), cycle \(cycle) of 6")
    }

    // MARK: Breathing circle

    private func breathingCircle(t: Double, phase: String, accent: Color, isPlaying: Bool) -> some View {
        let scale = reduceMotion ? 0.85 : breathScale(t: t)
        let glowOpacity = reduceMotion ? 0.5 : 0.35 + 0.35 * sin(.pi * t / 10)

        return ZStack {
            Circle()
                .fill(RadialGradient(colors: [accent, .clear], center: .center, startRadius: 0, endRadius: 150))
                .frame(width: 300, height: 300)
                .opacity(glowOpacity)

            Circle()
                .fill(RadialGradient(
                    colors: [.white.opacity(0.35), accent],
                    center: UnitPoint(x: 0.38, y: 0.32),
                    startRadius: 0, endRadius: 165
                ))
                .frame(width: 230, height: 230)
                .scaleEffect(scale)
                .shadow(color: accent.opacity(0.45), radius: 30, y: 10)
                .overlay(
                    Text(phase)
                        .font(.system(size: phaseFontSize, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                )
                .opacity(isPlaying ? 1 : 0.85)
        }
        .accessibilityHidden(true)
    }

    private func breathScale(t: Double) -> CGFloat {
        func easeInOut(_ x: Double) -> Double { x < 0.5 ? 2 * x * x : 1 - pow(-2 * x + 2, 2) / 2 }
        if t < 4 { return 0.58 + 0.42 * easeInOut(t / 4) }
        if t < 6 { return 1.0 }
        return 1.0 - 0.42 * easeInOut((t - 6) / 4)
    }

    // MARK: Actions

    private func toggle(now: Date) {
        if let pausedAt {
            startedAt += now.timeIntervalSince(pausedAt)
            self.pausedAt = nil
        } else {
            pausedAt = now
        }
    }

    private func finish(elapsed: TimeInterval) {
        if elapsed >= 10 {
            appState.completeBreathingSession()
        }
        dismiss()
    }
}

#Preview {
    BreathingView()
        .environment(AppState())
}
