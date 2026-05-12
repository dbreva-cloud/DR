import WidgetKit
import SwiftUI

// MARK: - Timeline entry
struct PrimeCutEntry: TimelineEntry {
    let date: Date
    let snapshot: SharedAppSnapshot
    let isPlaceholder: Bool

    static func placeholder() -> PrimeCutEntry {
        PrimeCutEntry(date: .now, snapshot: SharedDataManager.placeholder(), isPlaceholder: true)
    }
}

// MARK: - Provider
struct PrimeCutProvider: TimelineProvider {
    typealias Entry = PrimeCutEntry

    func placeholder(in context: Context) -> PrimeCutEntry {
        .placeholder()
    }

    func getSnapshot(in context: Context, completion: @escaping (PrimeCutEntry) -> Void) {
        let snap = SharedDataManager.readSnapshot() ?? SharedDataManager.placeholder()
        completion(PrimeCutEntry(date: .now, snapshot: snap, isPlaceholder: false))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrimeCutEntry>) -> Void) {
        let snap = SharedDataManager.readSnapshot() ?? SharedDataManager.placeholder()
        let entry = PrimeCutEntry(date: .now, snapshot: snap, isPlaceholder: false)

        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}
