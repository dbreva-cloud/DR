import Foundation

// MARK: - Actual completed workout (vs planned)
struct WorkoutLog: Identifiable, Codable {
    var id        = UUID()
    var date:       Date
    var type:       WorkoutType
    var duration:   TimeInterval
    var completed:  Bool
    var notes:      String?
    var perceivedEffort: Int?   // RPE 1–10

    var durationString: String {
        let m = Int(duration / 60)
        return m < 60 ? "\(m)m" : "\(m / 60)h \(m % 60 > 0 ? "\(m % 60)m" : "")"
    }
}

// MARK: - History container
struct WorkoutHistory: Codable {
    var logs: [WorkoutLog]

    init(logs: [WorkoutLog] = []) { self.logs = logs }

    mutating func log(_ entry: WorkoutLog) {
        // Replace existing entry for same day if present
        if let idx = logs.firstIndex(where: {
            Calendar.current.isDate($0.date, inSameDayAs: entry.date)
        }) {
            logs[idx] = entry
        } else {
            logs.append(entry)
        }
        logs.sort { $0.date > $1.date }
    }

    func logsForCurrentWeek() -> [WorkoutLog] {
        let start = Calendar.current.date(
            byAdding: .day, value: -6,
            to: Calendar.current.startOfDay(for: .now)
        ) ?? .now
        return logs.filter { $0.date >= start }
    }

    var weeklyCompletionRate: Double {
        let week = logsForCurrentWeek()
        guard !week.isEmpty else { return 0 }
        return Double(week.filter(\.completed).count) / Double(week.count)
    }
}
