import SwiftUI
import WidgetKit

struct SennelWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: SennelWidgetTimelineProvider.Entry

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        case .accessoryRectangular:
            lockScreenWidget
        default:
            emptyWidget
        }
    }

    @ViewBuilder
    private var smallWidget: some View {
        if entry.isPremium {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(red: 0.2, green: 0.8, blue: 0.6))
                    Text("Sennel")
                        .font(.caption.weight(.bold))
                    Spacer()
                }
                Spacer()
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(entry.usedToday) / \(entry.dailyLimit)")
                        .font(.system(.body, design: .monospaced).weight(.semibold))
                    Text("Slots today")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(Color(red: 0.95, green: 1.0, blue: 0.98))
            .cornerRadius(12)
        } else {
            paywallPlaceholder
        }
    }

    @ViewBuilder
    private var mediumWidget: some View {
        if entry.isPremium, let nextSlot = entry.nextSlot {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color(red: 0.2, green: 0.8, blue: 0.6))
                        Text("Sennel")
                            .font(.caption.weight(.bold))
                        Spacer()
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(entry.usedToday) / \(entry.dailyLimit)")
                            .font(.system(.title3, design: .monospaced).weight(.semibold))
                        Text("Slots today")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Divider()
                VStack(alignment: .center, spacing: 6) {
                    Text("Next slot")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(timerInterval: nextSlot..., pauseTime: .distantFuture)
                        .font(.system(.body, design: .monospaced).weight(.semibold))
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                }
            }
            .padding(12)
            .background(Color(red: 0.95, green: 1.0, blue: 0.98))
            .cornerRadius(12)
        } else if entry.isPremium {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sennel")
                        .font(.caption.weight(.bold))
                    Spacer()
                    Text("\(entry.usedToday) / \(entry.dailyLimit)")
                        .font(.title3.weight(.semibold))
                    Text("Slots used")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Divider()
                VStack(alignment: .center, spacing: 6) {
                    Text("No slots")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("left today")
                        .font(.system(.body, design: .monospaced).weight(.semibold))
                }
            }
            .padding(12)
            .background(Color(red: 0.95, green: 1.0, blue: 0.98))
            .cornerRadius(12)
        } else {
            paywallPlaceholder
        }
    }

    @ViewBuilder
    private var lockScreenWidget: some View {
        if entry.isPremium, let nextSlot = entry.nextSlot {
            VStack(alignment: .leading, spacing: 2) {
                Text("Next slot")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(timerInterval: nextSlot..., pauseTime: .distantFuture)
                    .font(.system(.body, design: .monospaced).weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        } else if entry.isPremium {
            Text("All slots used")
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        } else {
            Text("Unlock Premium")
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    @ViewBuilder
    private var emptyWidget: some View {
        Text("Not supported")
            .font(.caption)
    }

    @ViewBuilder
    private var paywallPlaceholder: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .semibold))
                Text("Unlock Premium")
                    .font(.caption.weight(.bold))
                Spacer()
            }
            Spacer()
            Text("Get widgets & more")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color(red: 1.0, green: 0.98, blue: 0.95))
        .cornerRadius(12)
    }
}

#Preview {
    SennelWidgetView(entry: SennelWidgetEntry(
        date: .now,
        nextSlot: Date(timeIntervalSinceNow: 3600),
        usedToday: 3,
        dailyLimit: 8,
        isPremium: true
    ))
    .previewContext(WidgetPreviewContext(family: .systemMedium))
}
