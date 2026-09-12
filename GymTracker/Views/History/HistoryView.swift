import SwiftUI
import SwiftData

/// Chronological list of completed workouts.
struct HistoryView: View {
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]

    var body: some View {
        NavigationStack {
            Group {
                if workouts.isEmpty {
                    EmptyStateView(
                        iconName: "clock.arrow.circlepath",
                        title: "No workouts yet",
                        message: "Record your first workout and it will show up here."
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(workouts) { workout in
                                NavigationLink {
                                    WorkoutDetailView(workout: workout)
                                } label: {
                                    WorkoutRow(workout: workout)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(Theme.padding)
                    }
                }
            }
            .background(Theme.background)
            .navigationTitle("History")
        }
    }
}

/// A single history entry card.
private struct WorkoutRow: View {
    let workout: Workout

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(workout.name)
                    .font(.headline)
                Spacer()
                Text(AppFormatters.relativeDate(workout.date))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.secondaryText)
            }

            HStack(spacing: 14) {
                Label("\(workout.exerciseCount) exercises", systemImage: "figure.strengthtraining.traditional")
                Label("\(workout.setCount) sets", systemImage: "number")
                Label(AppFormatters.volume(workout.totalVolume), systemImage: "scalemass")
            }
            .font(.caption)
            .foregroundStyle(Theme.secondaryText)
        }
        .padding(Theme.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

#Preview {
    HistoryView()
        .modelContainer(PreviewData.container)
}