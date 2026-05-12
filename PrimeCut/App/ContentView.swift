import SwiftUI

struct ContentView: View {
    @EnvironmentObject var settings: SettingsStore
    @State private var selectedTab: Tab = .dashboard

    enum Tab: Int {
        case dashboard = 0
        case planner   = 1
        case progress  = 2
        case settings  = 3
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: selectedTab == .dashboard ? "house.fill" : "house")
                }
                .tag(Tab.dashboard)

            PlannerView()
                .tabItem {
                    Label("Planner", systemImage: selectedTab == .planner ? "calendar.circle.fill" : "calendar.circle")
                }
                .tag(Tab.planner)

            PrimeCutProgressView()
                .tabItem {
                    Label("Progress", systemImage: selectedTab == .progress ? "chart.line.uptrend.xyaxis.circle.fill" : "chart.line.uptrend.xyaxis.circle")
                }
                .tag(Tab.progress)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: selectedTab == .settings ? "gearshape.fill" : "gearshape")
                }
                .tag(Tab.settings)
        }
        .accentColor(settings.accentColor)
        .onAppear {
            // Custom tab bar styling
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Theme.surface)
            appearance.shadowColor = UIColor(Theme.separator)

            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SettingsStore())
        .environmentObject(PlannerStore())
        .environmentObject(HealthKitManager())
}
