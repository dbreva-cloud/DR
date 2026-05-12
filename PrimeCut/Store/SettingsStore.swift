import SwiftUI
import Combine

final class SettingsStore: ObservableObject {
    // MARK: - Persisted settings
    @AppStorage("autoModeEnabled")    var autoModeEnabled: Bool   = true
    @AppStorage("notificationsOn")    var notificationsOn: Bool   = true
    @AppStorage("stepGoal")           var stepGoal: Double        = 8000
    @AppStorage("useMetric")          var useMetric: Bool         = false
    @AppStorage("accentIsGold")       var accentIsGold: Bool      = false
    @AppStorage("streakCount")        var streakCount: Int        = 0
    @AppStorage("lastCompletedDay")   var lastCompletedDayRaw: Double = 0
    @AppStorage("onboardingComplete") var onboardingComplete: Bool = false
    @AppStorage("userName")           var userName: String        = ""
    @AppStorage("primaryActivity")    var primaryActivity: String = "BJJ + Lifting"

    var lastCompletedDay: Date? {
        get { lastCompletedDayRaw == 0 ? nil : Date(timeIntervalSince1970: lastCompletedDayRaw) }
        set { lastCompletedDayRaw = newValue?.timeIntervalSince1970 ?? 0 }
    }

    var accentColor: Color     { accentIsGold ? Theme.gold   : Theme.accent }
    var accentGradient: LinearGradient { accentIsGold ? Theme.goldGradient : Theme.accentGradient }

    var displayName: String { userName.isEmpty ? "Athlete" : userName }

    // MARK: - Streak management
    func recordDayCompletion() {
        let today = Calendar.current.startOfDay(for: .now)
        if let last = lastCompletedDay {
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
            if Calendar.current.isDate(last, inSameDayAs: yesterday) {
                streakCount += 1
                HapticManager.streak()
            } else if !Calendar.current.isDate(last, inSameDayAs: today) {
                streakCount = 1
            }
        } else {
            streakCount = 1
        }
        lastCompletedDay = today
    }

    func resetStreak() {
        streakCount = 0
        lastCompletedDayRaw = 0
    }
}
