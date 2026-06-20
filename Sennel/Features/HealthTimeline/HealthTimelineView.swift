import SwiftUI

/// Flat milestone list (no glass, per design doc §10). Real milestone data and
/// styling land in the UI pass.
struct HealthTimelineView: View {
    var body: some View {
        List {
            Text("Health Timeline")
        }
        .navigationTitle("Health Timeline")
    }
}
