import XCTest
import SwiftData
@testable import GymTrackerDrafts

@MainActor
final class WorkoutDraftPersistenceTests: XCTestCase {
    private func container(at directory: URL) throws -> ModelContainer {
        let schema = Schema([Exercise.self, Workout.self, WorkoutSet.self])
        return try ModelContainer(for: schema, configurations: [
            ModelConfiguration(schema: schema, url: directory.appendingPathComponent("history.store"))
        ])
    }

    private func withStore(_ test: (URL, WorkoutDraftStore) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try test(directory, WorkoutDraftStore(fileURL: directory.appendingPathComponent("draft.json")))
    }

    private func exercise(_ name: String, in context: ModelContext) throws -> Exercise {
        let exercise = Exercise(name: name, muscleGroup: "Chest", category: "Push", isPreset: false)
        context.insert(exercise)
        try context.save()
        return exercise
    }

    func testRelaunchRestoresOldDraftWithPartialSetsAndLocks() async throws {
        try withStore { directory, store in
            let date = Date(timeIntervalSince1970: 1_000_000)
            do {
                let database = try container(at: directory)
                let context = database.mainContext
                let session = WorkoutSession.restore(in: context, store: store)
                session.addExercise(try exercise("Bench Press", in: context))
                session.name = "Push Day"
                session.date = date
                let draft = try XCTUnwrap(session.exercises.first)
                draft.sets[0].weightText = "82.50"
                draft.sets[0].repsText = "8"
                draft.isComplete = true
                session.addExercise(try exercise("Fly", in: context))
                session.exercises[1].sets[0].weightText = "12."
            }

            // Reopen both stores without keeping any session/model instances.
            let reopened = try container(at: directory)
            let session = WorkoutSession.restore(in: reopened.mainContext, store: store)
            XCTAssertEqual(session.name, "Push Day")
            XCTAssertEqual(session.date, date)
            XCTAssertEqual(session.exercises.map { $0.exercise.name }, ["Bench Press", "Fly"])
            XCTAssertTrue(session.exercises[0].isComplete)
            XCTAssertEqual(session.exercises[0].sets[0].weightText, "82.50")
            XCTAssertEqual(session.exercises[0].sets[0].repsText, "8")
            XCTAssertEqual(session.exercises[1].sets[0].weightText, "12.")
            XCTAssertEqual(session.exercises[1].sets[0].repsText, "")
            XCTAssertTrue(try reopened.mainContext.fetch(FetchDescriptor<Workout>()).isEmpty)
        }
    }

    func testResumedEditsAndRemovalsAreSavedImmediately() async throws {
        try withStore { directory, store in
            let database = try container(at: directory)
            let context = database.mainContext
            let session = WorkoutSession.restore(in: context, store: store)
            let bench = try exercise("Bench", in: context)
            let fly = try exercise("Fly", in: context)
            session.addExercises([bench, fly])
            let resumed = WorkoutSession.restore(in: context, store: store)
            resumed.exercises[0].sets.append(DraftSet(weightText: "90", repsText: "6"))
            resumed.exercises[0].sets.removeFirst()
            resumed.exercises[0].sets[0].repsText = "7"
            resumed.exercises[0].isComplete = true
            resumed.removeExercise(at: 1)
            let restored = WorkoutSession.restore(in: context, store: store)
            XCTAssertEqual(restored.exercises.count, 1)
            XCTAssertEqual(restored.exercises[0].sets.count, 1)
            XCTAssertEqual(restored.exercises[0].sets[0].repsText, "7")
            XCTAssertTrue(restored.exercises[0].isComplete)
            restored.exercises[0].isComplete = false
            XCTAssertFalse(try XCTUnwrap(store.load()).exercises[0].isComplete)
        }
    }

    func testFinishingClearsDraftAndKeepsHistory() async throws {
        try withStore { directory, store in
            let database = try container(at: directory)
            let context = database.mainContext
            let session = WorkoutSession.restore(in: context, store: store)
            session.addExercise(try exercise("Bench", in: context))
            session.exercises[0].sets[0].weightText = "185"
            session.exercises[0].sets[0].repsText = "8"
            _ = try WorkoutService().save(session: session, in: context)
            session.reset()
            XCTAssertNil(try store.load())
            XCTAssertTrue(WorkoutSession.restore(in: context, store: store).isEmpty)
            XCTAssertEqual(try context.fetch(FetchDescriptor<Workout>()).count, 1)
        }
    }

    func testEmptyLaunchAndIsolatedHistoryEditorLeaveDraftAlone() async throws {
        try withStore { directory, store in
            let database = try container(at: directory)
            let context = database.mainContext
            let session = WorkoutSession.restore(in: context, store: store)
            XCTAssertTrue(session.isEmpty)
            XCTAssertNil(try store.load())
            session.name = "Saved name"
            let local = WorkoutSession()
            local.addExercise(try exercise("Bench", in: context))
            local.reset()
            XCTAssertEqual(try XCTUnwrap(store.load()).name, "Saved name")
            session.reset()
            XCTAssertNil(try store.load())
        }
    }
}
