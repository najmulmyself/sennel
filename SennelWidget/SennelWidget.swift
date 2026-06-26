import WidgetKit
import SwiftUI

/// Home-screen + lock-screen widget. Reads the shared App Group store via
/// `SennelWidgetTimelineProvider` and renders the per-family UI in
/// `SennelWidgetView` (small = slots used, medium = slots + next-slot countdown,
/// accessoryRectangular = lock-screen countdown). Gated on premium in the view.
struct SennelWidget: Widget {
    let kind: String = "SennelWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SennelWidgetTimelineProvider()) { entry in
            SennelWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Sennel")
        .description("Your next pouch slot and today's progress.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}
