import Foundation

/// A separate file keeps unfinished entries out of workout history. There is
/// deliberately no expiry: the draft stays until the workout is finished/reset.
struct WorkoutDraftStore {
    let fileURL: URL

    init(fileURL: URL = URL.applicationSupportDirectory
        .appendingPathComponent("GymTracker", isDirectory: true)
        .appendingPathComponent("active-workout.json")) {
        self.fileURL = fileURL
    }

    func load() throws -> WorkoutDraft? {
        do {
            return try JSONDecoder().decode(WorkoutDraft.self, from: Data(contentsOf: fileURL))
        } catch CocoaError.fileReadNoSuchFile {
            return nil
        }
    }

    func save(_ draft: WorkoutDraft) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        // Replace the whole snapshot atomically so a terminated write can't
        // leave a half-written draft behind.
        try JSONEncoder().encode(draft).write(to: fileURL, options: .atomic)
    }

    func clear() throws {
        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch CocoaError.fileNoSuchFile {
            // A new/empty session has no draft to remove.
        }
    }
}

struct WorkoutDraft: Codable {
    var name: String
    var date: Date
    var exercises: [ExerciseEntry]

    struct ExerciseEntry: Codable {
        var exerciseID: UUID
        var isComplete: Bool
        var sets: [SetEntry]
    }

    struct SetEntry: Codable {
        var weightText: String
        var repsText: String
        /// Older drafts used pounds and did not include this field.
        var entryUnit: String?
    }
}
