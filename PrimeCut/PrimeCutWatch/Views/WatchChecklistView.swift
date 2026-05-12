import SwiftUI
import WatchKit

struct WatchChecklistView: View {
    @EnvironmentObject var store: WatchStore

    var body: some View {
        List {
            ForEach(store.snapshot.checklistItems, id: \.label) { item in
                WatchChecklistRow(item: item)
            }
        }
        .navigationTitle("Checklist")
        .listStyle(.carousel)
    }
}

// MARK: - Row
private struct WatchChecklistRow: View {
    let item: SharedAppSnapshot.ChecklistSnapshot

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(item.isChecked ? Color(hex: "#4CAF72") : Color(hex: "#48484A"))
                .scaleEffect(item.isChecked ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: item.isChecked)

            Text(item.label)
                .font(.system(size: 15, weight: item.isChecked ? .regular : .semibold))
                .foregroundStyle(item.isChecked ? Color(hex: "#48484A") : Color(hex: "#F5F5F5"))
                .strikethrough(item.isChecked, color: Color(hex: "#48484A"))
        }
        .padding(.vertical, 4)
    }
}
