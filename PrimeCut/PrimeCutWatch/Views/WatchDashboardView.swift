import SwiftUI

struct WatchDashboardView: View {
    @EnvironmentObject var store: WatchStore

    private var snap: SharedAppSnapshot { store.snapshot }
    private var progress: Double { min(snap.stepCount / max(snap.stepGoal, 1), 1.0) }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                // App name
                Text("PRIME CUT")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(Color(hex: "#4CAF72"))
                    .kerning(1.5)

                // Step ring
                WatchRingView(progress: progress, steps: snap.stepCount, goal: snap.stepGoal)

                // Steps remaining
                let remaining = max(snap.stepGoal - snap.stepCount, 0)
                if remaining > 0 {
                    Text("\(Int(remaining).formatted()) to go")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "#8E8E93"))
                } else {
                    Label("Goal hit!", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(hex: "#4CAF72"))
                }

                Divider()

                // Streak
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.orange)
                    Text("\(snap.streakCount) day streak")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: "#F5F5F5"))
                }

                // Checklist mini
                VStack(alignment: .leading, spacing: 4) {
                    let checked = snap.checklistItems.filter(\.isChecked).count
                    Text("\(checked)/\(snap.checklistItems.count) done")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "#8E8E93"))
                    // Mini bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3).fill(Color(hex: "#1C1C1E")).frame(height: 6)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(hex: "#4CAF72"))
                                .frame(width: geo.size.width * Double(checked) / Double(max(snap.checklistItems.count, 1)),
                                       height: 6)
                        }
                    }
                    .frame(height: 6)
                }
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle("Dashboard")
        .onTapGesture { store.refresh() }
    }
}
