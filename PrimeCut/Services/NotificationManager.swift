import UserNotifications
import Foundation

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    // MARK: - Schedule meal reminders from a DayPlan
    func scheduleMealReminders(for plan: DayPlan) {
        cancelAllPending()

        for meal in plan.meals where !meal.isConsumed {
            scheduleReminder(
                id: "meal_\(meal.id.uuidString)",
                title: mealTitle(for: meal.timing),
                body: mealBody(for: meal),
                date: meal.scheduledTime.adding(minutes: -10)
            )
        }
    }

    // MARK: - Missed meal nudge (30 min after scheduled time)
    func scheduleMissedMealNudge(for meal: Meal) {
        scheduleReminder(
            id: "missed_\(meal.id.uuidString)",
            title: "Don't skip \(meal.timing.rawValue)",
            body: "Your \(meal.timing.rawValue.lowercased()) window is closing. Eat now.",
            date: meal.scheduledTime.adding(minutes: 30)
        )
    }

    func cancelAllPending() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Private
    private func scheduleReminder(id: String, title: String, body: String, date: Date) {
        guard date > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body  = body
        content.sound = .default

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func mealTitle(for timing: MealTiming) -> String {
        switch timing {
        case .preWorkout:  return "Pre-Workout Fuel"
        case .postWorkout: return "Post-Workout Recovery"
        case .breakfast:   return "Breakfast Time"
        case .lunch:       return "Lunch Time"
        case .dinner:      return "Dinner Time"
        case .snack:       return "Snack Reminder"
        }
    }

    private func mealBody(for meal: Meal) -> String {
        "P:\(Int(meal.macros.protein))g · C:\(Int(meal.macros.carbs))g · F:\(Int(meal.macros.fat))g"
    }
}
