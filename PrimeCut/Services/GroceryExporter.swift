import Foundation
import UIKit

struct GroceryItem: Identifiable {
    var id = UUID()
    var name: String
    var category: String
    var quantity: String
}

struct GroceryList {
    var items: [GroceryItem]
    var trainingDays: Int

    var grouped: [String: [GroceryItem]] {
        Dictionary(grouping: items, by: \.category)
    }

    func exportText() -> String {
        var lines = ["Prime Cut — Grocery List"]
        lines.append("Training days this week: \(trainingDays)")
        lines.append(String(repeating: "-", count: 32))

        let sorted = grouped.keys.sorted()
        for category in sorted {
            lines.append("\n\(category.uppercased())")
            for item in grouped[category] ?? [] {
                lines.append("• \(item.name) (\(item.quantity))")
            }
        }
        return lines.joined(separator: "\n")
    }

    // Export to Apple Notes via share sheet
    func shareAsNotes(from viewController: UIViewController? = nil) {
        let text = exportText()
        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        activityVC.excludedActivityTypes = [.postToFacebook, .postToTwitter, .postToWeibo]

        if let vc = viewController ?? UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first?.rootViewController {
            vc.present(activityVC, animated: true)
        }
    }
}

// MARK: - Generator
struct GroceryExporter {

    static func generate(from plans: [DayPlan]) -> GroceryList {
        let trainingDays = plans.filter { $0.workout?.type != .rest && $0.workout != nil }.count
        var items: [GroceryItem] = []

        // Proteins
        items.append(GroceryItem(name: "Chicken Breast", category: "Protein",
                                  quantity: "\(trainingDays * 2 + 2) servings"))
        items.append(GroceryItem(name: "Ground Beef (90% lean)", category: "Protein",
                                  quantity: "\(max(trainingDays, 2)) servings"))
        items.append(GroceryItem(name: "Eggs", category: "Protein",
                                  quantity: "2 dozen"))
        items.append(GroceryItem(name: "Greek Yogurt", category: "Protein",
                                  quantity: "1 large tub"))
        items.append(GroceryItem(name: "Cottage Cheese", category: "Protein",
                                  quantity: "2 containers"))

        // Carbs
        let highCarbDays = plans.filter { $0.workout?.type == .bjj }.count
        if highCarbDays > 0 {
            items.append(GroceryItem(name: "White Rice", category: "Carbs",
                                      quantity: "\(highCarbDays * 2) cups dry"))
            items.append(GroceryItem(name: "Oats", category: "Carbs", quantity: "1 bag"))
        }
        items.append(GroceryItem(name: "Sweet Potatoes", category: "Carbs",
                                  quantity: "\(trainingDays + 2) medium"))
        items.append(GroceryItem(name: "Bananas", category: "Carbs", quantity: "1 bunch"))

        // Fats
        items.append(GroceryItem(name: "Avocados", category: "Fats", quantity: "4–6"))
        items.append(GroceryItem(name: "Olive Oil", category: "Fats", quantity: "1 bottle"))
        items.append(GroceryItem(name: "Almonds / Mixed Nuts", category: "Fats", quantity: "1 bag"))

        // Vegetables
        items.append(GroceryItem(name: "Broccoli", category: "Vegetables", quantity: "2 heads"))
        items.append(GroceryItem(name: "Spinach", category: "Vegetables", quantity: "1 large bag"))
        items.append(GroceryItem(name: "Bell Peppers", category: "Vegetables", quantity: "6 peppers"))
        items.append(GroceryItem(name: "Zucchini", category: "Vegetables", quantity: "3 medium"))

        // Staples
        items.append(GroceryItem(name: "Kosher Salt", category: "Staples", quantity: "as needed"))
        items.append(GroceryItem(name: "Black Pepper", category: "Staples", quantity: "as needed"))
        items.append(GroceryItem(name: "Protein Powder (Whey)", category: "Staples",
                                  quantity: "\(trainingDays) servings"))

        return GroceryList(items: items, trainingDays: trainingDays)
    }
}
