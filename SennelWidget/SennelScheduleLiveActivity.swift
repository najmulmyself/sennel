import ActivityKit
import WidgetKit
import SwiftUI
import Foundation

struct SennelScheduleLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SennelScheduleActivityAttributes.self) { context in
            liveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Next slot in")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(timerInterval: context.state.nextEligibleSlot...Date.distantFuture, pauseTime: .distantFuture)
                            .font(.system(.title3, design: .monospaced).weight(.bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Slots used")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text("\(context.state.usedToday) / \(context.state.dailyLimit)")
                            .font(.system(.title3, design: .monospaced).weight(.bold))
                    }
                }
            } compactLeading: {
                Text("\(context.state.usedToday) / \(context.state.dailyLimit)")
                    .font(.system(.body, design: .monospaced).weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            } compactTrailing: {
                Text(timerInterval: context.state.nextEligibleSlot...Date.distantFuture, pauseTime: .distantFuture)
                    .font(.system(.caption, design: .monospaced).weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            } minimal: {
                Text(timerInterval: context.state.nextEligibleSlot...Date.distantFuture, pauseTime: .distantFuture)
                    .font(.caption.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .keylineTint(.cyan)
        }
    }

    @ViewBuilder
    private func liveActivityView(context: ActivityViewContext<SennelScheduleActivityAttributes>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Next slot countdown")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(timerInterval: context.state.nextEligibleSlot...Date.distantFuture, pauseTime: .distantFuture)
                        .font(.system(.title2, design: .monospaced).weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Slots used")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("\(context.state.usedToday) / \(context.state.dailyLimit)")
                        .font(.system(.title2, design: .monospaced).weight(.bold))
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(red: 0.95, green: 1.0, blue: 0.98))
        .cornerRadius(12)
    }
}
