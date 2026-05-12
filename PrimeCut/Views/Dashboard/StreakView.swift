import SwiftUI

struct StreakView: View {
    let count: Int
    let accentGradient: LinearGradient

    @State private var pulseOpacity: Double = 0.0
    @State private var ringScale: CGFloat = 1.0
    @State private var appeared = false

    var body: some View {
        HStack(spacing: Theme.spacingMD) {
            // Flame icon with pulse
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15 * pulseOpacity))
                    .frame(width: 52, height: 52)
                    .scaleEffect(ringScale)

                Image(systemName: "flame.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .yellow],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(count)")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                        .contentTransition(.numericText())

                    Text("day streak")
                        .font(.titleMedium)
                        .foregroundStyle(Theme.textSecondary)
                }
                Text(count == 0 ? "Complete today to start your streak" : streakMessage)
                    .font(.bodyMedium)
                    .foregroundStyle(Theme.textTertiary)
            }
            Spacer()
        }
        .primeCutCard()
        .cardBorder()
        .onAppear {
            guard !appeared else { return }
            appeared = true
            if count > 0 { startPulse() }
        }
        .onChange(of: count) { old, new in
            if new > old { pulseOnNewStreak() }
        }
    }

    private var streakMessage: String {
        switch count {
        case 1:     return "Good start. Keep it going."
        case 2...6: return "Building momentum — stay consistent."
        case 7...13: return "One week strong. Don't break it."
        case 14...29: return "Two weeks locked in. Elite level."
        default:    return "\(count) days straight. Unstoppable."
        }
    }

    private func startPulse() {
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
            pulseOpacity = 1.0
            ringScale = 1.3
        }
    }

    private func pulseOnNewStreak() {
        withAnimation(.springBouncy) { ringScale = 1.5 }
        withAnimation(.springBouncy.delay(0.15)) { ringScale = 1.0 }
        if count > 0 { startPulse() }
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        VStack {
            StreakView(count: 12, accentGradient: Theme.accentGradient)
            StreakView(count: 0,  accentGradient: Theme.accentGradient)
        }
        .padding()
    }
}
