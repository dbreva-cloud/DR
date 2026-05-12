import Foundation

struct ProgressEntry: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var adherencePercent: Double  // 0–1
    var steps: Double
    var workoutCompleted: Bool
    var recoveryScore: Int

    var weekday: String { date.weekdayShort }
}

struct ProgressData: Codable {
    var entries: [ProgressEntry]

    var weekAdherence: Double {
        guard !entries.isEmpty else { return 0 }
        return entries.map(\.adherencePercent).reduce(0, +) / Double(entries.count)
    }

    var workoutConsistency: Double {
        guard !entries.isEmpty else { return 0 }
        let completed = entries.filter(\.workoutCompleted).count
        return Double(completed) / Double(entries.count)
    }

    var averageRecovery: Double {
        guard !entries.isEmpty else { return 0 }
        return Double(entries.map(\.recoveryScore).reduce(0, +)) / Double(entries.count)
    }

    // Sample data for preview / first-launch
    static func sample() -> ProgressData {
        let base = Date()
        let entries = (0..<7).map { i -> ProgressEntry in
            let date = Calendar.current.date(byAdding: .day, value: i - 6, to: base) ?? base
            return ProgressEntry(
                date: date,
                adherencePercent: Double.random(in: 0.6...1.0),
                steps: Double.random(in: 4000...12000),
                workoutCompleted: Bool.random(),
                recoveryScore: Int.random(in: 45...95)
            )
        }
        return ProgressData(entries: entries)
    }
}
