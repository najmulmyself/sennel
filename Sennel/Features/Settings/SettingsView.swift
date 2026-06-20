import SwiftUI

/// Standard iOS list style, flat, no glass — utility screen (design doc §10).
struct SettingsView: View {
    var body: some View {
        List {
            Text("Settings")
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    SettingsView()
}
