import Foundation

/// One editable row in the history edit screen. Backed by plain text so
/// the user can type freely; weight/reps parse on save.
struct EditedSetRow: Identifiable {
    let id = UUID()
    /// Non-nil when this row edits an already-saved set.
    var existingSetID: UUID?
    var exercise: Exercise
    var weightText: String
    var repsText: String

    var weight: Double? { Double(weightText) }
    var reps: Int? { Int(repsText) }

    var isValid: Bool {
        (weight ?? 0) > 0 && (reps ?? 0) > 0
    }

    static func from(set: WorkoutSet) -> EditedSetRow? {
        guard let exercise = set.exercise else { return nil }
        return EditedSetRow(
            existingSetID: set.id,
            exercise: exercise,
            weightText: set.weight == set.weight.rounded()
                ? String(Int(set.weight)) : String(set.weight),
            repsText: String(set.reps)
        )
    }

    static func blank(exercise: Exercise) -> EditedSetRow {
        EditedSetRow(exercise: exercise, weightText: "", repsText: "")
    }
}
