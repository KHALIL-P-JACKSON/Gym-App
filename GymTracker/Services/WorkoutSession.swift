import Foundation
import Observation
import SwiftData

/// The workout currently being logged. The shared session autosaves a draft
/// after every edit; one-off editors and previews use an unpersisted session.
@Observable
final class WorkoutSession {
    var name: String { didSet { saveDraft() } }
    /// The date this workout took place. Normally "now", but can be a
    /// past day when backfilling earlier workouts from History.
    var date: Date { didSet { saveDraft() } }
    var exercises: [DraftExercise] {
        didSet {
            observeExercises()
            saveDraft()
        }
    }

    private let draftStore: WorkoutDraftStore?
    @ObservationIgnored private var isResetting = false

    init(
        name: String = "Workout",
        date: Date = .now,
        exercises: [DraftExercise] = [],
        draftStore: WorkoutDraftStore? = nil
    ) {
        self.name = name
        self.date = date
        self.exercises = exercises
        self.draftStore = draftStore
        observeExercises()
    }

    /// Resolve stable exercise IDs against SwiftData after seeding the library.
    /// Previous performance is derived from history rather than cached in JSON.
    static func restore(in context: ModelContext, store: WorkoutDraftStore = WorkoutDraftStore()) -> WorkoutSession {
        do {
            guard let draft = try store.load() else {
                return WorkoutSession(draftStore: store)
            }
            let library = try context.fetch(FetchDescriptor<Exercise>())
            let exercises = draft.exercises.compactMap { entry -> DraftExercise? in
                guard let exercise = library.first(where: { $0.id == entry.exerciseID }) else { return nil }
                let restored = DraftExercise(exercise: exercise, sets: entry.sets.map {
                    DraftSet(
                        weightText: $0.weightText,
                        repsText: $0.repsText,
                        entryUnit: WeightUnit(rawValue: $0.entryUnit ?? "lb") ?? .lb
                    )
                })
                restored.isComplete = entry.isComplete
                restored.previousSets = WorkoutService().previousSets(for: exercise, in: context)
                return restored
            }
            return WorkoutSession(name: draft.name, date: draft.date, exercises: exercises, draftStore: store)
        } catch {
            NSLog("Couldn't restore workout draft: %@", error.localizedDescription)
            return WorkoutSession(draftStore: store)
        }
    }

    private func observeExercises() {
        for draft in exercises {
            draft.onChange = { [weak self] in self?.saveDraft() }
        }
    }

    private func saveDraft() {
        guard let draftStore, !isResetting else { return }
        do {
            if exercises.isEmpty && name == "Workout" {
                try draftStore.clear()
            } else {
                try draftStore.save(WorkoutDraft(name: name, date: date, exercises: exercises.map { draft in
                    WorkoutDraft.ExerciseEntry(
                        exerciseID: draft.exercise.id,
                        isComplete: draft.isComplete,
                        sets: draft.sets.map {
                            WorkoutDraft.SetEntry(
                                weightText: $0.weightText,
                                repsText: $0.repsText,
                                entryUnit: $0.entryUnit.rawValue
                            )
                        }
                    )
                }))
            }
        } catch {
            NSLog("Couldn't save workout draft: %@", error.localizedDescription)
        }
    }

    var isEmpty: Bool { exercises.isEmpty }

    func contains(_ exercise: Exercise) -> Bool {
        exercises.contains { $0.exercise.id == exercise.id }
    }

    func addExercise(_ exercise: Exercise) {
        guard !contains(exercise) else { return }
        exercises.append(DraftExercise(exercise: exercise))
    }

    /// Adds every exercise in the list that isn't already in the session.
    /// Returns the number of exercises actually added.
    @discardableResult
    func addExercises(_ exercisesToAdd: [Exercise]) -> Int {
        var added = 0
        for exercise in exercisesToAdd where !contains(exercise) {
            exercises.append(DraftExercise(exercise: exercise))
            added += 1
        }
        return added
    }

    func removeExercise(at index: Int) {
        guard exercises.indices.contains(index) else { return }
        exercises.remove(at: index)
    }

    func reset() {
        isResetting = true
        name = "Workout"
        date = .now
        exercises = []
        isResetting = false
        saveDraft()
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
    var sets: [DraftSet] {
        didSet {
            observeSets()
            onChange?()
        }
    }
    @ObservationIgnored var onChange: (() -> Void)?
    /// Sets from the user's most recent workout with this exercise.
    var previousSets: [WorkoutSet] = []
    /// When true the exercise is locked: values can't be edited until
    /// the user taps Edit again.
    var isComplete: Bool = false { didSet { onChange?() } }

    init(exercise: Exercise, sets: [DraftSet] = []) {
        self.exercise = exercise
        self.sets = sets.isEmpty ? [DraftSet()] : sets
        observeSets()
    }

    private func observeSets() {
        for set in sets {
            set.onChange = { [weak self] in self?.onChange?() }
        }
    }

    /// All sets have a weight and rep count (and at least one set exists).
    var hasValidSets: Bool {
        !sets.isEmpty && sets.allSatisfy { $0.isValid }
    }
}

/// A partially entered set. Weight and reps are kept as text so the user
/// can type freely; they are parsed and validated when the workout saves.
///
/// `weightText` is always in `entryUnit`; `weight` converts back to
/// stored pounds.
@Observable
final class DraftSet: Identifiable {
    let id = UUID()
    var weightText: String { didSet { onChange?() } }
    var repsText: String { didSet { onChange?() } }
    @ObservationIgnored var onChange: (() -> Void)?
    /// Unit the weight text was entered in (snapshot of the setting when
    /// the row was created).
    var entryUnit: WeightUnit { didSet { onChange?() } }

    init(weightText: String = "", repsText: String = "", entryUnit: WeightUnit = AppSettings.weightUnit) {
        self.weightText = weightText
        self.repsText = repsText
        self.entryUnit = entryUnit
    }

    /// Parsed weight converted to stored pounds.
    var weight: Double? {
        guard let value = Double(weightText) else { return nil }
        return entryUnit.toPounds(value)
    }
    var reps: Int? { Int(repsText) }

    var isValid: Bool {
        (weight ?? 0) > 0 && (reps ?? 0) > 0
    }
}
