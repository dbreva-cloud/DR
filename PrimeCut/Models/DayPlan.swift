import Foundation

// MARK: - Checklist item
struct ChecklistItem: Identifiable, Codable {
    var id = UUID()
    var label: String
    var isChecked: Bool = false
}

// MARK: - DayPlan
struct DayPlan: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var workout: Workout?
    var meals: [Meal] = []
    var checklist: [ChecklistItem]
    var stepGoal: Double
    var steps: Double = 0

    // Computed streak eligibility: all checklist items done
    var isComplete: Bool {
        checklist.allSatisfy(\.isChecked)
    }

    var stepProgress: Double {
        min(steps / stepGoal, 1.0)
    }

    init(date: Date = .now, stepGoal: Double = 8000) {
        self.date = date
        self.stepGoal = stepGoal
        self.checklist = [
            ChecklistItem(label: "Breakfast"),
            ChecklistItem(label: "Lunch"),
            ChecklistItem(label: "Dinner"),
            ChecklistItem(label: "Workout"),
            ChecklistItem(label: "Step Goal"),
        ]
    }

    // Generate auto meals from a planned workout
    mutating func generateMeals(from workout: Workout) {
        // Remove existing workout-related meals
        meals.removeAll { $0.timing.isWorkoutRelated }

        if workout.type != .rest {
            let pre = Meal(
                timing: .preWorkout,
                scheduledTime: workout.preWorkoutMealTime,
                macros: .preWorkout(for: workout.type),
                linkedWorkoutID: workout.id
            )
            let post = Meal(
                timing: .postWorkout,
                scheduledTime: workout.postWorkoutMealTime,
                macros: .postWorkout(for: workout.type),
                linkedWorkoutID: workout.id
            )
            meals.append(contentsOf: [pre, post])
        }

        // Ensure base meals exist
        ensureBaseMeals()
        sortMeals()
    }

    mutating func ensureBaseMeals() {
        let baseMealTimings: [(MealTiming, Int)] = [
            (.breakfast, 8),
            (.lunch, 13),
            (.dinner, 19)
        ]
        for (timing, hour) in baseMealTimings {
            if !meals.contains(where: { $0.timing == timing }) {
                var comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
                comps.hour = hour
                comps.minute = 0
                let mealTime = Calendar.current.date(from: comps) ?? date
                meals.append(Meal(timing: timing, scheduledTime: mealTime, macros: .standard(timing)))
            }
        }
    }

    mutating func sortMeals() {
        meals.sort { $0.scheduledTime < $1.scheduledTime }
    }
}

// MARK: - Weekly plan
struct WeekPlan: Codable {
    var days: [DayPlan]

    static func makeDefault() -> WeekPlan {
        let days = (0..<7).map { offset -> DayPlan in
            let date = Calendar.current.date(byAdding: .day, value: offset - 3, to: .now) ?? .now
            return DayPlan(date: date)
        }
        return WeekPlan(days: days)
    }
}
