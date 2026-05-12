import SwiftUI

struct MealDetailSheet: View {
    let meal: Meal
    @EnvironmentObject var store: PlannerStore
    @EnvironmentObject var settings: SettingsStore
    @Environment(\.dismiss) var dismiss

    @State private var consumed: Bool

    init(meal: Meal) {
        self.meal = meal
        _consumed = State(initialValue: meal.isConsumed)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Theme.spacingLG) {
                        // Header card
                        headerCard

                        // Macro breakdown
                        macroCard

                        // Food suggestions
                        foodSuggestionCard

                        // Mark consumed
                        consumedToggle

                        Spacer(minLength: 40)
                    }
                    .padding(Theme.spacingMD)
                }
            }
            .navigationTitle(meal.timing.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(settings.accentColor)
                }
            }
        }
        .presentationDetents([.large])
        .presentationBackground(Theme.surface)
    }

    // MARK: - Header
    private var headerCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(settings.accentColor.opacity(0.15))
                    .frame(width: 64, height: 64)
                Image(systemName: meal.timing.icon)
                    .font(.system(size: 28))
                    .foregroundStyle(settings.accentColor)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.timing.rawValue)
                    .font(.titleLarge)
                    .foregroundStyle(Theme.textPrimary)
                Text(meal.scheduledTime.hourMinuteString)
                    .font(.titleMedium)
                    .foregroundStyle(settings.accentColor)
                if meal.timing.isWorkoutRelated {
                    Label("Workout-linked meal", systemImage: "bolt.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            Spacer()
        }
        .primeCutCard()
        .cardBorder()
    }

    // MARK: - Macro breakdown
    private var macroCard: some View {
        VStack(alignment: .leading, spacing: Theme.spacingMD) {
            Text("Macros")
                .font(.titleMedium)
                .foregroundStyle(Theme.textPrimary)

            HStack(spacing: 12) {
                MacroPill(label: "Protein", value: meal.macros.protein, unit: "g",
                           color: .blue, icon: "bolt.heart.fill")
                MacroPill(label: "Carbs", value: meal.macros.carbs, unit: "g",
                           color: .orange, icon: "flame.fill")
                MacroPill(label: "Fat", value: meal.macros.fat, unit: "g",
                           color: settings.accentColor, icon: "drop.fill")
            }

            // Calories total
            HStack {
                Text("Total Calories")
                    .font(.bodyMedium)
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text("\(Int(meal.macros.calories)) kcal")
                    .font(.titleMedium)
                    .foregroundStyle(Theme.textPrimary)
            }
            .padding(.top, 4)

            // Macro bar
            MacroBar(protein: meal.macros.protein,
                     carbs: meal.macros.carbs,
                     fat: meal.macros.fat)
        }
        .primeCutCard()
        .cardBorder()
    }

    // MARK: - Food suggestions
    private var foodSuggestionCard: some View {
        VStack(alignment: .leading, spacing: Theme.spacingMD) {
            HStack {
                Text("Food Ideas")
                    .font(.titleMedium)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("Hit these macros")
                    .font(.caption)
                    .foregroundStyle(Theme.textTertiary)
            }

            VStack(spacing: 0) {
                ForEach(Array(foodSuggestions.enumerated()), id: \.offset) { idx, item in
                    FoodSuggestionRow(item: item, accentColor: settings.accentColor)
                    if idx < foodSuggestions.count - 1 {
                        Divider().background(Theme.separator).padding(.leading, 36)
                    }
                }
            }
        }
        .primeCutCard()
        .cardBorder()
    }

    // MARK: - Consumed toggle
    private var consumedToggle: some View {
        Button {
            withAnimation(.springSnappy) { consumed.toggle() }
            HapticManager.checkmark()
            store.markMealConsumed(id: meal.id)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: consumed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(consumed ? settings.accentColor : Theme.textTertiary)
                    .scaleEffect(consumed ? 1.1 : 1.0)
                    .animation(.springBouncy, value: consumed)

                Text(consumed ? "Meal logged" : "Mark as consumed")
                    .font(.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundStyle(consumed ? settings.accentColor : Theme.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .primeCutCard()
            .cardBorder()
        }
        .buttonStyle(.plain)
        .disabled(meal.isConsumed)
    }

    // MARK: - Food suggestions logic
    private var foodSuggestions: [FoodItem] {
        FoodSuggestionEngine.suggestions(for: meal.timing, macros: meal.macros)
    }
}

// MARK: - Macro pill
private struct MacroPill: View {
    let label: String
    let value: Double
    let unit: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
            Text("\(Int(value))\(unit)")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))
    }
}

// MARK: - Macro bar
private struct MacroBar: View {
    let protein: Double
    let carbs: Double
    let fat: Double
    @State private var appeared = false

    private var total: Double { protein + carbs + fat }
    private var proteinFrac: Double { protein / max(total, 1) }
    private var carbsFrac: Double { carbs / max(total, 1) }
    private var fatFrac: Double { fat / max(total, 1) }

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 2) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.blue.opacity(0.7))
                    .frame(width: appeared ? geo.size.width * proteinFrac : 0)
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.orange.opacity(0.7))
                    .frame(width: appeared ? geo.size.width * carbsFrac : 0)
                RoundedRectangle(cornerRadius: 3)
                    .fill(Theme.accent.opacity(0.7))
                    .frame(width: appeared ? geo.size.width * fatFrac : 0)
            }
            .frame(height: 8)
            .clipShape(RoundedRectangle(cornerRadius: 3))
        }
        .frame(height: 8)
        .animation(.smoothSlow.delay(0.2), value: appeared)
        .onAppear { appeared = true }
    }
}

// MARK: - Food suggestion row
private struct FoodSuggestionRow: View {
    let item: FoodItem
    let accentColor: Color

    var body: some View {
        HStack(spacing: 12) {
            Text(item.emoji)
                .font(.system(size: 24))
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.textPrimary)
                Text(item.portionNote)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("P:\(item.protein)g")
                    .font(.caption)
                    .foregroundStyle(Color.blue.opacity(0.8))
                Text("C:\(item.carbs)g")
                    .font(.caption)
                    .foregroundStyle(Color.orange.opacity(0.8))
            }
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Food item model
struct FoodItem {
    var emoji: String
    var name: String
    var portionNote: String
    var protein: Int
    var carbs: Int
}

// MARK: - Food suggestion engine
struct FoodSuggestionEngine {
    static func suggestions(for timing: MealTiming, macros: Macros) -> [FoodItem] {
        switch timing {
        case .breakfast:
            return [
                FoodItem(emoji: "🥚", name: "4 Eggs + 2 Whites", portionNote: "Scrambled or fried", protein: 28, carbs: 1),
                FoodItem(emoji: "🌾", name: "Oatmeal (1 cup dry)", portionNote: "With protein powder mix-in", protein: 10, carbs: 54),
                FoodItem(emoji: "🫙", name: "Greek Yogurt (200g)", portionNote: "Full-fat, plain", protein: 18, carbs: 8),
                FoodItem(emoji: "🍌", name: "Banana", portionNote: "Medium, pre-workout carb", protein: 1, carbs: 27),
            ]
        case .preWorkout:
            return [
                FoodItem(emoji: "🍚", name: "White Rice (1 cup cooked)", portionNote: "Fast digesting carb", protein: 4, carbs: 45),
                FoodItem(emoji: "🐔", name: "Chicken Breast (150g)", portionNote: "Lean, easy to digest", protein: 35, carbs: 0),
                FoodItem(emoji: "🍌", name: "Banana + Protein Shake", portionNote: "Quick energy + protein", protein: 25, carbs: 30),
                FoodItem(emoji: "🥜", name: "Rice Cakes + Almond Butter", portionNote: "2 cakes, 1 tbsp butter", protein: 4, carbs: 18),
            ]
        case .postWorkout:
            return [
                FoodItem(emoji: "🥩", name: "Ground Beef (200g)", portionNote: "90% lean", protein: 40, carbs: 0),
                FoodItem(emoji: "🍚", name: "White Rice (1.5 cups cooked)", portionNote: "Replenish glycogen", protein: 6, carbs: 66),
                FoodItem(emoji: "🥛", name: "Whey Protein Shake", portionNote: "2 scoops in water", protein: 48, carbs: 6),
                FoodItem(emoji: "🍠", name: "Sweet Potato (medium)", portionNote: "Baked, with skin", protein: 2, carbs: 26),
            ]
        case .lunch:
            return [
                FoodItem(emoji: "🐔", name: "Chicken Breast (200g)", portionNote: "Grilled or baked", protein: 46, carbs: 0),
                FoodItem(emoji: "🥗", name: "Large Salad + Avocado", portionNote: "Spinach, peppers, half avo", protein: 4, carbs: 12),
                FoodItem(emoji: "🍚", name: "White Rice (1 cup)", portionNote: "Or sweet potato", protein: 4, carbs: 45),
                FoodItem(emoji: "🫙", name: "Cottage Cheese (150g)", portionNote: "High protein side", protein: 18, carbs: 4),
            ]
        case .dinner:
            return [
                FoodItem(emoji: "🥩", name: "Steak (200g)", portionNote: "Ribeye or sirloin", protein: 46, carbs: 0),
                FoodItem(emoji: "🥦", name: "Broccoli + Zucchini", portionNote: "2 cups, steamed", protein: 5, carbs: 12),
                FoodItem(emoji: "🍳", name: "3 Eggs + Egg Whites", portionNote: "Scrambled as side", protein: 22, carbs: 1),
                FoodItem(emoji: "🍠", name: "Sweet Potato (small)", portionNote: "If training day", protein: 2, carbs: 20),
            ]
        case .snack:
            return [
                FoodItem(emoji: "🫙", name: "Greek Yogurt (150g)", portionNote: "With a handful of nuts", protein: 14, carbs: 6),
                FoodItem(emoji: "🥜", name: "Mixed Nuts (30g)", portionNote: "Almonds, cashews", protein: 5, carbs: 6),
                FoodItem(emoji: "🧀", name: "Cottage Cheese (100g)", portionNote: "Late-night protein", protein: 12, carbs: 3),
                FoodItem(emoji: "🥚", name: "Hard-boiled Eggs (2)", portionNote: "With salt + pepper", protein: 12, carbs: 0),
            ]
        }
    }
}

#Preview {
    MealDetailSheet(meal: Meal(
        timing: .postWorkout,
        scheduledTime: .now,
        macros: .postWorkout(for: .bjj)
    ))
    .environmentObject(PlannerStore())
    .environmentObject(SettingsStore())
}
