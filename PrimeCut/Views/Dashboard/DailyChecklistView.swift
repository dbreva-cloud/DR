import SwiftUI

struct DailyChecklistView: View {
    @EnvironmentObject var store: PlannerStore
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            Text("Today's Checklist")
                .font(.titleMedium)
                .foregroundStyle(Theme.textPrimary)

            VStack(spacing: 6) {
                ForEach(store.todayPlan.checklist) { item in
                    ChecklistRow(item: item, accentColor: settings.accentColor) {
                        store.toggleChecklist(id: item.id)
                    }
                }
            }
        }
        .primeCutCard()
        .cardBorder()
    }
}

// MARK: - Row
private struct ChecklistRow: View {
    let item: ChecklistItem
    let accentColor: Color
    let onTap: () -> Void

    @State private var checkScale: CGFloat = 1.0
    @State private var rowOffset: CGFloat = 0

    var body: some View {
        Button(action: {
            onTap()
            animateCheck()
        }) {
            HStack(spacing: 12) {
                // Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(item.isChecked ? accentColor : Theme.separator, lineWidth: 1.5)
                        .frame(width: 24, height: 24)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(item.isChecked ? accentColor.opacity(0.15) : Color.clear)
                        )

                    if item.isChecked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(accentColor)
                            .scaleEffect(checkScale)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.springBouncy, value: item.isChecked)

                // Label
                Text(item.label)
                    .font(.bodyLarge)
                    .foregroundStyle(item.isChecked ? Theme.textSecondary : Theme.textPrimary)
                    .strikethrough(item.isChecked, color: Theme.textTertiary)
                    .animation(.smooth, value: item.isChecked)

                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .offset(x: rowOffset)
    }

    private func animateCheck() {
        withAnimation(.springBouncy) { checkScale = 1.3 }
        withAnimation(.springBouncy.delay(0.1)) { checkScale = 1.0 }
        // Subtle nudge right on check
        withAnimation(.spring(response: 0.2)) { rowOffset = 4 }
        withAnimation(.spring(response: 0.3).delay(0.1)) { rowOffset = 0 }
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        DailyChecklistView()
            .environmentObject(PlannerStore())
            .environmentObject(SettingsStore())
            .padding()
    }
}
