import HealthKit
import Combine
import SwiftUI

@MainActor
final class HealthKitManager: ObservableObject {
    private let store = HKHealthStore()

    @Published var stepCount: Double = 0
    @Published var isAuthorized: Bool = false
    @Published var authorizationStatus: AuthStatus = .notDetermined

    enum AuthStatus {
        case notDetermined, authorized, denied, unavailable
    }

    private let stepType = HKQuantityType(.stepCount)

    // MARK: - Authorization
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationStatus = .unavailable
            return
        }

        do {
            try await store.requestAuthorization(
                toShare: [],
                read: [stepType]
            )
            isAuthorized = true
            authorizationStatus = .authorized
            await fetchTodaySteps()
        } catch {
            authorizationStatus = .denied
        }
    }

    // MARK: - Step fetching
    func fetchTodaySteps() async {
        guard isAuthorized else { return }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: now,
            options: .strictStartDate
        )

        await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { [weak self] _, result, _ in
                Task { @MainActor in
                    self?.stepCount = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                    continuation.resume()
                }
            }
            store.execute(query)
        }
    }

    // MARK: - Historical steps (last 7 days)
    func fetchWeeklySteps() async -> [Date: Double] {
        guard isAuthorized else { return [:] }

        var result: [Date: Double] = [:]
        let calendar = Calendar.current

        await withCheckedContinuation { continuation in
            let anchorDate = calendar.startOfDay(for: Date())
            let interval = DateComponents(day: 1)
            let startDate = calendar.date(byAdding: .day, value: -6, to: anchorDate) ?? anchorDate

            let query = HKStatisticsCollectionQuery(
                quantityType: stepType,
                quantitySamplePredicate: nil,
                options: .cumulativeSum,
                anchorDate: anchorDate,
                intervalComponents: interval
            )
            query.initialResultsHandler = { _, statsCollection, _ in
                statsCollection?.enumerateStatistics(from: startDate, to: Date()) { stats, _ in
                    result[stats.startDate] = stats.sumQuantity()?.doubleValue(for: .count()) ?? 0
                }
                Task { @MainActor in
                    continuation.resume()
                }
            }
            self.store.execute(query)
        }
        return result
    }

    // MARK: - Observe live step updates
    func startObservingSteps() {
        guard isAuthorized else { return }

        let query = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] _, _, _ in
            Task { await self?.fetchTodaySteps() }
        }
        store.execute(query)
        store.enableBackgroundDelivery(for: stepType, frequency: .immediate) { _, _ in }
    }
}
