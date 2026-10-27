import SwiftUI

/// Root tab bar: Home, Workout, Plan, History, Progress.
/// Shares the app's restored workout session with the Workout and Plan tabs.
struct MainTabView: View {
    @State private var selectedTab = 0
    @Bindable var session: WorkoutSession

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)

            WorkoutView(session: session)
                .tabItem { Label("Workout", systemImage: "dumbbell.fill") }
                .tag(1)

            PlanView(session: session, selectedTab: $selectedTab)
                .tabItem { Label("Plan", systemImage: "clipboard.fill") }
                .tag(2)

            HistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
                .tag(3)

            ProgressScreen()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(4)
        }
    }
}

#Preview {
    MainTabView(session: WorkoutSession())
        .modelContainer(PreviewData.container)
}
