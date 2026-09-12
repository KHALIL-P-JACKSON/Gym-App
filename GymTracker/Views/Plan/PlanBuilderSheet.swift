import SwiftUI
import SwiftData

/// Builder sheet for a custom plan: name it, then multi-select
/// exercises from the library. The plan is saved to SwiftData.
struct PlanBuilderSheet: View {
    let exercises: [Exercise]
    var onSave: (String, [String]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedIDs: Set<UUID> = []

    private var selectedNames: [String] {
        exercises.filter { selectedIDs.contains($0.id) }.map(\.name)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Plan name") {
                    TextField("e.g. Push Day Plus", text: $name)
                        .textInputAutocapitalization(.words)
                }
                ForEach(MuscleGroup.allCases) { group in
                    let groupExercises = exercises.filter { $0.muscleGroup == group.rawValue }
                    if !groupExercises.isEmpty {
                        Section(group.displayName) {
                            ForEach(groupExercises) { exercise in
                                Button {
                                    if selectedIDs.contains(exercise.id) {
                                        selectedIDs.remove(exercise.id)
                                    } else {
                                        selectedIDs.insert(exercise.id)
                                    }
                                } label: {
                                    HStack {
                                        Text(exercise.name)
                                            .foregroundStyle(Color.primary)
                                        Spacer()
                                        if selectedIDs.contains(exercise.id) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(Theme.primary)
                                        } else {
                                            Image(systemName: "circle")
                                                .foregroundStyle(Theme.secondaryText)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(name, selectedNames)
                    }
                    .disabled(
                        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            || selectedIDs.isEmpty
                    )
                }
            }
        }
    }
}
