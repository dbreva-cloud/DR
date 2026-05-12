import Foundation

// MARK: - Typed file-based persistence replacing raw UserDefaults JSON
final class PersistenceManager {
    static let shared = PersistenceManager()

    // Use App Group so widget + watch can share data
    private let appGroupID = "group.com.primecut.app"
    private var containerURL: URL {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = .prettyPrinted
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private init() {}

    // MARK: - Generic save / load
    func save<T: Encodable>(_ value: T, key: StorageKey) {
        do {
            let data = try encoder.encode(value)
            try data.write(to: url(for: key), options: .atomic)
        } catch {
            print("[PersistenceManager] save failed for \(key.rawValue): \(error)")
        }
    }

    func load<T: Decodable>(_ type: T.Type, key: StorageKey) -> T? {
        let fileURL = url(for: key)
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? decoder.decode(type, from: data)
    }

    func delete(key: StorageKey) {
        try? FileManager.default.removeItem(at: url(for: key))
    }

    // MARK: - Shared UserDefaults (for widget/watch lightweight reads)
    var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    func writeShared<T: Encodable>(_ value: T, key: String) {
        if let data = try? encoder.encode(value) {
            sharedDefaults.set(data, forKey: key)
        }
    }

    func readShared<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = sharedDefaults.data(forKey: key) else { return nil }
        return try? decoder.decode(type, from: data)
    }

    // MARK: - Private
    private func url(for key: StorageKey) -> URL {
        containerURL.appendingPathComponent("\(key.rawValue).json")
    }
}

// MARK: - Storage keys
enum StorageKey: String {
    case weekPlans      = "weekPlans"
    case progressData   = "progressData"
    case workoutHistory = "workoutHistory"
    case recovery       = "recovery"
}

// SharedAppSnapshot lives in Models/SharedAppSnapshot.swift
