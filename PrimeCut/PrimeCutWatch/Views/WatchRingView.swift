import SwiftUI

struct WatchRingView: View {
    let progress: Double
    let steps: Double
    let goal: Double

    @State private var animatedProgress: Double = 0

    private let diameter: CGFloat = 100
    private let lineWidth: CGFloat = 10

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(Color(hex: "#1C1C1E"), lineWidth: lineWidth)
                .frame(width: diameter, height: diameter)

            // Progress arc
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    LinearGradient(
                        colors: [Color(hex: "#4CAF72"), Color(hex: "#2D8B52")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: diameter, height: diameter)
                .rotationEffect(.degrees(-90))

            // Center label
            VStack(spacing: 1) {
                Text(stepsShort)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: "#F5F5F5"))
                Text("steps")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Color(hex: "#8E8E93"))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, new in
            withAnimation(.easeInOut(duration: 0.4)) { animatedProgress = new }
        }
    }

    private var stepsShort: String {
        steps >= 1000 ? String(format: "%.1fk", steps / 1000) : "\(Int(steps))"
    }
}

extension Color {
    // Duplicate for Watch target (no shared module)
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double( int        & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b)
    }
}
