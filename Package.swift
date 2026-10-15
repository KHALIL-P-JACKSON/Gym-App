// swift-tools-version: 5.9
import PackageDescription

// A macOS test harness for persistence. Build the iPhone app with Xcode.
let package = Package(
    name: "GymTrackerDrafts",
    platforms: [.macOS(.v14)],
    targets: [
        .target(
            name: "GymTrackerDrafts",
            path: "GymTracker",
            exclude: ["Assets.xcassets", "Components", "Data", "Utilities", "Views",
                      "App/GymTrackerApp.swift", "App/Theme.swift", "Models/WorkoutPlan.swift",
                      "Services/PlanStore.swift", "Services/ProgressCalculator.swift"],
            sources: ["Models/Exercise.swift", "Models/Workout.swift", "Models/WorkoutSet.swift",
                      "Services/WorkoutSession.swift", "Services/WorkoutService.swift",
                      "Services/WorkoutDraftStore.swift"]
        ),
        .testTarget(name: "GymTrackerDraftsTests", dependencies: ["GymTrackerDrafts"], path: "Tests")
    ]
)
