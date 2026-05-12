import Foundation
import WidgetKit

// Lightweight shared reader — no SwiftUI, no HealthKit, usable by widget + watch
struct SharedDataManager {
    static let appGroupID = "group.com.primecut.app"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    // MARK: - Keys
    private enum Key {
        static let snapshot = "sharedSnapshot"
    }

    // MARK: - Write (called from main app)
    static func write(snapshot: SharedAppSnapshot) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(snapshot) {
            defaults.set(data, forKey: Key.snapshot)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    // MARK: - Read (called from widget / watch)
    static func readSnapshot() -> SharedAppSnapshot? {
        guard let data = defaults.data(forKey: Key.snapshot) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(SharedAppSnapshot.self, from: data)
    }

    // MARK: - Fallback placeholder
    static func placeholder() -> SharedAppSnapshot {
        SharedAppSnapshot(
            stepCount: 5420,
            stepGoal: 8000,
            streakCount: 4,
            checklistItems: [
                .init(label: "Breakfast", isChecked: true),
                .init(label: "Lunch",     isChecked: false),
                .init(label: "Dinner",    isChecked: false),
                .init(label: "Workout",   isChecked: true),
                .init(label: "Step Goal", isChecked: false),
            ],
            updatedAt: .now
        )
    }
}
