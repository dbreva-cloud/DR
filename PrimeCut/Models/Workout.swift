import SwiftUI
import Foundation

// MARK: - Workout type
enum WorkoutType: String, CaseIterable, Codable, Identifiable {
    case bjj      = "BJJ"
    case strength = "Strength"
    case rest     = "Rest"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .bjj:      return "figure.martial.arts"
        case .strength: return "dumbbell.fill"
        case .rest:     return "moon.fill"
        }
    }

    var color: Color {
        switch self {
        case .bjj:      return Theme.bjjColor
        case .strength: return Theme.strengthColor
        case .rest:     return Theme.restColor
        }
    }

    var carbMultiplier: Double {
        switch self {
        case .bjj:      return 1.25
        case .strength: return 1.0
        case .rest:     return 0.80
        }
    }

    // Carbs in grams for pre/post meals
    var preWorkoutCarbs: Double {
        switch self {
        case .bjj:      return 50
        case .strength: return 40
        case .rest:     return 0
        }
    }

    var postWorkoutCarbs: Double {
        switch self {
        case .bjj:      return 60
        case .strength: return 50
        case .rest:     return 0
        }
    }

    var baseProtein: Double { 40 }

    var label: String {
        switch self {
        case .bjj:      return "Brazilian Jiu-Jitsu"
        case .strength: return "Strength Training"
        case .rest:     return "Rest Day"
        }
    }
}

// MARK: - Workout model
struct Workout: Identifiable, Codable, Equatable {
    var id = UUID()
    var type: WorkoutType
    var startTime: Date
    var duration: TimeInterval  // seconds

    var endTime: Date { startTime.addingTimeInterval(duration) }

    var preWorkoutMealTime: Date {
        startTime.adding(minutes: -75)
    }

    var postWorkoutMealTime: Date {
        startTime.addingTimeInterval(duration).adding(minutes: 30)
    }

    var durationString: String {
        let minutes = Int(duration / 60)
        if minutes < 60 { return "\(minutes)m" }
        let h = minutes / 60
        let m = minutes % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }

    // Default 60-min workouts
    init(type: WorkoutType, startTime: Date, duration: TimeInterval = 3600) {
        self.type = type
        self.startTime = startTime
        self.duration = duration
    }
}
