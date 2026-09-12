import SwiftUI

/// The Workout tab. Presents the shared logging editor; a draft in
/// progress survives tab switches because the editor keeps its state
/// within the tab's view hierarchy.
struct WorkoutView: View {
    var body: some View {
        WorkoutEditor()
            .navigationTitle("Workout")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        WorkoutView()
    }
    .modelContainer(PreviewData.container)
}