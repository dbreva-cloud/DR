import Foundation

// MARK: - Auto Mode output
struct AutoModeRecommendation {
    var carbAdjustment: CarbAdjustment
    var workoutSuggestion: WorkoutSuggestion
    var note: String
}

enum CarbAdjustment: String {
    case increase = "Increase Carbs"
    case maintain = "Maintain"
    case reduce   = "Reduce Carbs"

    var multiplier: Double {
        switch self {
        case .increase: return 1.15
        case .maintain: return 1.0
        case .reduce:   return 0.85
        }
    }

    var icon: String {
        switch self {
        case .increase: return "arrow.up.circle.fill"
        case .maintain: return "minus.circle.fill"
        case .reduce:   return "arrow.down.circle.fill"
        }
    }
}

// MARK: - Auto Mode Engine
struct AutoModeEngine {

    // Core decision function
    static func recommend(
        steps: Double,
        stepGoal: Double,
        workout: Workout?,
        recovery: RecoveryInput
    ) -> AutoModeRecommendation {

        let stepRatio      = steps / max(stepGoal, 1)
        let recoveryScore  = recovery.recoveryScore
        let workoutType    = workout?.type

        // Recovery-based suggestion
        let workoutSuggestion = recovery.workoutSuggestion

        // Carb adjustment logic
        let carbAdjustment: CarbAdjustment
        var notes: [String] = []

        switch workoutType {
        case .bjj:
            carbAdjustment = .increase
            notes.append("BJJ session → carbs elevated for glycolytic demand.")
        case .strength:
            carbAdjustment = recoveryScore > 60 ? .maintain : .reduce
            notes.append("Strength session → balanced macros.")
        case .rest, .none:
            if stepRatio < 0.5 {
                carbAdjustment = .reduce
                notes.append("Low steps + rest day → reduce carbs to match output.")
            } else {
                carbAdjustment = .maintain
                notes.append("Rest day with good movement → maintain carbs.")
            }
        }

        // Override: poor recovery always pulls carbs down
        if recoveryScore < 35 {
            notes.append("Poor recovery detected → carbs reduced to aid repair.")
        }

        // Override: very high step count bumps carbs
        if stepRatio > 1.3 && carbAdjustment != .increase {
            notes.append("High step output → slight carb increase.")
        }

        return AutoModeRecommendation(
            carbAdjustment: carbAdjustment,
            workoutSuggestion: workoutSuggestion,
            note: notes.joined(separator: " ")
        )
    }

    // Apply carb adjustment to a set of meals
    static func adjustMeals(_ meals: [Meal], adjustment: CarbAdjustment) -> [Meal] {
        meals.map { meal in
            var m = meal
            m.macros.carbs *= adjustment.multiplier
            return m
        }
    }
}
