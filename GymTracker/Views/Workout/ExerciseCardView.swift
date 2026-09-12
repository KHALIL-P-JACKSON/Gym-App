import SwiftUI
import SwiftData

/// A card for one exercise being logged in the current workout.
/// Shows the user's last performance, set inputs, and an Add Set button.
struct ExerciseCardView: View {
    @Bindable var draft: DraftExercise
    var onAddSet: () -> Void
    var onRemoveExercise: () -> Void
    var onRemoveSet: (DraftSet) -> Void

    @FocusState private var focusedField: SetField?
    @State private var pendingFocus: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            if !draft.previousSets.isEmpty {
                lastWorkoutStrip
            }
            columnHeader
            ForEach(Array(draft.sets.enumerated()), id: \.element.id) { index, set in
                SetRow(
                    set: set,
                    setNumber: index + 1,
                    onRemove: { onRemoveSet(set) },
                    weightField: $focusedField,
                    repsField: $focusedField
                )
                .onAppear {
                    if pendingFocus == set.id {
                        focusedField = .weight(set.id)
                        pendingFocus = nil
                    }
                }
            }
            addSetButton
        }
        .padding(Theme.padding)
        .cardStyle()
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(draft.exercise.name)
                    .font(.headline)
                Text(draft.exercise.muscleGroup.capitalized)
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
            Spacer()
            Button(action: onRemoveExercise) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Theme.secondaryText)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(draft.exercise.name)")
        }
    }

    /// Summary of the user's most recent session with this exercise.
    private var lastWorkoutStrip: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Last Workout")
                    .sectionHeaderStyle()
                Spacer()
                if let date = draft.previousSets.first?.workout?.date {
                    Text(AppFormatters.shortDate(date))
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            ForEach(draft.previousSets.prefix(3)) { set in
                HStack {
                    Text("Set \(set.setNumber)")
                        .foregroundStyle(Theme.secondaryText)
                    Spacer()
                    Text("\(AppFormatters.weight(set.weight)) lb × \(set.reps)")
                        .monospacedDigit()
                }
                .font(.subheadline)
            }
        }
        .padding(12)
        .background(
            Theme.primary.opacity(0.10),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
    }

    private var columnHeader: some View {
        HStack(spacing: 8) {
            Text("Set")
                .frame(width: 24, alignment: .leading)
            Text("Weight (lb)")
                .frame(maxWidth: .infinity)
            Text("Reps")
                .frame(maxWidth: .infinity)
            Text("")
                .frame(width: 28)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(Theme.secondaryText)
    }

    private var addSetButton: some View {
        Button {
            onAddSet()
            // Focus the new row's weight field once it appears.
            pendingFocus = draft.sets.last?.id
        } label: {
            Label("Add Set", systemImage: "plus")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.bordered)
        .tint(Theme.primary)
    }
}