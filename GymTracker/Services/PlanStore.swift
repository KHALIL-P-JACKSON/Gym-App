import Foundation
import SwiftData

/// Persistence helpers for workout plans (preset splits + user plans).
struct PlanStore {

    /// Inserts missing preset plans and fixes sort order. User plans are
    /// never modified or removed.
    static func seedIfNeeded(in context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<WorkoutPlan>())) ?? []
        let existingByName = Dictionary(
            existing.map { ($0.name, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        var madeChanges = false
        for (index, seed) in DefaultPlans.seeds.enumerated() {
            if let installed = existingByName[seed.name] {
                if installed.sortOrder != index || !installed.isPreset {
                    installed.sortOrder = index
                    installed.isPreset = true
                    installed.exerciseNames = seed.exerciseNames
                    madeChanges = true
                }
            } else {
                context.insert(WorkoutPlan(
                    name: seed.name,
                    exerciseNames: seed.exerciseNames,
                    isPreset: true,
                    sortOrder: index
                ))
                madeChanges = true
            }
        }
        // Shift user plans after presets so ordering stays stable.
        let userPlans = existing.filter { !$0.isPreset }.sorted { $0.createdAt < $1.createdAt }
        for (offset, plan) in userPlans.enumerated() {
            let target = DefaultPlans.seeds.count + offset
            if plan.sortOrder != target {
                plan.sortOrder = target
                madeChanges = true
            }
        }
        guard madeChanges else { return }
        try? context.save()
    }

    /// Creates a user plan from the given name + exercise names.
    @discardableResult
    static func create(name: String, exerciseNames: [String], in context: ModelContext) -> WorkoutPlan? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !exerciseNames.isEmpty else { return nil }
        let existing = (try? context.fetch(FetchDescriptor<WorkoutPlan>())) ?? []
        let nextOrder = (existing.map(\.sortOrder).max() ?? -1) + 1
        let plan = WorkoutPlan(name: trimmed, exerciseNames: exerciseNames, isPreset: false, sortOrder: nextOrder)
        context.insert(plan)
        try? context.save()
        return plan
    }

    static func delete(_ plan: WorkoutPlan, in context: ModelContext) {
        context.delete(plan)
        try? context.save()
    }

    /// Resolves a plan's exercise names to installed Exercise objects,
    /// preserving the plan's order and skipping missing names.
    static func resolveExercises(for plan: WorkoutPlan, from library: [Exercise]) -> [Exercise] {
        let byName = Dictionary(library.map { ($0.name, $0) }, uniquingKeysWith: { first, _ in first })
        return plan.exerciseNames.compactMap { byName[$0] }
    }
}
