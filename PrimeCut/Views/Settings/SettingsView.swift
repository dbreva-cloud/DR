import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var healthKit: HealthKitManager
    @EnvironmentObject var store: PlannerStore

    @State private var showStreakResetAlert = false
    @State private var notificationsGranted = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                List {
                    // Health
                    healthSection

                    // Auto Mode
                    autoModeSection

                    // Goals
                    goalsSection

                    // Notifications
                    notificationsSection

                    // Appearance
                    appearanceSection

                    // Data
                    dataSection

                    // App info
                    infoSection
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { navBar }
            .alert("Reset Streak?", isPresented: $showStreakResetAlert) {
                Button("Reset", role: .destructive) { settings.resetStreak() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your \(settings.streakCount)-day streak will be cleared.")
            }
            .task {
                let granted = await NotificationManager.shared.requestAuthorization()
                notificationsGranted = granted
            }
        }
    }

    // MARK: - Health section
    private var healthSection: some View {
        Section {
            HStack {
                settingsIcon("heart.fill", color: .red)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Apple Health")
                        .foregroundStyle(Theme.textPrimary)
                    Text(healthStatusLabel)
                        .font(.caption)
                        .foregroundStyle(healthStatusColor)
                }
                Spacer()
                if healthKit.authorizationStatus != .authorized {
                    Button("Connect") {
                        Task { await healthKit.requestAuthorization() }
                    }
                    .font(.labelLarge)
                    .foregroundStyle(settings.accentColor)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(settings.accentColor)
                }
            }
        } header: {
            sectionHeader("Health")
        }
        .listRowBackground(Theme.surface)
    }

    // MARK: - Auto mode
    private var autoModeSection: some View {
        Section {
            Toggle(isOn: $settings.autoModeEnabled) {
                HStack {
                    settingsIcon("bolt.fill", color: settings.accentColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auto Mode")
                            .foregroundStyle(Theme.textPrimary)
                        Text("Adapts meals to steps, workout, and recovery")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .tint(settings.accentColor)

            if settings.autoModeEnabled, let rec = store.autoRecommendation {
                HStack {
                    settingsIcon(rec.carbAdjustment.icon, color: settings.accentColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Today's Adjustment")
                            .foregroundStyle(Theme.textPrimary)
                        Text(rec.note)
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(2)
                    }
                }
            }
        } header: {
            sectionHeader("Automation")
        }
        .listRowBackground(Theme.surface)
    }

    // MARK: - Goals
    private var goalsSection: some View {
        Section {
            HStack {
                settingsIcon("figure.walk", color: .orange)
                Text("Daily Step Goal")
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Picker("", selection: $settings.stepGoal) {
                    ForEach([5000, 6000, 7000, 8000, 10000, 12000, 15000], id: \.self) { goal in
                        Text(Double(goal).stepString)
                            .tag(Double(goal))
                    }
                }
                .tint(settings.accentColor)
            }
        } header: {
            sectionHeader("Goals")
        }
        .listRowBackground(Theme.surface)
    }

    // MARK: - Notifications
    private var notificationsSection: some View {
        Section {
            Toggle(isOn: $settings.notificationsOn) {
                HStack {
                    settingsIcon("bell.fill", color: .yellow)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Meal Reminders")
                            .foregroundStyle(Theme.textPrimary)
                        Text("Pre/post workout fuel alerts")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .tint(settings.accentColor)
            .onChange(of: settings.notificationsOn) { _, isOn in
                if isOn {
                    NotificationManager.shared.scheduleMealReminders(for: store.todayPlan)
                } else {
                    NotificationManager.shared.cancelAllPending()
                }
            }
        } header: {
            sectionHeader("Notifications")
        }
        .listRowBackground(Theme.surface)
    }

    // MARK: - Appearance
    private var appearanceSection: some View {
        Section {
            HStack {
                settingsIcon("paintpalette.fill", color: settings.accentColor)
                Text("Accent Color")
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                HStack(spacing: 10) {
                    colorDot(color: Theme.accent, label: "Green", isSelected: !settings.accentIsGold) {
                        withAnimation(.springSnappy) { settings.accentIsGold = false }
                        HapticManager.selection()
                    }
                    colorDot(color: Theme.gold, label: "Gold", isSelected: settings.accentIsGold) {
                        withAnimation(.springSnappy) { settings.accentIsGold = true }
                        HapticManager.selection()
                    }
                }
            }

            Toggle(isOn: $settings.useMetric) {
                HStack {
                    settingsIcon("ruler.fill", color: .blue)
                    Text("Use Metric Units")
                        .foregroundStyle(Theme.textPrimary)
                }
            }
            .tint(settings.accentColor)
        } header: {
            sectionHeader("Appearance")
        }
        .listRowBackground(Theme.surface)
    }

    // MARK: - Data
    private var dataSection: some View {
        Section {
            Button {
                store.generateGroceryList()
            } label: {
                HStack {
                    settingsIcon("cart.fill", color: settings.accentColor)
                    Text("Generate Grocery List")
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textTertiary)
                }
            }

            Button {
                store.appendTodayToProgress()
                HapticManager.notification(.success)
            } label: {
                HStack {
                    settingsIcon("chart.line.uptrend.xyaxis", color: settings.accentColor)
                    Text("Save Today to Progress")
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                }
            }

            Button(role: .destructive) {
                showStreakResetAlert = true
            } label: {
                HStack {
                    settingsIcon("flame.slash.fill", color: Theme.danger)
                    Text("Reset Streak")
                        .foregroundStyle(Theme.danger)
                    Spacer()
                }
            }
        } header: {
            sectionHeader("Data")
        }
        .listRowBackground(Theme.surface)
    }

    // MARK: - Info
    private var infoSection: some View {
        Section {
            HStack {
                settingsIcon("info.circle.fill", color: Theme.textTertiary)
                Text("Prime Cut")
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("v1.0")
                    .font(.bodyMedium)
                    .foregroundStyle(Theme.textTertiary)
            }
        } header: {
            sectionHeader("About")
        }
        .listRowBackground(Theme.surface)
    }

    // MARK: - Nav bar
    private var navBar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Text("Settings")
                .font(.titleLarge)
                .foregroundStyle(Theme.textPrimary)
        }
    }

    // MARK: - Helpers
    private var healthStatusLabel: String {
        switch healthKit.authorizationStatus {
        case .authorized:      return "Connected · \(Int(healthKit.stepCount).formatted()) steps today"
        case .denied:          return "Access denied in Settings"
        case .unavailable:     return "Not available on this device"
        case .notDetermined:   return "Tap Connect to enable"
        }
    }

    private var healthStatusColor: Color {
        healthKit.authorizationStatus == .authorized ? settings.accentColor : Theme.textTertiary
    }

    @ViewBuilder
    private func settingsIcon(_ name: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.15))
                .frame(width: 32, height: 32)
            Image(systemName: name)
                .font(.system(size: 15))
                .foregroundStyle(color)
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.labelLarge)
            .foregroundStyle(Theme.textSecondary)
            .textCase(nil)
    }

    private func colorDot(color: Color, label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 26, height: 26)
                if isSelected {
                    Circle()
                        .strokeBorder(.white, lineWidth: 2)
                        .frame(width: 26, height: 26)
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsStore())
        .environmentObject(HealthKitManager())
        .environmentObject(PlannerStore())
}
