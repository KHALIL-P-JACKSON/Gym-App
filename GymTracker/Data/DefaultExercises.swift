import Foundation
import SwiftData

/// Muscle groups used to organize the exercise picker.
enum MuscleGroup: String, CaseIterable, Identifiable {
    case chest, back, shoulders, arms, legs

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .chest: return "Chest"
        case .back: return "Back"
        case .shoulders: return "Shoulders"
        case .arms: return "Arms"
        case .legs: return "Legs"
        }
    }

    var symbolName: String {
        switch self {
        case .chest: return "figure.strengthtraining.traditional"
        case .back: return "figure.rower"
        case .shoulders: return "figure.arms.open"
        case .arms: return "dumbbell.fill"
        case .legs: return "figure.run"
        }
    }
}

/// Push / Pull / Legs style category. Stored on the model so future
/// features (templates, day planning) can use it.
enum ExerciseCategory: String, CaseIterable {
    case push, pull, legs

    var displayName: String {
        switch self {
        case .push: return "Push"
        case .pull: return "Pull"
        case .legs: return "Legs"
        }
    }
}

/// Blueprint for a preset exercise.
struct ExerciseSeed {
    let name: String
    let muscleGroup: MuscleGroup
    let category: ExerciseCategory
}

/// The fixed library of exercises available from launch.
///
/// These are reference data only — the user's recorded results are never
/// hardcoded here.
enum DefaultExercises {

    static let seeds: [ExerciseSeed] = [
        // Chest
        ExerciseSeed(name: "Bench Press", muscleGroup: .chest, category: .push),
        ExerciseSeed(name: "Incline Bench Press", muscleGroup: .chest, category: .push),
        ExerciseSeed(name: "Dumbbell Bench Press", muscleGroup: .chest, category: .push),
        ExerciseSeed(name: "Incline Dumbbell Press", muscleGroup: .chest, category: .push),
        // Back
        ExerciseSeed(name: "Lat Pulldown", muscleGroup: .back, category: .pull),
        ExerciseSeed(name: "Seated Cable Row", muscleGroup: .back, category: .pull),
        ExerciseSeed(name: "Barbell Row", muscleGroup: .back, category: .pull),
        // Shoulders
        ExerciseSeed(name: "Shoulder Press", muscleGroup: .shoulders, category: .push),
        ExerciseSeed(name: "Lateral Raise", muscleGroup: .shoulders, category: .push),
        // Arms
        ExerciseSeed(name: "Bicep Curl", muscleGroup: .arms, category: .pull),
        ExerciseSeed(name: "Hammer Curl", muscleGroup: .arms, category: .pull),
        ExerciseSeed(name: "Tricep Pushdown", muscleGroup: .arms, category: .push),
        // Legs
        ExerciseSeed(name: "Squat", muscleGroup: .legs, category: .legs),
        ExerciseSeed(name: "Leg Press", muscleGroup: .legs, category: .legs),
        ExerciseSeed(name: "Leg Extension", muscleGroup: .legs, category: .legs),
        ExerciseSeed(name: "Leg Curl", muscleGroup: .legs, category: .legs),
        ExerciseSeed(name: "Romanian Deadlift", muscleGroup: .legs, category: .legs),
        ExerciseSeed(name: "Calf Raise", muscleGroup: .legs, category: .legs),
    ]
}

/// Inserts the preset exercises the first time the app is launched.
enum ExerciseSeeder {

    static func seedIfNeeded(in context: ModelContext) {
        // If there is already at least one exercise, the library was
        // seeded on a previous launch.
        guard (try? context.fetchCount(FetchDescriptor<Exercise>())) == 0 else { return }

        for (index, seed) in DefaultExercises.seeds.enumerated() {
            let exercise = Exercise(
                name: seed.name,
                muscleGroup: seed.muscleGroup.rawValue,
                category: seed.category.rawValue,
                isPreset: true,
                sortOrder: index
            )
            context.insert(exercise)
        }

        do {
            try context.save()
        } catch {
            // Non-fatal: the library is re-seeded on the next launch.
            print("Failed to seed preset exercises: \(error)")
        }
    }
}