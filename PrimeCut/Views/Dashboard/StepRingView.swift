import SwiftUI

struct StepRingView: View {
    let steps: Double
    let goal: Double
    let accentGradient: LinearGradient

    @State private var animatedProgress: Double = 0
    @State private var pulseScale: CGFloat = 1.0

    private var progress: Double { min(steps / max(goal, 1), 1.0) }
    private let ringWidth: CGFloat = 16
    private let diameter: CGFloat  = 160

    var body: some View {
        ZStack {
            // Track ring
            Circle()
                .stroke(Theme.surfaceHigh, lineWidth: ringWidth)
                .frame(width: diameter, height: diameter)

            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    accentGradient,
                    style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                )
                .frame(width: diameter, height: diameter)
                .rotationEffect(.degrees(-90))
                .shadow(color: Color(hex: "#4CAF72").opacity(0.4), radius: 8, x: 0, y: 0)

            // Tip glow dot
            if animatedProgress > 0.01 {
                tipDot
            }

            // Center content
            centerLabel
        }
        .onAppear {
            withAnimation(.smoothSlow.delay(0.2)) {
                animatedProgress = progress
            }
            startPulse()
        }
        .onChange(of: steps) { _, _ in
            withAnimation(.springSnappy) {
                animatedProgress = progress
            }
        }
    }

    // MARK: - Tip dot
    private var tipDot: some View {
        let angle = Angle.degrees(animatedProgress * 360 - 90)
        let radius = diameter / 2
        let x = radius * CGFloat(cos(angle.radians))
        let y = radius * CGFloat(sin(angle.radians))
        return Circle()
            .fill(Color(hex: "#4CAF72"))
            .frame(width: ringWidth, height: ringWidth)
            .shadow(color: Color(hex: "#4CAF72").opacity(0.8), radius: 6)
            .offset(x: x, y: y)
    }

    // MARK: - Center label
    private var centerLabel: some View {
        VStack(spacing: 2) {
            Text(steps.stepString)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .scaleEffect(pulseScale)

            Text("of \(goal.stepString)")
                .font(.labelSmall)
                .foregroundStyle(Theme.textSecondary)

            Text("steps")
                .font(.caption)
                .foregroundStyle(Theme.textTertiary)
        }
    }

    private func startPulse() {
        guard progress >= 1.0 else { return }
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            pulseScale = 1.06
        }
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        StepRingView(steps: 6200, goal: 8000, accentGradient: Theme.accentGradient)
    }
}
