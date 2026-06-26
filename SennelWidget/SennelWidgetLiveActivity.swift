//
//  SennelWidgetLiveActivity.swift
//  SennelWidget
//
//  Created by Najmul Huda on 6/27/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct SennelWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct SennelWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SennelWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension SennelWidgetAttributes {
    fileprivate static var preview: SennelWidgetAttributes {
        SennelWidgetAttributes(name: "World")
    }
}

extension SennelWidgetAttributes.ContentState {
    fileprivate static var smiley: SennelWidgetAttributes.ContentState {
        SennelWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: SennelWidgetAttributes.ContentState {
         SennelWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: SennelWidgetAttributes.preview) {
   SennelWidgetLiveActivity()
} contentStates: {
    SennelWidgetAttributes.ContentState.smiley
    SennelWidgetAttributes.ContentState.starEyes
}
