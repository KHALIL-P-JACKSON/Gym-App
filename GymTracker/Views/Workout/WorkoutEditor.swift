import SwiftUI
import SwiftData

/// The workout logging experience: pick exercises, enter sets, finish
/// and save. Used as the Workout tab and, from History, to log a
/// workout that happened on a past day.
struct WorkoutEditor: View {
    /// When true, the user can pick the workout's date before saving
    /// (used when adding past workouts from History).
    var canPickDate: Bool = false
    /// Called after the user taps Done on the completion screen.
    var onFinished: () -> Void = {}

    @Environment(\.modelContext) private var context
    @Query(sort: \Exercise.sortOrder) private var libraryExercises: [Exercise]

    @State private var session = WorkoutSession()
    @State private var completedWorkout: Workout?
    @State private var alert: ActiveAlert?

    enum ActiveAlert: Identifiable {
        case incompleteSets(count: Int)
        case saveFailed

        var id: String {
            switch self {
            case .incompleteSets: return "incompleteSets"
            case .saveFailed: return "saveFailed"
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                if session.exercises.isEmpty {
                    EmptyStateView(
                        iconName: "hand.tap",
                        title: "Pick your first exercise",
                        message: "Choose an exercise below to start building your workout."
                    )
                } else {
                    ForEach(Array(session.exercises.enumerated()), id: \.element.exercise.id) { index, draft in
                        ExerciseCardView(
                            draft: draft,
                            onAddSet: { addSet(to: draft) },
                            onRemoveExercise: { session.removeExercise(at: index) },
                            onRemoveSet: { set in removeSet(set, from: draft) }
                        )
                    }
                }

                ExercisePickerView(
                    exercises: libraryExercises,
                    isAdded: { session.contains($0) },
                    onSelect: addExercise
                )
            }
            .padding(.top, 4)
            .padding(.horizontal, Theme.padding)
            .padding(.bottom, 8)
        }
        .background(Theme.background)
        .safeAreaInset(edge: .bottom) { finishBar }
        .fullScreenCover(item: $completedWorkout) { workout in
            WorkoutCompleteView(workout: workout) {
                completedWorkout = nil
                onFinished()
            }
        }
        .alert(item: $alert) { alert in
            switch alert {
            case .incompleteSets(let count):
                return Alert(
                    title: Text("Remove incomplete sets?"),
                    message: Text("\(count) set\(count == 1 ? "" : "s") \(count == 1 ? "has" : "have") no weight or reps and won't be saved."),
                    primaryButton: .destructive(Text("Discard & Save")) { saveWorkout() },
                    secondaryButton: .cancel(Text("Keep Editing"))
                )
            case .saveFailed:
                return Alert(
                    title: Text("Couldn't save workout"),
                    message: Text("Something went wrong while saving. Nothing was lost — please try again."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            @Bindable var session = session
            if canPickDate {
                DatePicker(
                    "Workout Date",
                    selection: $session.date,
                    in: ...Date(),
                    displayedComponents: .date
                )
            } else {
                Text(AppFormatters.longDate(session.date))
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
            }

            TextField("Workout name", text: $session.name)
                .font(.title.bold())
                .textFieldStyle(.plain)
        }
    }

    // MARK: - Bottom bar

    private var finishBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(session.exercises.count) \(session.exercises.count == 1 ? "exercise" : "exercises")")
                    .font(.subheadline.weight(.semibold))
                Text("\(session.validSetCount) valid set\(session.validSetCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
            Spacer()
            Button(action: finishWorkout) {
                Label("Finish Workout", systemImage: "checkmark")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.primary)
            .disabled(session.validSetCount == 0)
        }
        .padding(.horizontal, Theme.padding)
        .padding(.vertical, 10)
        .background(.bar, ignoresSafeAreaEdges: [.bottom, .horizontal])
    }

    // MARK: - Actions

    private func addExercise(_ exercise: Exercise) {
        guard !session.contains(exercise) else { return }
        session.addExercise(exercise)
        // Show the user's last recorded sets for this exercise.
        session.exercises.last?.previousSets = WorkoutService().previousSets(for: exercise, in: context)
    }

    private func addSet(to draft: DraftExercise) {
        withAnimation(.snappy) {
            draft.sets.append(DraftSet())
        }
    }

    private func removeSet(_ set: DraftSet, from draft: DraftExercise) {
        withAnimation(.snappy) {
            draft.sets.removeAll { $0.id == set.id }
        }
    }

    private func finishWorkout() {
        guard session.validSetCount > 0 else { return }

        let incompleteCount = session.exercises
            .flatMap { $0.sets }
            .filter { !$0.isValid }
            .count

        if incompleteCount > 0 {
            alert = .incompleteSets(count: incompleteCount)
        } else {
            saveWorkout()
        }
    }

    /// Saves the current session, then closes it and shows the summary.
    private func saveWorkout() {
        do {
            let saved = try WorkoutService().save(session: session, in: context)
            completedWorkout = saved
            session.reset()
        } catch {
            alert = .saveFailed
        }
    }
}