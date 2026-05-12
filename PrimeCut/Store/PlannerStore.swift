import SwiftUI
import Combine

@MainActor
final class PlannerStore: ObservableObject {
    @Published var todayPlan:          DayPlan
    @Published var weekPlans:          [DayPlan] = []
    @Published var autoRecommendation: AutoModeRecommendation?
    @Published var progressData:       ProgressData
    @Published var recovery:           RecoveryInput
    @Published var workoutHistory:     WorkoutHistory
    @Published var groceryList:        GroceryList?

    private let persistence = PersistenceManager.shared

    init() {
        todayPlan      = DayPlan(date: .now)
        progressData   = PersistenceManager.shared.load(ProgressData.self,  key: .progressData)   ?? ProgressData.sample()
        recovery       = PersistenceManager.shared.load(RecoveryInput.self, key: .recovery)       ?? RecoveryInput()
        workoutHistory = PersistenceManager.shared.load(WorkoutHistory.self, key: .workoutHistory) ?? WorkoutHistory()

        loadWeekPlans()
        if weekPlans.isEmpty { seedWeek() }
        syncTodayPlan()
        todayPlan.ensureBaseMeals()
    }

    // MARK: - Workout planning
    func addOrUpdateWorkout(_ workout: Workout) {
        todayPlan.workout = workout
        todayPlan.generateMeals(from: workout)
        todayPlan.ensureBaseMeals()
        syncTodayToWeek()
        saveAll()
        NotificationManager.shared.scheduleMealReminders(for: todayPlan)
    }

    func removeWorkout() {
        todayPlan.workout = nil
        todayPlan.meals.removeAll { $0.timing.isWorkoutRelated }
        syncTodayToWeek()
        saveAll()
    }

    // MARK: - Workout history
    func logWorkout(_ log: WorkoutLog) {
        workoutHistory.log(log)
        // Auto-check "Workout" checklist item if completed
        if log.completed, let idx = todayPlan.checklist.firstIndex(where: { $0.label == "Workout" }),
           !todayPlan.checklist[idx].isChecked {
            todayPlan.checklist[idx].isChecked = true
        }
        syncTodayToWeek()
        persistence.save(workoutHistory, key: .workoutHistory)
    }

    // MARK: - Checklist
    func toggleChecklist(id: UUID) {
        guard let idx = todayPlan.checklist.firstIndex(where: { $0.id == id }) else { return }
        withAnimation(.springSnappy) {
            todayPlan.checklist[idx].isChecked.toggle()
        }
        HapticManager.checkmark()
        syncTodayToWeek()
        saveAll()
        pushSharedSnapshot()
    }

    // MARK: - Meal consumed
    func markMealConsumed(id: UUID) {
        guard let idx = todayPlan.meals.firstIndex(where: { $0.id == id }) else { return }
        todayPlan.meals[idx].isConsumed = true
        syncTodayToWeek()
        saveAll()
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
        persistence.save(recovery, key: .recovery)
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
            if progressData.entries.count > 90 {
                progressData.entries.removeFirst(progressData.entries.count - 90)
            }
        } else if let idx = progressData.entries.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: entry.date) }) {
            progressData.entries[idx] = entry
        }
        persistence.save(progressData, key: .progressData)
    }

    // MARK: - Shared snapshot (widget + watch)
    func pushSharedSnapshot(steps: Double? = nil, settings: SettingsStore? = nil) {
        let snap = SharedAppSnapshot(
            stepCount: steps ?? todayPlan.steps,
            stepGoal: settings?.stepGoal ?? 8000,
            streakCount: settings?.streakCount ?? 0,
            checklistItems: todayPlan.checklist.map {
                SharedAppSnapshot.ChecklistSnapshot(label: $0.label, isChecked: $0.isChecked)
            },
            updatedAt: .now
        )
        SharedDataManager.write(snapshot: snap)
    }

    // MARK: - Persistence
    func saveAll() {
        persistence.save(weekPlans, key: .weekPlans)
    }

    private func loadWeekPlans() {
        weekPlans = persistence.load([DayPlan].self, key: .weekPlans) ?? []
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

// Expose workout history computed props at store level for convenience
extension PlannerStore {
    func logsForCurrentWeek() -> [WorkoutLog] {
        workoutHistory.logsForCurrentWeek()
    }
}
