import SwiftUI
import WatchKit

@main
struct PrimeCutWatchApp: App {
    @StateObject private var watchStore = WatchStore()

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(watchStore)
        }
    }
}

// MARK: - Watch root view
struct WatchContentView: View {
    @EnvironmentObject var store: WatchStore
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            WatchDashboardView()
                .tag(0)
            WatchChecklistView()
                .tag(1)
        }
        .tabViewStyle(.page)
        .onAppear { store.refresh() }
    }
}

// MARK: - Watch store (reads from shared App Group)
@MainActor
final class WatchStore: ObservableObject {
    @Published var snapshot: SharedAppSnapshot = SharedDataManager.placeholder()

    func refresh() {
        if let live = SharedDataManager.readSnapshot() {
            snapshot = live
        }
    }
}
