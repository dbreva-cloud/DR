import SwiftUI
import Charts

struct StepBarChart: View {
    let entries: [ProgressEntry]
    let goal: Double
    let accentColor: Color

    @State private var appeared = false

    var body: some View {
        Chart {
            ForEach(entries) { entry in
                BarMark(
                    x: .value("Day", entry.weekday),
                    y: .value("Steps", appeared ? entry.steps : 0)
                )
                .foregroundStyle(
                    entry.steps >= goal
                        ? LinearGradient(colors: [accentColor, accentColor.opacity(0.6)],
                                          startPoint: .top, endPoint: .bottom)
                        : LinearGradient(colors: [Theme.textTertiary.opacity(0.5), Theme.textTertiary.opacity(0.2)],
                                          startPoint: .top, endPoint: .bottom)
                )
                .cornerRadius(4)
            }

            // Goal line
            RuleMark(y: .value("Goal", goal))
                .foregroundStyle(accentColor.opacity(0.6))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5]))
                .annotation(position: .trailing) {
                    Text("Goal")
                        .font(.caption)
                        .foregroundStyle(accentColor.opacity(0.8))
                }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisGridLine()
                    .foregroundStyle(Theme.separator)
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text(v >= 1000 ? "\(Int(v / 1000))k" : "\(Int(v))")
                            .font(.caption)
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let s = value.as(String.self) {
                        Text(s)
                            .font(.caption)
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
            }
        }
        .animation(.smoothSlow, value: appeared)
        .onAppear {
            withAnimation(.smoothSlow.delay(0.2)) { appeared = true }
        }
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        StepBarChart(entries: ProgressData.sample().entries, goal: 8000, accentColor: Theme.accent)
            .frame(height: 140)
            .padding()
    }
}
