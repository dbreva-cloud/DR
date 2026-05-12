import SwiftUI

struct WorkoutHistoryView: View {
    @EnvironmentObject var store: PlannerStore
    @EnvironmentObject var settings: SettingsStore

    @State private var selectedLog: WorkoutLog?
    @State private var showLogWorkout = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if store.workoutHistory.logs.isEmpty {
                    emptyState
                } else {
                    List {
                        // This week summary
                        Section {
                            weekSummaryCard
                        } header: {
                            sectionLabel("This Week")
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

                        // History
                        Section {
                            ForEach(store.workoutHistory.logs) { log in
                                HistoryRow(log: log, accentColor: settings.accentColor)
                                    .listRowBackground(Theme.surface)
                                    .onTapGesture { selectedLog = log }
                            }
                        } header: {
                            sectionLabel("All Workouts")
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Workout History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showLogWorkout = true
                        HapticManager.impact(.medium)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(settings.accentColor)
                    }
                }
            }
            .sheet(isPresented: $showLogWorkout) {
                LogWorkoutSheet()
                    .environmentObject(store)
                    .environmentObject(settings)
            }
            .sheet(item: $selectedLog) { log in
                LogDetailSheet(log: log)
                    .environmentObject(settings)
            }
        }
    }

    // MARK: - Week summary
    private var weekSummaryCard: some View {
        let week = store.workoutHistory.logsForCurrentWeek()
        let completed = week.filter(\.completed).count
        let rate = store.workoutHistory.weeklyCompletionRate

        return HStack(spacing: 0) {
            // Completion circle
            ZStack {
                Circle()
                    .stroke(Theme.surfaceHigh, lineWidth: 6)
                Circle()
                    .trim(from: 0, to: rate)
                    .stroke(settings.accentGradient,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(completed)")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text("done")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .frame(width: 70, height: 70)
            .padding(.trailing, 16)

            VStack(alignment: .leading, spacing: 6) {
                Text("\(completed) of \(week.count) workouts completed")
                    .font(.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.textPrimary)

                // Type breakdown
                HStack(spacing: 8) {
                    ForEach(WorkoutType.allCases) { type in
                        let count = week.filter { $0.type == type && $0.completed }.count
                        if count > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: type.icon)
                                    .font(.system(size: 10))
                                    .foregroundStyle(type.color)
                                Text("\(count)")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }

    // MARK: - Empty state
    private var emptyState: some View {
        VStack(spacing: Theme.spacingMD) {
            Image(systemName: "dumbbell")
                .font(.system(size: 44))
                .foregroundStyle(Theme.textTertiary)
            Text("No workouts logged yet")
                .font(.titleMedium)
                .foregroundStyle(Theme.textSecondary)
            Text("Tap + to log your first workout")
                .font(.bodyMedium)
                .foregroundStyle(Theme.textTertiary)
            Button {
                showLogWorkout = true
            } label: {
                Label("Log Workout", systemImage: "plus")
                    .font(.bodyLarge.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(settings.accentGradient)
                    .clipShape(Capsule())
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.top, 8)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.labelLarge)
            .foregroundStyle(Theme.textSecondary)
            .textCase(nil)
    }
}

// MARK: - History row
private struct HistoryRow: View {
    let log: WorkoutLog
    let accentColor: Color

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(log.type.color.opacity(log.completed ? 0.15 : 0.05))
                    .frame(width: 44, height: 44)
                Image(systemName: log.completed ? log.type.icon : "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(log.completed ? log.type.color : Theme.textTertiary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(log.type.label)
                    .font(.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundStyle(log.completed ? Theme.textPrimary : Theme.textSecondary)

                HStack(spacing: 6) {
                    Text(log.date, style: .date)
                    Text("·")
                    Text(log.durationString)
                    if let rpe = log.perceivedEffort {
                        Text("·")
                        Text("RPE \(rpe)")
                    }
                }
                .font(.caption)
                .foregroundStyle(Theme.textTertiary)
            }

            Spacer()

            if log.completed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(accentColor)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Log Workout Sheet
struct LogWorkoutSheet: View {
    @EnvironmentObject var store: PlannerStore
    @EnvironmentObject var settings: SettingsStore
    @Environment(\.dismiss) var dismiss

    @State private var type: WorkoutType = .strength
    @State private var date: Date = .now
    @State private var durationMinutes: Int = 60
    @State private var completed: Bool = true
    @State private var rpe: Int = 7
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Theme.spacingLG) {
                        // Type
                        typeSection
                        // Date + Duration
                        timingSection
                        // Completed toggle
                        completedSection
                        // RPE
                        rpeSection
                        // Notes
                        notesSection
                        // Save
                        saveButton
                    }
                    .padding(Theme.spacingMD)
                }
            }
            .navigationTitle("Log Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .presentationDetents([.large])
        .presentationBackground(Theme.surface)
    }

    private var typeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Workout Type")
                .font(.titleMedium)
                .foregroundStyle(Theme.textPrimary)
            HStack(spacing: 10) {
                ForEach(WorkoutType.allCases) { t in
                    Button {
                        withAnimation(.springSnappy) { type = t }
                        HapticManager.selection()
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(type == t ? t.color.opacity(0.2) : Theme.surfaceHigh)
                                    .frame(width: 52, height: 52)
                                    .overlay(Circle().strokeBorder(type == t ? t.color : Color.clear, lineWidth: 2))
                                Image(systemName: t.icon)
                                    .font(.system(size: 20))
                                    .foregroundStyle(type == t ? t.color : Theme.textTertiary)
                            }
                            Text(t.rawValue)
                                .font(.labelSmall)
                                .foregroundStyle(type == t ? t.color : Theme.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .primeCutCard()
        .cardBorder()
    }

    private var timingSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingMD) {
            Text("When")
                .font(.titleMedium)
                .foregroundStyle(Theme.textPrimary)
            DatePicker("Date", selection: $date, displayedComponents: [.date])
                .datePickerStyle(.compact)
                .tint(settings.accentColor)
                .foregroundStyle(Theme.textPrimary)
            Divider().background(Theme.separator)
            VStack(alignment: .leading, spacing: 6) {
                Text("Duration: \(durationMinutes) min")
                    .font(.labelLarge)
                    .foregroundStyle(Theme.textSecondary)
                HStack(spacing: 8) {
                    ForEach([30, 45, 60, 75, 90, 120], id: \.self) { m in
                        Button {
                            durationMinutes = m
                            HapticManager.selection()
                        } label: {
                            Text("\(m)m")
                                .font(.labelLarge)
                                .foregroundStyle(durationMinutes == m ? .white : Theme.textSecondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(durationMinutes == m ? settings.accentColor : Theme.surfaceHigh)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .scaleEffect(durationMinutes == m ? 1.05 : 1.0)
                        .animation(.springSnappy, value: durationMinutes)
                    }
                }
            }
        }
        .primeCutCard()
        .cardBorder()
    }

    private var completedSection: some View {
        Toggle(isOn: $completed) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(settings.accentColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(settings.accentColor)
                }
                Text("Workout completed")
                    .foregroundStyle(Theme.textPrimary)
            }
        }
        .tint(settings.accentColor)
        .primeCutCard()
        .cardBorder()
    }

    private var rpeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Perceived Effort (RPE \(rpe)/10)")
                .font(.titleMedium)
                .foregroundStyle(Theme.textPrimary)
            HStack(spacing: 4) {
                ForEach(1...10, id: \.self) { n in
                    Button {
                        rpe = n
                        HapticManager.selection()
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(rpe >= n ? rpeColor(n) : Theme.surfaceHigh)
                                .frame(height: 32)
                            Text("\(n)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(rpe >= n ? .white : Theme.textTertiary)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .animation(.springSnappy, value: rpe)
                }
            }
            Text(rpeLabel)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .primeCutCard()
        .cardBorder()
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.titleMedium)
                .foregroundStyle(Theme.textPrimary)
            TextField("How did it go?", text: $notes, axis: .vertical)
                .font(.bodyLarge)
                .foregroundStyle(Theme.textPrimary)
                .tint(settings.accentColor)
                .lineLimit(3...5)
        }
        .primeCutCard()
        .cardBorder()
    }

    private var saveButton: some View {
        Button {
            let log = WorkoutLog(
                date: date,
                type: type,
                duration: Double(durationMinutes) * 60,
                completed: completed,
                notes: notes.isEmpty ? nil : notes,
                perceivedEffort: rpe
            )
            store.logWorkout(log)
            HapticManager.notification(.success)
            dismiss()
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Save Workout")
                    .fontWeight(.bold)
            }
            .font(.bodyLarge)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(settings.accentGradient)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func rpeColor(_ n: Int) -> Color {
        switch n {
        case 1...3: return settings.accentColor
        case 4...6: return .orange
        case 7...8: return Color.orange.mix(with: .red, by: 0.4)
        default:    return .red
        }
    }

    private var rpeLabel: String {
        switch rpe {
        case 1...3: return "Light effort — recovery pace"
        case 4...5: return "Moderate — sustainable"
        case 6...7: return "Hard — challenging but manageable"
        case 8...9: return "Very hard — near limit"
        default:    return "Maximum — nothing left in the tank"
        }
    }
}

// MARK: - Log detail sheet
struct LogDetailSheet: View {
    let log: WorkoutLog
    @EnvironmentObject var settings: SettingsStore
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                VStack(spacing: Theme.spacingLG) {
                    // Icon + title
                    HStack(spacing: 16) {
                        ZStack {
                            Circle().fill(log.type.color.opacity(0.15)).frame(width: 64, height: 64)
                            Image(systemName: log.type.icon).font(.system(size: 28)).foregroundStyle(log.type.color)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(log.type.label).font(.titleLarge).foregroundStyle(Theme.textPrimary)
                            Text(log.date, style: .date).font(.bodyMedium).foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                    }
                    .primeCutCard().cardBorder()

                    // Stats
                    HStack(spacing: 12) {
                        StatBox(label: "Duration", value: log.durationString)
                        StatBox(label: "Status", value: log.completed ? "Done" : "Skipped")
                        if let rpe = log.perceivedEffort {
                            StatBox(label: "RPE", value: "\(rpe)/10")
                        }
                    }

                    if let notes = log.notes {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes").font(.labelLarge).foregroundStyle(Theme.textSecondary)
                            Text(notes).font(.bodyLarge).foregroundStyle(Theme.textPrimary)
                        }
                        .primeCutCard().cardBorder()
                    }
                    Spacer()
                }
                .padding(Theme.spacingMD)
            }
            .navigationTitle("Workout Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.foregroundStyle(settings.accentColor)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationBackground(Theme.surface)
    }
}

private struct StatBox: View {
    let label: String
    let value: String
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.titleMedium).fontWeight(.bold).foregroundStyle(Theme.textPrimary)
            Text(label).font(.caption).foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 12)
        .background(Theme.surface).clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))
        .overlay(RoundedRectangle(cornerRadius: Theme.radiusMedium).strokeBorder(Theme.separator, lineWidth: 0.5))
    }
}

#Preview {
    WorkoutHistoryView()
        .environmentObject(PlannerStore())
        .environmentObject(SettingsStore())
}
