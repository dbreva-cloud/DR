import CloudKit
import SwiftUI
import Combine

// MARK: - CloudKit sync manager
@MainActor
final class CloudKitManager: ObservableObject {
    static let shared = CloudKitManager()

    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncDate: Date?
    @Published var iCloudAvailable: Bool = false

    private let container = CKContainer(identifier: "iCloud.com.primecut.app")
    private var privateDB: CKDatabase { container.privateCloudDatabase }

    enum SyncStatus: Equatable {
        case idle
        case syncing
        case success
        case error(String)
    }

    private init() {
        Task { await checkiCloudStatus() }
    }

    // MARK: - Status check
    func checkiCloudStatus() async {
        do {
            let status = try await container.accountStatus()
            iCloudAvailable = (status == .available)
        } catch {
            iCloudAvailable = false
        }
    }

    // MARK: - Save week plans
    func saveWeekPlans(_ plans: [DayPlan]) async {
        guard iCloudAvailable else { return }
        syncStatus = .syncing

        do {
            let record = try makePlanRecord(plans: plans)
            _ = try await privateDB.save(record)
            syncStatus = .success
            lastSyncDate = .now
        } catch {
            syncStatus = .error(error.localizedDescription)
        }
    }

    // MARK: - Fetch week plans
    func fetchWeekPlans() async -> [DayPlan]? {
        guard iCloudAvailable else { return nil }
        syncStatus = .syncing

        do {
            let pred = NSPredicate(value: true)
            let query = CKQuery(recordType: "WeekPlan", predicate: pred)
            let result = try await privateDB.records(matching: query,
                                                      inZoneWith: nil,
                                                      desiredKeys: nil,
                                                      resultsLimit: 1)
            guard let record = try result.matchResults.first?.1.get() else {
                syncStatus = .idle
                return nil
            }
            let plans = try decodePlans(from: record)
            syncStatus = .success
            lastSyncDate = .now
            return plans
        } catch {
            syncStatus = .error(error.localizedDescription)
            return nil
        }
    }

    // MARK: - Save progress data
    func saveProgressData(_ data: ProgressData) async {
        guard iCloudAvailable else { return }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(data)
            let record = CKRecord(recordType: "ProgressData")
            record["json"] = jsonData as CKRecordValue
            record["updatedAt"] = Date() as CKRecordValue
            _ = try await privateDB.save(record)
        } catch {
            print("[CloudKit] saveProgressData error: \(error)")
        }
    }

    // MARK: - Encoding helpers
    private func makePlanRecord(plans: [DayPlan]) throws -> CKRecord {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(plans)
        let record = CKRecord(recordType: "WeekPlan")
        record["plansJSON"] = data as CKRecordValue
        record["updatedAt"] = Date() as CKRecordValue
        return record
    }

    private func decodePlans(from record: CKRecord) throws -> [DayPlan] {
        guard let data = record["plansJSON"] as? Data else {
            throw CKError(.invalidArguments)
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([DayPlan].self, from: data)
    }

    // MARK: - Subscribe to remote changes
    func subscribeToChanges() async {
        guard iCloudAvailable else { return }
        let subscription = CKQuerySubscription(
            recordType: "WeekPlan",
            predicate: NSPredicate(value: true),
            options: [.firesOnRecordCreation, .firesOnRecordUpdate]
        )
        let notification = CKSubscription.NotificationInfo()
        notification.shouldSendContentAvailable = true
        subscription.notificationInfo = notification

        do {
            _ = try await privateDB.save(subscription)
        } catch {
            // Subscription may already exist — safe to ignore duplicate error
            print("[CloudKit] subscribeToChanges: \(error)")
        }
    }
}

// MARK: - Sync status view
struct CloudSyncStatusView: View {
    @ObservedObject var cloudKit = CloudKitManager.shared

    var body: some View {
        HStack(spacing: 8) {
            statusIcon
            VStack(alignment: .leading, spacing: 1) {
                Text(statusText)
                    .font(.labelLarge)
                    .foregroundStyle(Theme.textPrimary)
                if let date = cloudKit.lastSyncDate {
                    Text("Last sync: \(date, style: .relative) ago")
                        .font(.caption)
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            Spacer()
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch cloudKit.syncStatus {
        case .idle:
            Image(systemName: "icloud.fill").foregroundStyle(Theme.textTertiary)
        case .syncing:
            ProgressView().tint(Theme.accent).scaleEffect(0.75)
        case .success:
            Image(systemName: "icloud.and.arrow.up.fill").foregroundStyle(Theme.accent)
        case .error:
            Image(systemName: "icloud.slash.fill").foregroundStyle(Theme.danger)
        }
    }

    private var statusText: String {
        switch cloudKit.syncStatus {
        case .idle:          return cloudKit.iCloudAvailable ? "iCloud Ready" : "iCloud Unavailable"
        case .syncing:       return "Syncing…"
        case .success:       return "Synced"
        case .error(let m):  return "Sync Error: \(m)"
        }
    }
}
