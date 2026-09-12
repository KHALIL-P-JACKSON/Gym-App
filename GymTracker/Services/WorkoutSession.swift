import Foundation
import Observation
import SwiftData

/// In-memory representation of the workout currently being logged.
///
/// Nothing is written to disk until the user finishes the workout, which
/// keeps the database clean and makes deleting a set or exercise free.
@Observable
final class WorkoutSession {
    var name: String
    var exercises: [DraftExercise]

    init(name: String = "Workout", exercises: [DraftExercise] = []) {
        self.name = name
        self.exercises = exercises
    }

    var isEmpty: Bool { exercises.isEmpty }

    func contains(_ exercise: Exercise) -> Bool {
        exercises.contains { $0.exercise.id == exercise.id }
    }

    func addExercise(_ exercise: Exercise) {
        guard !contains(exercise) else { return }
        exercises.append(DraftExercise(exercise: exercise))
    }

    func removeExercise(at index: Int) {
        guard exercises.indices.contains(index) else { return }
        exercises.remove(at: index)
    }

    func reset() {
        name = "Workout"
        exercises = []
    }

    /// Sets that have both a weight and a rep count.
    var validSets: [DraftSet] {
        exercises.flatMap { $0.sets }.filter { $0.isValid }
    }

    var validSetCount: Int { validSets.count }
}

/// A preset exercise that was added to the current workout session.
@Observable
final class DraftExercise {
    let exercise: Exercise
    var sets: [DraftSet]
    /// Sets from the user's most recent workout with this exercise.
    var previousSets: [WorkoutSet] = []

    init(exercise: Exercise, sets: [DraftSet] = []) {
        self.exercise = exercise
        self.sets = sets.isEmpty ? [DraftSet()] : sets
    }
}

/// A partially entered set. Weight and reps are kept as text so the user
/// can type freely; they are parsed and validated when the workout saves.
@Observable
final class DraftSet: Identifiable {
    let id = UUID()
    var weightText: String
    var repsText: String

    init(weightText: String = "", repsText: String = "") {
        self.weightText = weightText
        self.repsText = repsText
    }

    var weight: Double? { Double(weightText) }
    var reps: Int? { Int(repsText) }

    var isValid: Bool {
        (weight ?? 0) > 0 && (reps ?? 0) > 0
    }
}