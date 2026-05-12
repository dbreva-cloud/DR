import SwiftUI

struct AddWorkoutSheet: View {
    @EnvironmentObject var store: PlannerStore
    @EnvironmentObject var settings: SettingsStore
    @Environment(\.dismiss) var dismiss

    @State private var selectedType: WorkoutType = .strength
    @State private var startHour: Int   = 18
    @State private var startMinute: Int = 0
    @State private var durationMinutes: Int = 60
    @State private var showTypePicker = false

    private var startTime: Date {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: store.todayPlan.date)
        comps.hour   = startHour
        comps.minute = startMinute
        return Calendar.current.date(from: comps) ?? .now
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Theme.spacingLG) {
                        // Type selector
                        typeSelector

                        // Time & Duration
                        timeDurationCard

                        // Preview
                        mealPreviewCard

                        // Add button
                        addButton
                    }
                    .padding(Theme.spacingMD)
                }
            }
            .navigationTitle("Add Workout")
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

    // MARK: - Type selector
    private var typeSelector: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            Text("Workout Type")
                .font(.titleMedium)
                .foregroundStyle(Theme.textPrimary)

            HStack(spacing: 10) {
                ForEach(WorkoutType.allCases) { type in
                    TypeChip(
                        type: type,
                        isSelected: selectedType == type
                    ) {
                        withAnimation(.springSnappy) { selectedType = type }
                        HapticManager.selection()
                    }
                }
            }
        }
        .primeCutCard()
        .cardBorder()
    }

    // MARK: - Time & duration
    private var timeDurationCard: some View {
        VStack(alignment: .leading, spacing: Theme.spacingMD) {
            Text("Timing")
                .font(.titleMedium)
                .foregroundStyle(Theme.textPrimary)

            // Start time
            VStack(alignment: .leading, spacing: 6) {
                Text("Start Time")
                    .font(.labelLarge)
                    .foregroundStyle(Theme.textSecondary)
                HStack(spacing: 12) {
                    Picker("Hour", selection: $startHour) {
                        ForEach(5...22, id: \.self) { h in
                            Text(hourLabel(h)).tag(h)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 90, height: 100)
                    .clipped()

                    Text(":")
                        .font(.titleLarge)
                        .foregroundStyle(Theme.textSecondary)

                    Picker("Minute", selection: $startMinute) {
                        ForEach([0, 15, 30, 45], id: \.self) { m in
                            Text(String(format: "%02d", m)).tag(m)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 70, height: 100)
                    .clipped()

                    Spacer()

                    Text(startTime.hourMinuteString)
                        .font(.titleMedium)
                        .foregroundStyle(settings.accentColor)
                }
            }

            Divider().background(Theme.separator)

            // Duration
            VStack(alignment: .leading, spacing: 6) {
                Text("Duration: \(durationMinutes) min")
                    .font(.labelLarge)
                    .foregroundStyle(Theme.textSecondary)

                HStack(spacing: 10) {
                    ForEach([30, 45, 60, 75, 90, 120], id: \.self) { mins in
                        DurationChip(
                            minutes: mins,
                            isSelected: durationMinutes == mins,
                            accentColor: settings.accentColor
                        ) {
                            durationMinutes = mins
                            HapticManager.selection()
                        }
                    }
                }
            }
        }
        .primeCutCard()
        .cardBorder()
    }

    // MARK: - Meal preview
    private var mealPreviewCard: some View {
        let workout = Workout(type: selectedType, startTime: startTime,
                              duration: Double(durationMinutes) * 60)
        return VStack(alignment: .leading, spacing: Theme.spacingMD) {
            HStack {
                Text("Auto-Generated Meals")
                    .font(.titleMedium)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Image(systemName: "bolt.fill")
                    .foregroundStyle(settings.accentColor)
            }

            if selectedType == .rest {
                HStack(spacing: 8) {
                    Image(systemName: "moon.fill")
                        .foregroundStyle(Theme.restColor)
                    Text("Rest day — standard meals only, lower carbs")
                        .font(.bodyMedium)
                        .foregroundStyle(Theme.textSecondary)
                }
            } else {
                MealPreviewRow(
                    icon: "bolt.fill",
                    label: "Pre-Workout",
                    time: workout.preWorkoutMealTime.hourMinuteString,
                    macros: .preWorkout(for: selectedType),
                    accentColor: settings.accentColor
                )
                Divider().background(Theme.separator)
                MealPreviewRow(
                    icon: "flame.fill",
                    label: "Post-Workout",
                    time: workout.postWorkoutMealTime.hourMinuteString,
                    macros: .postWorkout(for: selectedType),
                    accentColor: settings.accentColor
                )
            }
        }
        .primeCutCard()
        .cardBorder()
        .animation(.springSnappy, value: selectedType)
    }

    // MARK: - Add button
    private var addButton: some View {
        Button {
            let workout = Workout(
                type: selectedType,
                startTime: startTime,
                duration: Double(durationMinutes) * 60
            )
            withAnimation(.springSnappy) {
                store.addOrUpdateWorkout(workout)
            }
            HapticManager.notification(.success)
            dismiss()
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add to Plan")
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

    private func hourLabel(_ h: Int) -> String {
        let suffix = h < 12 ? "AM" : "PM"
        let display = h > 12 ? h - 12 : (h == 0 ? 12 : h)
        return "\(display) \(suffix)"
    }
}

// MARK: - Supporting views
private struct TypeChip: View {
    let type: WorkoutType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isSelected ? type.color.opacity(0.2) : Theme.surfaceHigh)
                        .frame(width: 52, height: 52)
                    Image(systemName: type.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(isSelected ? type.color : Theme.textTertiary)
                }
                .overlay(
                    Circle().strokeBorder(
                        isSelected ? type.color : Color.clear,
                        lineWidth: 2
                    )
                )
                Text(type.rawValue)
                    .font(.labelSmall)
                    .foregroundStyle(isSelected ? type.color : Theme.textSecondary)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

private struct DurationChip: View {
    let minutes: Int
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(minutes)m")
                .font(.labelLarge)
                .foregroundStyle(isSelected ? .white : Theme.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isSelected ? accentColor : Theme.surfaceHigh)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.springSnappy, value: isSelected)
    }
}

private struct MealPreviewRow: View {
    let icon: String
    let label: String
    let time: String
    let macros: Macros
    let accentColor: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(accentColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.textPrimary)
                Text("P:\(Int(macros.protein))g · C:\(Int(macros.carbs))g · F:\(Int(macros.fat))g")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            Text(time)
                .font(.labelLarge)
                .foregroundStyle(accentColor)
        }
    }
}

#Preview {
    AddWorkoutSheet()
        .environmentObject(PlannerStore())
        .environmentObject(SettingsStore())
}
