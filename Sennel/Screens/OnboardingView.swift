import SwiftUI

/// 2-question onboarding (sennel_design.md Section 10 / PRD Phase 1) — full-bleed
/// stage-0 slate gradient, no glass, single question per screen, straight to value.
struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum Step { case lastPouch, dailyGoal }
    @State private var step: Step = .lastPouch

    private enum TimeChoice { case justNow, specific }
    @State private var timeChoice: TimeChoice = .justNow
    @State private var chosenTime = Date()
    @State private var showTimePicker = false

    @State private var dailyGoal = 8

    private let gradient = LinearGradient(
        stops: [
            .init(color: Color(hex: "#93A1B2"), location: 0),
            .init(color: Color(hex: "#6B788B"), location: 0.52),
            .init(color: Color(hex: "#566175"), location: 1),
        ],
        startPoint: UnitPoint(x: 0.3, y: 0),
        endPoint: UnitPoint(x: 0.7, y: 1)
    )

    var body: some View {
        ZStack {
            gradient.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.top, SennelSpace.lg)

                Group {
                    if step == .lastPouch {
                        lastPouchContent
                    } else {
                        dailyGoalContent
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .frame(maxHeight: .infinity)

                ctaButton
            }
            .padding(.horizontal, 26)
            .padding(.bottom, SennelSpace.lg)
        }
        .sheet(isPresented: $showTimePicker) {
            NavigationStack {
                DatePicker("Last pouch", selection: $chosenTime, in: ...Date(), displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .padding()
                    .navigationTitle("When was it?")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showTimePicker = false }
                        }
                    }
            }
            .presentationDetents([.medium])
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 10) {
            Circle().fill(.white).frame(width: 9, height: 9)
            Circle()
                .fill(.white.opacity(step == .lastPouch ? 0.35 : 1))
                .frame(width: 9, height: 9)
            Spacer()
            OnboardingMark()
                .frame(width: 30, height: 30)
                .opacity(0.9)
        }
        .accessibilityHidden(true)
    }

    // MARK: Step 1 — last pouch

    private var lastPouchContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepHeading(
                step: "Step 1 of 2",
                title: "When did you last\nuse a pouch?",
                subtitle: "Your streak starts from this moment."
            )

            Spacer()

            VStack(spacing: 22) {
                Group {
                    if timeChoice == .justNow {
                        HeroNumber("Now", baseSize: 70)
                    } else {
                        HeroNumber(chosenTime.formatted(date: .omitted, time: .shortened), baseSize: 70)
                    }
                }
                .foregroundStyle(.white)
                .accessibilityLabel(timeChoice == .justNow ? "Now" : "Selected time \(chosenTime.formatted(date: .omitted, time: .shortened))")

                HStack(spacing: 10) {
                    timeChip("Just now", selected: timeChoice == .justNow) {
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { timeChoice = .justNow }
                    }
                    timeChip(
                        timeChoice == .specific ? chosenTime.formatted(date: .omitted, time: .shortened) : "Choose time",
                        selected: timeChoice == .specific
                    ) {
                        timeChoice = .specific
                        showTimePicker = true
                    }
                    timeChip("Earlier", selected: false) {
                        timeChoice = .specific
                        showTimePicker = true
                    }
                }
            }
            .frame(maxWidth: .infinity)

            Spacer()
        }
    }

    private func timeChip(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .foregroundStyle(selected ? Color(hex: "#566175") : .white)
                .background(
                    Capsule().fill(selected ? Color.white : Color.white.opacity(0.18))
                )
                .overlay(
                    Capsule().strokeBorder(Color.white.opacity(selected ? 0 : 0.35))
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: Step 2 — daily goal

    private var dailyGoalContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepHeading(
                step: "Step 2 of 2",
                title: "What's your daily\ngoal to start?",
                subtitle: "Reduce gradually — you can change this anytime."
            )

            Spacer()

            VStack(spacing: 18) {
                HStack(spacing: 30) {
                    stepperButton("–", enabled: dailyGoal > 1, filled: false) { dailyGoal -= 1 }
                    HeroNumber("\(dailyGoal)", baseSize: 92)
                        .foregroundStyle(.white)
                        .frame(minWidth: 110)
                        .contentTransition(.numericText())
                        .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8), value: dailyGoal)
                    stepperButton("+", enabled: dailyGoal < 20, filled: true) { dailyGoal += 1 }
                }
                Text("pouches per day")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Daily goal")
            .accessibilityValue("\(dailyGoal) pouches per day")
            .accessibilityAdjustableAction { direction in
                if direction == .increment, dailyGoal < 20 { dailyGoal += 1 }
                if direction == .decrement, dailyGoal > 1 { dailyGoal -= 1 }
            }

            Spacer()
        }
    }

    private func stepperButton(_ symbol: String, enabled: Bool, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(symbol)
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(filled ? Color(hex: "#566175") : .white)
                .frame(width: 54, height: 54)
                .background(
                    Circle().fill(filled ? Color.white : Color.white.opacity(0.18))
                )
                .overlay(Circle().strokeBorder(Color.white.opacity(filled ? 0 : 0.35)))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
    }

    // MARK: Shared

    private func stepHeading(step: String, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(step.uppercased())
                .font(.subheadline.weight(.semibold))
                .kerning(2)
                .foregroundStyle(.white.opacity(0.75))
            Text(title)
                .font(.largeTitle.weight(.bold))
                .lineSpacing(4)
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.body)
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(.top, 48)
        .accessibilityElement(children: .combine)
    }

    private var ctaButton: some View {
        Button {
            advance()
        } label: {
            Text(step == .lastPouch ? "Continue" : "Start my streak")
                .font(.body.weight(.bold))
                .foregroundStyle(Color(hex: "#566175"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(RoundedRectangle(cornerRadius: SennelRadius.button, style: .continuous).fill(.white))
                .shadow(color: .black.opacity(0.14), radius: 24, y: 10)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: step)
    }

    private func advance() {
        switch step {
        case .lastPouch:
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) { step = .dailyGoal }
        case .dailyGoal:
            appState.startDate = timeChoice == .justNow ? Date() : chosenTime
            appState.dailyLimit = dailyGoal
            appState.hasOnboarded = true
        }
    }
}

/// The app icon's ring-and-dots glyph, bare (no gradient backing) — used in the
/// onboarding header where the gradient background already does that job.
private struct OnboardingMark: View {
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: size / 2, y: size / 2)
            let radius = size * 0.32
            ZStack {
                Circle()
                    .trim(from: 0, to: 75.0 / 205)
                    .stroke(.white, style: StrokeStyle(lineWidth: size * 0.092, lineCap: .round))
                    .rotationEffect(.degrees(135))
                Circle()
                    .fill(.white)
                    .frame(width: size * 0.207, height: size * 0.207)
                    .position(x: center.x - radius * 0.45, y: center.y + radius * 0.78)
                Circle()
                    .fill(.white)
                    .frame(width: size * 0.12, height: size * 0.12)
                    .position(x: center.x + radius * 0.78, y: center.y - radius * 0.97)
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environment(AppState())
}
