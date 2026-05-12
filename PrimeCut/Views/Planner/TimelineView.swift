import SwiftUI

// MARK: - Timeline block union
enum TimelineBlock: Identifiable {
    case workout(Workout)
    case meal(Meal)

    var id: UUID {
        switch self {
        case .workout(let w): return w.id
        case .meal(let m):    return m.id
        }
    }

    var scheduledTime: Date {
        switch self {
        case .workout(let w): return w.startTime
        case .meal(let m):    return m.scheduledTime
        }
    }
}

// MARK: - Main timeline
struct TimelineView: View {
    let plan: DayPlan
    var onMealTap: ((Meal) -> Void)? = nil

    @EnvironmentObject var settings: SettingsStore

    private let startHour      = 6
    private let endHour        = 23
    private let hourHeight: CGFloat = 64
    private let timeColumnWidth: CGFloat = 44

    private var timelineHeight: CGFloat {
        CGFloat(endHour - startHour) * hourHeight
    }

    private var blocks: [TimelineBlock] {
        var result: [TimelineBlock] = []
        if let w = plan.workout { result.append(.workout(w)) }
        result.append(contentsOf: plan.meals.map { .meal($0) })
        return result.sorted { $0.scheduledTime < $1.scheduledTime }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                ZStack(alignment: .topLeading) {
                    hourGrid
                    nowIndicator
                    // Invisible scroll anchor at current time
                    Color.clear
                        .frame(height: 1)
                        .id("now_anchor")
                        .offset(y: max(0, yOffset(for: .now) - 120))

                    ForEach(blocks) { block in
                        blockView(for: block)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.85, anchor: .top).combined(with: .opacity),
                                removal:   .scale(scale: 0.8).combined(with: .opacity)
                            ))
                    }
                }
                .frame(height: timelineHeight)
                .padding(.leading, timeColumnWidth)
                .padding(.trailing, 8)
            }
            .onAppear {
                // Delay slightly so scroll view is fully laid out
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    withAnimation(.smooth) {
                        proxy.scrollTo("now_anchor", anchor: .top)
                    }
                }
            }
        }
    }

    // MARK: - Hour grid
    private var hourGrid: some View {
        VStack(spacing: 0) {
            ForEach(startHour...endHour, id: \.self) { hour in
                HStack(alignment: .top, spacing: 8) {
                    Text(hourLabel(hour))
                        .font(.caption)
                        .foregroundStyle(Theme.textTertiary)
                        .frame(width: timeColumnWidth - 8, alignment: .trailing)

                    Rectangle()
                        .fill(Theme.separator)
                        .frame(height: 0.5)
                        .frame(maxWidth: .infinity)
                }
                .frame(height: hourHeight)
                .id("hour_\(hour)")
            }
        }
    }

    // MARK: - Now indicator
    private var nowIndicator: some View {
        let y = yOffset(for: .now)
        return HStack(spacing: 0) {
            Text("NOW")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(Color.red)
                .frame(width: timeColumnWidth - 4, alignment: .trailing)
            Circle().fill(Color.red).frame(width: 7, height: 7)
            Rectangle().fill(Color.red.opacity(0.6)).frame(height: 1)
        }
        .offset(y: y - 3.5)
    }

    // MARK: - Block views
    @ViewBuilder
    private func blockView(for block: TimelineBlock) -> some View {
        switch block {
        case .workout(let workout):
            WorkoutTimelineBlock(workout: workout, hourHeight: hourHeight, startHour: startHour)
                .padding(.leading, timeColumnWidth + 4)
                .offset(y: yOffset(for: workout.startTime))

        case .meal(let meal):
            MealTimelineBlock(meal: meal, accentColor: settings.accentColor)
                .padding(.leading, timeColumnWidth + 4)
                .offset(y: yOffset(for: meal.scheduledTime))
                .onTapGesture {
                    HapticManager.impact(.light)
                    onMealTap?(meal)
                }
        }
    }

    // MARK: - Helpers
    private func yOffset(for date: Date) -> CGFloat {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        let hour   = CGFloat(comps.hour ?? startHour)
        let minute = CGFloat(comps.minute ?? 0)
        return ((hour + minute / 60.0) - CGFloat(startHour)) * hourHeight
    }

    private func hourLabel(_ hour: Int) -> String {
        let suffix = hour < 12 ? "AM" : "PM"
        let h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        return "\(h)\(suffix)"
    }
}

// MARK: - Workout block
struct WorkoutTimelineBlock: View {
    let workout: Workout
    let hourHeight: CGFloat
    let startHour: Int

    private var blockHeight: CGFloat {
        max(CGFloat(workout.duration / 3600) * hourHeight, 48)
    }

    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2).fill(workout.type.color).frame(width: 4)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Image(systemName: workout.type.icon).font(.system(size: 12, weight: .semibold))
                    Text(workout.type.rawValue).font(.labelLarge)
                }
                .foregroundStyle(workout.type.color)
                Text("\(workout.startTime.hourMinuteString) – \(workout.endTime.hourMinuteString)")
                    .font(.caption).foregroundStyle(Theme.textSecondary)
                Text(workout.durationString)
                    .font(.caption).foregroundStyle(Theme.textTertiary)
            }
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(height: blockHeight, alignment: .top)
        .background(workout.type.color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSmall))
        .overlay(RoundedRectangle(cornerRadius: Theme.radiusSmall)
            .strokeBorder(workout.type.color.opacity(0.3), lineWidth: 1))
        .padding(.trailing, 8)
    }
}

// MARK: - Meal block
struct MealTimelineBlock: View {
    let meal: Meal
    let accentColor: Color

    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .fill(meal.isConsumed ? Theme.textTertiary : accentColor)
                .frame(width: 3)
            HStack(spacing: 6) {
                Image(systemName: meal.timing.icon)
                    .font(.system(size: 11))
                    .foregroundStyle(meal.isConsumed ? Theme.textTertiary : accentColor)
                Text(meal.timing.rawValue)
                    .font(.labelLarge)
                    .foregroundStyle(meal.isConsumed ? Theme.textTertiary : Theme.textPrimary)
                Spacer()
                Text(meal.macroSummary)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
            }
            if meal.isConsumed {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 14)).foregroundStyle(Theme.accent)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Theme.surfaceHigh)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSmall))
        .overlay(RoundedRectangle(cornerRadius: Theme.radiusSmall)
            .strokeBorder(meal.timing.isWorkoutRelated ? accentColor.opacity(0.25) : Theme.separator, lineWidth: 0.5))
        .padding(.trailing, 8)
    }
}
