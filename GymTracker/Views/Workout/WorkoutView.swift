import SwiftUI

/// The Workout tab. Presents the shared logging editor; a draft in
/// progress survives tab switches and relaunches because the app owns
/// and persists the session shared with the Plan tab.
struct WorkoutView: View {
    @Bindable var session: WorkoutSession

    var body: some View {
        WorkoutEditor(session: session)
            .navigationTitle("Workout")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        WorkoutView(session: WorkoutSession())
    }
    .modelContainer(PreviewData.container)
}
