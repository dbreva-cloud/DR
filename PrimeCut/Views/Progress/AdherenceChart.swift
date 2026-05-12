import SwiftUI
import Charts

struct AdherenceLineChart: View {
    let entries: [ProgressEntry]
    let accentColor: Color

    @State private var appeared = false

    var body: some View {
        Chart {
            ForEach(Array(entries.enumerated()), id: \.offset) { idx, entry in
                LineMark(
                    x: .value("Day", entry.weekday),
                    y: .value("Adherence", appeared ? entry.adherencePercent * 100 : 0)
                )
                .foregroundStyle(accentColor)
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Day", entry.weekday),
                    y: .value("Adherence", appeared ? entry.adherencePercent * 100 : 0)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [accentColor.opacity(0.3), accentColor.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Day", entry.weekday),
                    y: .value("Adherence", appeared ? entry.adherencePercent * 100 : 0)
                )
                .foregroundStyle(accentColor)
                .symbolSize(30)
            }

            // 100% goal line
            RuleMark(y: .value("Goal", 100))
                .foregroundStyle(Theme.textTertiary.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                .annotation(position: .trailing) {
                    Text("100%")
                        .font(.caption)
                        .foregroundStyle(Theme.textTertiary)
                }
        }
        .chartYScale(domain: 0...110)
        .chartYAxis {
            AxisMarks(values: [0, 50, 100]) { value in
                AxisGridLine()
                    .foregroundStyle(Theme.separator)
                AxisValueLabel {
                    if let v = value.as(Int.self) {
                        Text("\(v)%")
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
            withAnimation(.smoothSlow.delay(0.15)) { appeared = true }
        }
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        AdherenceLineChart(entries: ProgressData.sample().entries, accentColor: Theme.accent)
            .frame(height: 140)
            .padding()
    }
}
