import Foundation

// MARK: - Meal timing category
enum MealTiming: String, Codable {
    case breakfast     = "Breakfast"
    case preWorkout    = "Pre-Workout"
    case postWorkout   = "Post-Workout"
    case lunch         = "Lunch"
    case dinner        = "Dinner"
    case snack         = "Snack"

    var icon: String {
        switch self {
        case .breakfast:  return "sunrise.fill"
        case .preWorkout: return "bolt.fill"
        case .postWorkout:return "flame.fill"
        case .lunch:      return "sun.max.fill"
        case .dinner:     return "moon.stars.fill"
        case .snack:      return "leaf.fill"
        }
    }

    var isWorkoutRelated: Bool {
        self == .preWorkout || self == .postWorkout
    }
}

// MARK: - Macros
struct Macros: Codable, Equatable {
    var protein: Double  // grams
    var carbs:   Double
    var fat:     Double

    var calories: Double { protein * 4 + carbs * 4 + fat * 9 }

    static let zero = Macros(protein: 0, carbs: 0, fat: 0)

    static func preWorkout(for type: WorkoutType) -> Macros {
        Macros(protein: type.baseProtein, carbs: type.preWorkoutCarbs, fat: 10)
    }

    static func postWorkout(for type: WorkoutType) -> Macros {
        Macros(protein: type.baseProtein + 5, carbs: type.postWorkoutCarbs, fat: 8)
    }

    static func standard(_ timing: MealTiming) -> Macros {
        switch timing {
        case .breakfast: return Macros(protein: 35, carbs: 40, fat: 15)
        case .lunch:     return Macros(protein: 40, carbs: 45, fat: 18)
        case .dinner:    return Macros(protein: 45, carbs: 35, fat: 20)
        case .snack:     return Macros(protein: 20, carbs: 15, fat: 8)
        default:         return Macros(protein: 35, carbs: 35, fat: 12)
        }
    }
}

// MARK: - Meal model
struct Meal: Identifiable, Codable, Equatable {
    var id = UUID()
    var timing: MealTiming
    var scheduledTime: Date
    var macros: Macros
    var isConsumed: Bool = false
    var linkedWorkoutID: UUID?

    var title: String { timing.rawValue }

    var macroSummary: String {
        "P:\(Int(macros.protein))g  C:\(Int(macros.carbs))g  F:\(Int(macros.fat))g"
    }
}
