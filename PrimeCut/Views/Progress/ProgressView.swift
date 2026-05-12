import SwiftUI
import Charts

struct PrimeCutProgressView: View {
    @EnvironmentObject var store: PlannerStore
    @EnvironmentObject var settings: SettingsStore

    @State private var chartsAppeared = false

    private var data: ProgressData { store.progressData }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Theme.spacingMD) {
                        // Summary cards row
                        summaryRow

                        // Weekly adherence
                        adherenceCard

                        // Step bar chart
                        stepChart

                        // Workout + Recovery
                        HStack(alignment: .top, spacing: Theme.spacingMD) {
                            workoutConsistencyCard
                            recoveryCard
                        }
                        .padding(.horizontal, Theme.spacingMD)

                        Spacer(minLength: 80)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { navBar }
            .onAppear {
                withAnimation(.smooth.delay(0.1)) {
                    chartsAppeared = true
                }
            }
        }
    }

    // MARK: - Summary row
    private var summaryRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                StatPill(
                    value: "\(Int(data.weekAdherence * 100))%",
                    label: "Adherence",
                    icon: "checkmark.circle.fill",
                    color: settings.accentColor
                )
                StatPill(
                    value: "\(Int(data.workoutConsistency * 100))%",
                    label: "Workouts",
                    icon: "dumbbell.fill",
                    color: settings.accentColor
                )
                StatPill(
                    value: "\(Int(data.averageRecovery))",
                    label: "Avg Recovery",
                    icon: "heart.fill",
                    color: Color.red.opacity(0.8)
                )
                StatPill(
                    value: "\(settings.streakCount)",
                    label: "Day Streak",
                    icon: "flame.fill",
                    color: .orange
                )
            }
            .padding(.horizontal, Theme.spacingMD)
        }
    }

    // MARK: - Adherence chart
    private var adherenceCard: some View {
        VStack(alignment: .leading, spacing: Theme.spacingMD) {
            sectionHeader("Weekly Adherence", subtitle: "Last 7 days")

            if chartsAppeared {
                AdherenceLineChart(entries: data.entries, accentColor: settings.accentColor)
                    .frame(height: 140)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                Rectangle().fill(Color.clear).frame(height: 140)
            }
        }
        .primeCutCard()
        .cardBorder()
        .padding(.horizontal, Theme.spacingMD)
    }

    // MARK: - Step chart
    private var stepChart: some View {
        VStack(alignment: .leading, spacing: Theme.spacingMD) {
            sectionHeader("Daily Steps", subtitle: "vs. goal")

            if chartsAppeared {
                StepBarChart(entries: data.entries, goal: settings.stepGoal, accentColor: settings.accentColor)
                    .frame(height: 140)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                Rectangle().fill(Color.clear).frame(height: 140)
            }
        }
        .primeCutCard()
        .cardBorder()
        .padding(.horizontal, Theme.spacingMD)
    }

    // MARK: - Workout consistency
    private var workoutConsistencyCard: some View {
        VStack(alignment: .leading, spacing: Theme.spacingMD) {
            sectionHeader("Workouts", subtitle: "this week")

            ZStack {
                Circle()
                    .stroke(Theme.surfaceHigh, lineWidth: 8)
                Circle()
                    .trim(from: 0, to: chartsAppeared ? data.workoutConsistency : 0)
                    .stroke(
                        settings.accentGradient,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.smoothSlow.delay(0.3), value: chartsAppeared)

                VStack(spacing: 2) {
                    Text("\(Int(data.workoutConsistency * 100))%")
                        .font(.titleLarge)
                        .fontWeight(.black)
                        .foregroundStyle(Theme.textPrimary)
                    Text("done")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .frame(width: 90, height: 90)
            .frame(maxWidth: .infinity)
        }
        .primeCutCard()
        .cardBorder()
        .frame(maxWidth: .infinity)
    }

    // MARK: - Recovery card
    private var recoveryCard: some View {
        VStack(alignment: .leading, spacing: Theme.spacingMD) {
            sectionHeader("Recovery", subtitle: "avg score")

            let score = Int(data.averageRecovery)
            ZStack {
                Circle()
                    .stroke(Theme.surfaceHigh, lineWidth: 8)
                Circle()
                    .trim(from: 0, to: chartsAppeared ? Double(score) / 100 : 0)
                    .stroke(
                        LinearGradient(
                            colors: [.red, .orange, settings.accentColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.smoothSlow.delay(0.4), value: chartsAppeared)

                VStack(spacing: 2) {
                    Text("\(score)")
                        .font(.titleLarge)
                        .fontWeight(.black)
                        .foregroundStyle(Theme.textPrimary)
                    Text("/ 100")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .frame(width: 90, height: 90)
            .frame(maxWidth: .infinity)
        }
        .primeCutCard()
        .cardBorder()
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers
    private func sectionHeader(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.titleMedium)
                .foregroundStyle(Theme.textPrimary)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(Theme.textTertiary)
        }
    }

    private var navBar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Text("Progress")
                .font(.titleLarge)
                .foregroundStyle(Theme.textPrimary)
        }
    }
}

// MARK: - Stat pill
private struct StatPill: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(Theme.textPrimary)

            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusMedium)
                .strokeBorder(Theme.separator, lineWidth: 0.5)
        )
    }
}

#Preview {
    PrimeCutProgressView()
        .environmentObject(PlannerStore())
        .environmentObject(SettingsStore())
}
