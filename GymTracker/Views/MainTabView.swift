import SwiftUI

/// Root tab bar: Home, Workout, History, Progress.
struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)

            WorkoutView()
                .tabItem { Label("Workout", systemImage: "dumbbell.fill") }
                .tag(1)

            HistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
                .tag(2)

            ProgressScreen()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(3)
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(PreviewData.container)
}