import Foundation

// Shared between the main app, widget, and watch — keep dependencies minimal
struct SharedAppSnapshot: Codable {
    var stepCount:      Double
    var stepGoal:       Double
    var streakCount:    Int
    var checklistItems: [ChecklistSnapshot]
    var updatedAt:      Date

    struct ChecklistSnapshot: Codable {
        var label:     String
        var isChecked: Bool
    }
}
