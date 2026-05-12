import SwiftUI
import WidgetKit

// MARK: - Small: Step ring
struct SmallStepRingWidget: View {
    let entry: PrimeCutEntry

    private var progress: Double {
        min(entry.snapshot.stepCount / max(entry.snapshot.stepGoal, 1), 1.0)
    }

    var body: some View {
        ZStack {
            Color(hex: "#0B0B0B")

            VStack(spacing: 6) {
                // Ring
                ZStack {
                    Circle()
                        .stroke(Color(hex: "#1C1C1E"), lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "#4CAF72"), Color(hex: "#2D8B52")],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 1) {
                        Text(stepsLabel)
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(Color(hex: "#F5F5F5"))
                        Text("steps")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Color(hex: "#8E8E93"))
                    }
                }
                .frame(width: 88, height: 88)

                // Streak pill
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.orange)
                    Text("\(entry.snapshot.streakCount)d")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color(hex: "#F5F5F5"))
                }
            }
        }
    }

    private var stepsLabel: String {
        let k = entry.snapshot.stepCount
        return k >= 1000 ? String(format: "%.1fk", k / 1000) : "\(Int(k))"
    }
}

// MARK: - Medium: Steps + checklist
struct MediumWidget: View {
    let entry: PrimeCutEntry

    private var progress: Double {
        min(entry.snapshot.stepCount / max(entry.snapshot.stepGoal, 1), 1.0)
    }

    var body: some View {
        HStack(spacing: 16) {
            // Left: ring
            ZStack {
                Circle()
                    .stroke(Color(hex: "#1C1C1E"), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: "#4CAF72"), Color(hex: "#2D8B52")],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 1) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(Color(hex: "#F5F5F5"))
                    Text("steps")
                        .font(.system(size: 8))
                        .foregroundStyle(Color(hex: "#8E8E93"))
                }
            }
            .frame(width: 80, height: 80)

            // Right: checklist
            VStack(alignment: .leading, spacing: 4) {
                Text("TODAY")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(Color(hex: "#4CAF72"))
                    .kerning(1.5)

                ForEach(entry.snapshot.checklistItems.prefix(4), id: \.label) { item in
                    HStack(spacing: 5) {
                        Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 10))
                            .foregroundStyle(item.isChecked ? Color(hex: "#4CAF72") : Color(hex: "#48484A"))
                        Text(item.label)
                            .font(.system(size: 11, weight: item.isChecked ? .regular : .medium))
                            .foregroundStyle(item.isChecked ? Color(hex: "#48484A") : Color(hex: "#F5F5F5"))
                            .strikethrough(item.isChecked, color: Color(hex: "#48484A"))
                    }
                }
            }
            Spacer()
        }
        .padding(14)
        .background(Color(hex: "#0B0B0B"))
    }
}

// MARK: - Large: Full dashboard snapshot
struct LargeWidget: View {
    let entry: PrimeCutEntry

    private var progress: Double {
        min(entry.snapshot.stepCount / max(entry.snapshot.stepGoal, 1), 1.0)
    }

    private var checkedCount: Int {
        entry.snapshot.checklistItems.filter(\.isChecked).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("PRIME CUT")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(Color(hex: "#4CAF72"))
                    .kerning(2)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.orange)
                    Text("\(entry.snapshot.streakCount) day streak")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color(hex: "#F5F5F5"))
                }
            }

            // Steps progress bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(Int(entry.snapshot.stepCount).formatted()) steps")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(Color(hex: "#F5F5F5"))
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(hex: "#4CAF72"))
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4).fill(Color(hex: "#1C1C1E")).frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient(
                                colors: [Color(hex: "#4CAF72"), Color(hex: "#2D8B52")],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(width: geo.size.width * progress, height: 8)
                    }
                }
                .frame(height: 8)
            }

            Divider().background(Color(hex: "#2C2C2E"))

            // Checklist
            VStack(alignment: .leading, spacing: 5) {
                Text("Checklist  \(checkedCount)/\(entry.snapshot.checklistItems.count)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color(hex: "#8E8E93"))
                ForEach(entry.snapshot.checklistItems, id: \.label) { item in
                    HStack(spacing: 6) {
                        Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 12))
                            .foregroundStyle(item.isChecked ? Color(hex: "#4CAF72") : Color(hex: "#48484A"))
                        Text(item.label)
                            .font(.system(size: 12, weight: item.isChecked ? .regular : .medium))
                            .foregroundStyle(item.isChecked ? Color(hex: "#48484A") : Color(hex: "#F5F5F5"))
                            .strikethrough(item.isChecked, color: Color(hex: "#48484A"))
                    }
                }
            }
        }
        .padding(16)
        .background(Color(hex: "#0B0B0B"))
    }
}

// MARK: - Color hex (duplicated in widget target — no shared module)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

#Preview("Small", as: .systemSmall) {
    PrimeCutWidget()
} timeline: {
    PrimeCutEntry.placeholder()
}

#Preview("Medium", as: .systemMedium) {
    PrimeCutWidget()
} timeline: {
    PrimeCutEntry.placeholder()
}

#Preview("Large", as: .systemLarge) {
    PrimeCutWidget()
} timeline: {
    PrimeCutEntry.placeholder()
}
