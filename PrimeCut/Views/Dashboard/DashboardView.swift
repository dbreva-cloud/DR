import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var store: PlannerStore
    @EnvironmentObject var healthKit: HealthKitManager
    @EnvironmentObject var settings: SettingsStore

    @State private var showRecoverySheet = false
    @State private var scrollOffset: CGFloat = 0
    @State private var headerOpacity: Double = 1.0

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Theme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Theme.spacingMD) {
                        // Step ring hero
                        stepRingHero

                        // Streak
                        StreakView(count: settings.streakCount, accentGradient: settings.accentGradient)
                            .padding(.horizontal, Theme.spacingMD)

                        // Checklist
                        DailyChecklistView()
                            .padding(.horizontal, Theme.spacingMD)

                        // Today's plan
                        TodayPlanCard()
                            .padding(.horizontal, Theme.spacingMD)

                        // Recovery section
                        recoverySection
                            .padding(.horizontal, Theme.spacingMD)

                        Spacer(minLength: 80)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { navigationBar }
            .sheet(isPresented: $showRecoverySheet) {
                RecoveryInputSheet()
                    .environmentObject(store)
            }
            .task {
                if healthKit.authorizationStatus == .notDetermined {
                    await healthKit.requestAuthorization()
                }
                store.todayPlan.steps = healthKit.stepCount
                store.runAutoMode(steps: healthKit.stepCount, settings: settings)
            }
            .onChange(of: healthKit.stepCount) { _, newSteps in
                store.todayPlan.steps = newSteps
                store.runAutoMode(steps: newSteps, settings: settings)

                // Auto-check step goal
                if newSteps >= settings.stepGoal {
                    autoCheckStepGoal()
                }
            }
            .onChange(of: store.todayPlan.isComplete) { _, isComplete in
                if isComplete { settings.recordDayCompletion() }
            }
        }
    }

    // MARK: - Step ring hero
    private var stepRingHero: some View {
        ZStack {
            // Background gradient
            RadialGradient(
                colors: [settings.accentColor.opacity(0.06), Theme.background],
                center: .center,
                startRadius: 10,
                endRadius: 180
            )
            .frame(height: 260)

            VStack(spacing: 8) {
                StepRingView(
                    steps: healthKit.stepCount,
                    goal: settings.stepGoal,
                    accentGradient: settings.accentGradient
                )

                Text(stepStatusText)
                    .font(.labelLarge)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.top, 4)
            }
            .padding(.top, 16)
        }
    }

    private var stepStatusText: String {
        let remaining = max(settings.stepGoal - healthKit.stepCount, 0)
        if remaining == 0 { return "Step goal crushed!" }
        return "\(remaining.stepString) steps to go"
    }

    // MARK: - Recovery section
    private var recoverySection: some View {
        Button(action: { showRecoverySheet = true }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Theme.surfaceHigh)
                        .frame(width: 44, height: 44)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.red.opacity(0.8))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Recovery Check-In")
                        .font(.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.textPrimary)
                    Text("Sleep \(store.recovery.sleepQuality)/5 · Stress \(store.recovery.stressLevel)/5 · Score \(store.recovery.recoveryScore)")
                        .font(.bodyMedium)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
            }
            .primeCutCard()
            .cardBorder()
        }
        .buttonStyle(.plain)
        .scaleOnPress()
    }

    // MARK: - Nav bar
    private var navigationBar: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarLeading) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("PRIME CUT")
                        .font(.system(size: 15, weight: .black, design: .default))
                        .foregroundStyle(settings.accentColor)
                        .kerning(2)
                    Text(todayDateString)
                        .font(.caption)
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if settings.autoModeEnabled {
                    Label("Auto", systemImage: "bolt.fill")
                        .font(.labelSmall)
                        .foregroundStyle(settings.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(settings.accentColor.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var todayDateString: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: .now)
    }

    private func autoCheckStepGoal() {
        guard let idx = store.todayPlan.checklist.firstIndex(where: { $0.label == "Step Goal" }),
              !store.todayPlan.checklist[idx].isChecked else { return }
        store.toggleChecklist(id: store.todayPlan.checklist[idx].id)
    }
}

// MARK: - Recovery Input Sheet
struct RecoveryInputSheet: View {
    @EnvironmentObject var store: PlannerStore
    @Environment(\.dismiss) var dismiss

    @State private var sleepQuality: Int = 3
    @State private var stressLevel: Int  = 2

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                VStack(spacing: Theme.spacingLG) {
                    // Sleep
                    ratingSection(
                        title: "Sleep Quality",
                        icon: "moon.fill",
                        value: $sleepQuality,
                        labels: ["Poor", "Fair", "OK", "Good", "Great"]
                    )

                    // Stress
                    ratingSection(
                        title: "Stress Level",
                        icon: "brain.head.profile",
                        value: $stressLevel,
                        labels: ["None", "Low", "Moderate", "High", "Extreme"]
                    )

                    // Score preview
                    let preview = RecoveryInput(sleepQuality: sleepQuality, stressLevel: stressLevel)
                    recoveryScorePreview(preview)

                    Spacer()
                }
                .padding(Theme.spacingLG)
            }
            .navigationTitle("Recovery Check-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        store.updateRecovery(RecoveryInput(
                            sleepQuality: sleepQuality,
                            stressLevel: stressLevel
                        ))
                        HapticManager.notification(.success)
                        dismiss()
                    }
                    .font(.bodyLarge.bold())
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .onAppear {
                sleepQuality = store.recovery.sleepQuality
                stressLevel  = store.recovery.stressLevel
            }
        }
        .presentationDetents([.medium])
        .presentationBackground(Theme.surface)
    }

    private func ratingSection(title: String, icon: String, value: Binding<Int>,
                                labels: [String]) -> some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            Label(title, systemImage: icon)
                .font(.titleMedium)
                .foregroundStyle(Theme.textPrimary)

            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { n in
                    Button {
                        value.wrappedValue = n
                        HapticManager.selection()
                    } label: {
                        VStack(spacing: 4) {
                            Circle()
                                .fill(value.wrappedValue >= n ? Theme.accent : Theme.surfaceHigh)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text("\(n)")
                                        .font(.labelLarge)
                                        .foregroundStyle(value.wrappedValue >= n ? .white : Theme.textSecondary)
                                )
                            Text(labels[n - 1])
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(value.wrappedValue == n ? 1.1 : 1.0)
                    .animation(.springSnappy, value: value.wrappedValue)
                }
            }
        }
        .primeCutCard()
        .cardBorder()
    }

    private func recoveryScorePreview(_ input: RecoveryInput) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Recovery Score")
                    .font(.labelLarge)
                    .foregroundStyle(Theme.textSecondary)
                Text(input.workoutSuggestion.detail)
                    .font(.bodyMedium)
                    .foregroundStyle(Theme.textPrimary)
            }
            Spacer()
            ZStack {
                Circle()
                    .stroke(Theme.separator, lineWidth: 4)
                    .frame(width: 60, height: 60)
                Circle()
                    .trim(from: 0, to: Double(input.recoveryScore) / 100)
                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                Text("\(input.recoveryScore)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
            }
        }
        .primeCutCard()
        .cardBorder()
    }
}

#Preview {
    DashboardView()
        .environmentObject(PlannerStore())
        .environmentObject(HealthKitManager())
        .environmentObject(SettingsStore())
}
