import SwiftUI

struct TodayPlanCard: View {
    @EnvironmentObject var store: PlannerStore
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingMD) {
            Text("Today's Plan")
                .font(.titleMedium)
                .foregroundStyle(Theme.textPrimary)

            if let workout = store.todayPlan.workout {
                workoutRow(workout)
                Divider().background(Theme.separator)
                keyMealsSection
            } else {
                emptyState
            }

            if let rec = store.autoRecommendation {
                autoModeBar(rec)
            }
        }
        .primeCutCard()
        .cardBorder()
    }

    // MARK: - Workout row
    private func workoutRow(_ workout: Workout) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(workout.type.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: workout.type.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(workout.type.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(workout.type.label)
                    .font(.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.textPrimary)
                Text("\(workout.startTime.hourMinuteString) · \(workout.durationString)")
                    .font(.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
        }
    }

    // MARK: - Key meals
    private var keyMealsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Key Meals")
                .font(.labelLarge)
                .foregroundStyle(Theme.textSecondary)

            let keyMeals = store.todayPlan.meals.filter { $0.timing.isWorkoutRelated }
            if keyMeals.isEmpty {
                Text("No workout-linked meals yet")
                    .font(.bodyMedium)
                    .foregroundStyle(Theme.textTertiary)
            } else {
                ForEach(keyMeals) { meal in
                    HStack(spacing: 8) {
                        Image(systemName: meal.timing.icon)
                            .font(.system(size: 12))
                            .foregroundStyle(settings.accentColor)
                            .frame(width: 16)

                        Text(meal.timing.rawValue)
                            .font(.bodyMedium)
                            .foregroundStyle(Theme.textPrimary)

                        Spacer()

                        Text(meal.scheduledTime.hourMinuteString)
                            .font(.labelLarge)
                            .foregroundStyle(settings.accentColor)
                    }
                }
            }
        }
    }

    // MARK: - Empty state
    private var emptyState: some View {
        HStack(spacing: 10) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 22))
                .foregroundStyle(Theme.textTertiary)
            VStack(alignment: .leading, spacing: 2) {
                Text("No workout planned")
                    .font(.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)
                Text("Go to Planner to add one")
                    .font(.caption)
                    .foregroundStyle(Theme.textTertiary)
            }
            Spacer()
        }
    }

    // MARK: - Auto mode banner
    private func autoModeBar(_ rec: AutoModeRecommendation) -> some View {
        HStack(spacing: 8) {
            Image(systemName: rec.carbAdjustment.icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(settings.accentColor)
            Text("Auto: \(rec.carbAdjustment.rawValue)")
                .font(.labelLarge)
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            Text(rec.workoutSuggestion.rawValue)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(settings.accentColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSmall))
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        TodayPlanCard()
            .environmentObject(PlannerStore())
            .environmentObject(SettingsStore())
            .padding()
    }
}
