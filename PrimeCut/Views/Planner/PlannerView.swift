import SwiftUI

struct PlannerView: View {
    @EnvironmentObject var store: PlannerStore
    @EnvironmentObject var settings: SettingsStore

    @State private var showAddWorkout = false
    @State private var selectedDayOffset = 0  // 0 = today
    @State private var showGroceryList = false

    private var selectedPlan: DayPlan {
        let target = Calendar.current.date(byAdding: .day, value: selectedDayOffset, to: Calendar.current.startOfDay(for: .now)) ?? .now
        return store.weekPlans.first(where: { Calendar.current.isDate($0.date, inSameDayAs: target) })
            ?? store.todayPlan
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Day strip
                    dayStrip
                        .padding(.bottom, Theme.spacingMD)

                    // Toolbar
                    planToolbar
                        .padding(.horizontal, Theme.spacingMD)
                        .padding(.bottom, Theme.spacingSM)

                    // Timeline
                    TimelineView(plan: selectedDayOffset == 0 ? store.todayPlan : selectedPlan)
                        .padding(.horizontal, Theme.spacingMD)
                        .animation(.springSnappy, value: selectedDayOffset)

                    Spacer(minLength: 80)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { navBar }
            .sheet(isPresented: $showAddWorkout) {
                AddWorkoutSheet()
                    .environmentObject(store)
                    .environmentObject(settings)
            }
            .sheet(isPresented: $showGroceryList) {
                GroceryListSheet()
                    .environmentObject(store)
                    .environmentObject(settings)
            }
        }
    }

    // MARK: - Day strip
    private var dayStrip: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(-3...3, id: \.self) { offset in
                        DayChip(
                            offset: offset,
                            isSelected: selectedDayOffset == offset,
                            hasWorkout: planHasWorkout(offset: offset),
                            accentColor: settings.accentColor
                        ) {
                            withAnimation(.springSnappy) { selectedDayOffset = offset }
                            HapticManager.selection()
                        }
                        .id(offset)
                    }
                }
                .padding(.horizontal, Theme.spacingMD)
                .padding(.vertical, Theme.spacingSM)
            }
            .onAppear {
                proxy.scrollTo(0, anchor: .center)
            }
        }
        .background(Theme.surface)
    }

    // MARK: - Plan toolbar
    private var planToolbar: some View {
        HStack(spacing: 10) {
            // Add workout button
            Button {
                showAddWorkout = true
                HapticManager.impact(.medium)
            } label: {
                Label("Add Workout", systemImage: "plus")
                    .font(.labelLarge)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(settings.accentGradient)
                    .clipShape(Capsule())
            }
            .buttonStyle(ScaleButtonStyle())

            // Remove workout (if exists and it's today)
            if store.todayPlan.workout != nil && selectedDayOffset == 0 {
                Button {
                    withAnimation(.springSnappy) { store.removeWorkout() }
                    HapticManager.impact(.light)
                } label: {
                    Label("Remove", systemImage: "trash")
                        .font(.labelLarge)
                        .foregroundStyle(Theme.danger)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Theme.danger.opacity(0.12))
                        .clipShape(Capsule())
                }
                .buttonStyle(ScaleButtonStyle())
            }

            Spacer()

            // Grocery list
            Button {
                store.generateGroceryList()
                showGroceryList = true
            } label: {
                Image(systemName: "cart.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(8)
                    .background(Theme.surfaceHigh)
                    .clipShape(Circle())
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }

    // MARK: - Nav bar
    private var navBar: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarLeading) {
                Text("Planner")
                    .font(.titleLarge)
                    .foregroundStyle(Theme.textPrimary)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Text(selectedPlan.date.weekdayShort)
                    .font(.labelLarge)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Theme.surfaceHigh)
                    .clipShape(Capsule())
            }
        }
    }

    private func planHasWorkout(offset: Int) -> Bool {
        let target = Calendar.current.date(byAdding: .day, value: offset, to: Calendar.current.startOfDay(for: .now)) ?? .now
        return store.weekPlans.first(where: { Calendar.current.isDate($0.date, inSameDayAs: target) })?.workout != nil
    }
}

// MARK: - Day chip
private struct DayChip: View {
    let offset: Int
    let isSelected: Bool
    let hasWorkout: Bool
    let accentColor: Color
    let action: () -> Void

    private var date: Date {
        Calendar.current.date(byAdding: .day, value: offset, to: Calendar.current.startOfDay(for: .now)) ?? .now
    }

    private var isToday: Bool { offset == 0 }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(date.weekdayShort.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : Theme.textTertiary)

                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(isSelected ? .white : (isToday ? accentColor : Theme.textPrimary))

                // Workout dot
                Circle()
                    .fill(hasWorkout ? (isSelected ? Color.white : accentColor) : Color.clear)
                    .frame(width: 5, height: 5)
            }
            .frame(width: 46, height: 68)
            .background(
                RoundedRectangle(cornerRadius: Theme.radiusMedium)
                    .fill(isSelected ? accentColor : Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusMedium)
                    .strokeBorder(
                        isToday && !isSelected ? accentColor.opacity(0.4) : Color.clear,
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.04 : 1.0)
        .animation(.springSnappy, value: isSelected)
    }
}

// MARK: - Grocery List Sheet
struct GroceryListSheet: View {
    @EnvironmentObject var store: PlannerStore
    @EnvironmentObject var settings: SettingsStore
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if let list = store.groceryList {
                    List {
                        ForEach(list.grouped.keys.sorted(), id: \.self) { category in
                            Section {
                                ForEach(list.grouped[category] ?? []) { item in
                                    HStack {
                                        Text(item.name)
                                            .foregroundStyle(Theme.textPrimary)
                                        Spacer()
                                        Text(item.quantity)
                                            .foregroundStyle(Theme.textSecondary)
                                            .font(.bodyMedium)
                                    }
                                    .listRowBackground(Theme.surface)
                                }
                            } header: {
                                Text(category)
                                    .foregroundStyle(settings.accentColor)
                                    .font(.labelLarge)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                } else {
                    Text("Generating list…")
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .navigationTitle("Grocery List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        store.groceryList?.shareAsNotes()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(settings.accentColor)
                }
            }
        }
        .presentationBackground(Theme.background)
    }
}

#Preview {
    PlannerView()
        .environmentObject(PlannerStore())
        .environmentObject(SettingsStore())
}
