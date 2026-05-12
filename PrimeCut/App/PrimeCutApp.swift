import SwiftUI

@main
struct PrimeCutApp: App {
    @StateObject private var healthKit   = HealthKitManager()
    @StateObject private var plannerStore = PlannerStore()
    @StateObject private var settingsStore = SettingsStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(healthKit)
                .environmentObject(plannerStore)
                .environmentObject(settingsStore)
                .preferredColorScheme(.dark)
        }
    }
}
