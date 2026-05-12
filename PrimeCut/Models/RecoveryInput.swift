import Foundation

struct RecoveryInput: Codable, Equatable {
    var sleepQuality: Int   // 1–5
    var stressLevel: Int    // 1–5
    var date: Date

    // Composite score 0–100 (higher = better recovery)
    var recoveryScore: Int {
        let sleep  = Double(sleepQuality) / 5.0
        let stress = 1.0 - Double(stressLevel) / 5.0
        return Int((sleep * 0.6 + stress * 0.4) * 100)
    }

    var recoveryLabel: String {
        switch recoveryScore {
        case 80...100: return "Optimal"
        case 60...79:  return "Good"
        case 40...59:  return "Moderate"
        case 20...39:  return "Low"
        default:       return "Poor"
        }
    }

    var workoutSuggestion: WorkoutSuggestion {
        switch recoveryScore {
        case 75...100: return .trainHard
        case 50...74:  return .trainModerate
        case 25...49:  return .lightSession
        default:       return .restDay
        }
    }

    init(sleepQuality: Int = 3, stressLevel: Int = 2, date: Date = .now) {
        self.sleepQuality = sleepQuality
        self.stressLevel  = stressLevel
        self.date         = date
    }
}

enum WorkoutSuggestion: String {
    case trainHard     = "Train Hard"
    case trainModerate = "Train Moderate"
    case lightSession  = "Light Session"
    case restDay       = "Rest Day"

    var detail: String {
        switch self {
        case .trainHard:     return "Recovery is optimal — push it today."
        case .trainModerate: return "Good to train, moderate intensity."
        case .lightSession:  return "Low intensity only — prioritize recovery."
        case .restDay:       return "Take the day off. Sleep and eat well."
        }
    }

    var icon: String {
        switch self {
        case .trainHard:     return "bolt.fill"
        case .trainModerate: return "figure.strengthtraining.traditional"
        case .lightSession:  return "figure.walk"
        case .restDay:       return "moon.fill"
        }
    }
}
