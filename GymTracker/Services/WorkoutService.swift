import Foundation
import SwiftData

/// Handles creating and saving workouts, and loading historical info
/// for an exercise.
struct WorkoutService {

    /// Converts the in-memory session into persisted SwiftData models.
    /// Sets without a weight or reps are skipped so invalid data never
    /// reaches the database.
    /// - Returns: the newly saved Workout.
    func save(session: WorkoutSession, in context: ModelContext) throws -> Workout {
        let workout = Workout(date: session.date, name: cleanedName(session.name))

        var globalOrder = 0
        for draftExercise in session.exercises {
            var setNumber = 0
            for draftSet in draftExercise.sets where draftSet.isValid {
                setNumber += 1
                let set = WorkoutSet(
                    weight: draftSet.weight ?? 0,
                    reps: draftSet.reps ?? 0,
                    setNumber: setNumber,
                    sortOrder: globalOrder
                )
                set.exercise = draftExercise.exercise
                set.workout = workout
                workout.sets.append(set)
                context.insert(set)
                globalOrder += 1
            }
        }

        context.insert(workout)
        try context.save()
        return workout
    }

    /// Returns the sets from the most recent workout that used the given
    /// exercise, newest workout first.
    func previousSets(for exercise: Exercise, limit: Int = 3, in context: ModelContext) -> [WorkoutSet] {
        guard let allSets = try? context.fetch(FetchDescriptor<WorkoutSet>()) else { return [] }

        let exerciseSets = allSets.filter { $0.exercise?.id == exercise.id }
        let sorted = exerciseSets.sorted { lhs, rhs in
            let lhsDate = lhs.workout?.date ?? .distantPast
            let rhsDate = rhs.workout?.date ?? .distantPast
            if lhsDate != rhsDate {
                return lhsDate > rhsDate
            }
            return lhs.sortOrder < rhs.sortOrder
        }

        guard let newestWorkoutID = sorted.first?.workout?.id else { return [] }
        return Array(sorted
            .filter { $0.workout?.id == newestWorkoutID }
            .prefix(limit))
    }

    private func cleanedName(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Workout" : trimmed
    }
}