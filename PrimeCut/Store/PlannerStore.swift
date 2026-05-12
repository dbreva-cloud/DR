import SwiftUI
import Combine

@MainActor
final class PlannerStore: ObservableObject {
    @Published var todayPlan: DayPlan
    @Published var weekPlans: [DayPlan] = []
    @Published var autoRecommendation: AutoModeRecommendation?
    @Published var progressData: ProgressData = .sample()
    @Published var recovery: RecoveryInput = RecoveryInput()
    @Published var groceryList: GroceryList?

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let storageKey = "primeCut_weekPlans"

    init() {
        todayPlan = DayPlan(date: .now)
        loadFromStorage()
        if weekPlans.isEmpty {
            seedWeek()
        }
        syncTodayPlan()
    }

    // MARK: - Workout management
    func addOrUpdateWorkout(_ workout: Workout) {
        todayPlan.workout = workout
        todayPlan.generateMeals(from: workout)
        todayPlan.ensureBaseMeals()
        syncTodayToWeek()
        save()
        NotificationManager.shared.scheduleMealReminders(for: todayPlan)
    }

    func removeWorkout() {
        todayPlan.workout = nil
        todayPlan.meals.removeAll { $0.timing.isWorkoutRelated }
        syncTodayToWeek()
        save()
    }

    // MARK: - Checklist
    func toggleChecklist(id: UUID) {
        guard let idx = todayPlan.checklist.firstIndex(where: { $0.id == id }) else { return }
        withAnimation(.springSnappy) {
            todayPlan.checklist[idx].isChecked.toggle()
        }
        HapticManager.checkmark()
        syncTodayToWeek()
        save()
    }

    // MARK: - Meal consumed
    func markMealConsumed(id: UUID) {
        guard let idx = todayPlan.meals.firstIndex(where: { $0.id == id }) else { return }
        todayPlan.meals[idx].isConsumed = true
        syncTodayToWeek()
        save()
    }

    // MARK: - Auto mode
    func runAutoMode(steps: Double, settings: SettingsStore) {
        guard settings.autoModeEnabled else { return }
        let rec = AutoModeEngine.recommend(
            steps: steps,
            stepGoal: settings.stepGoal,
            workout: todayPlan.workout,
            recovery: recovery
        )
        autoRecommendation = rec
        todayPlan.meals = AutoModeEngine.adjustMeals(todayPlan.meals, adjustment: rec.carbAdjustment)
        syncTodayToWeek()
    }

    // MARK: - Grocery list
    func generateGroceryList() {
        groceryList = GroceryExporter.generate(from: weekPlans)
    }

    // MARK: - Recovery
    func updateRecovery(_ input: RecoveryInput) {
        recovery = input
    }

    // MARK: - Progress data
    func appendTodayToProgress() {
        let entry = ProgressEntry(
            date: todayPlan.date,
            adherencePercent: Double(todayPlan.checklist.filter(\.isChecked).count) /
                              Double(max(todayPlan.checklist.count, 1)),
            steps: todayPlan.steps,
            workoutCompleted: todayPlan.checklist.first(where: { $0.label == "Workout" })?.isChecked ?? false,
            recoveryScore: recovery.recoveryScore
        )
        if !progressData.entries.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: entry.date) }) {
            progressData.entries.append(entry)
            if progressData.entries.count > 30 {
                progressData.entries.removeFirst()
            }
        }
    }

    // MARK: - Persistence
    func save() {
        if let data = try? encoder.encode(weekPlans) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadFromStorage() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let plans = try? decoder.decode([DayPlan].self, from: data) else { return }
        weekPlans = plans
    }

    private func syncTodayPlan() {
        let today = Calendar.current.startOfDay(for: .now)
        if let idx = weekPlans.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            todayPlan = weekPlans[idx]
        } else {
            weekPlans.append(todayPlan)
        }
    }

    private func syncTodayToWeek() {
        let today = Calendar.current.startOfDay(for: .now)
        if let idx = weekPlans.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            weekPlans[idx] = todayPlan
        }
    }

    private func seedWeek() {
        weekPlans = (0..<7).map { offset -> DayPlan in
            let date = Calendar.current.date(byAdding: .day, value: offset - 3, to: .now) ?? .now
            var plan = DayPlan(date: date)
            plan.ensureBaseMeals()
            return plan
        }
    }
}
