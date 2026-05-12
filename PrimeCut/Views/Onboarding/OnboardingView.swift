import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var healthKit: HealthKitManager

    @State private var currentStep = 0
    @State private var userName  = ""
    @State private var primaryActivity: PrimaryActivity = .both
    @State private var selectedStepGoal: Double = 8000
    @State private var slideOffset: CGFloat = 0
    @State private var opacity: Double = 1

    private let totalSteps = 5

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            // Background gradient pulse
            RadialGradient(
                colors: [settings.accentColor.opacity(0.08), Theme.background],
                center: .center,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: currentStep)

            VStack(spacing: 0) {
                // Progress dots
                progressDots
                    .padding(.top, 60)
                    .padding(.bottom, 32)

                // Step content
                ZStack {
                    stepView(for: currentStep)
                        .offset(x: slideOffset)
                        .opacity(opacity)
                }
                .frame(maxHeight: .infinity)

                // Navigation buttons
                navigationButtons
                    .padding(.horizontal, Theme.spacingLG)
                    .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Progress dots
    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { i in
                Capsule()
                    .fill(i <= currentStep ? settings.accentColor : Theme.surfaceHigh)
                    .frame(width: i == currentStep ? 24 : 8, height: 8)
                    .animation(.springSnappy, value: currentStep)
            }
        }
    }

    // MARK: - Steps
    @ViewBuilder
    private func stepView(for step: Int) -> some View {
        switch step {
        case 0: welcomeStep
        case 1: nameStep
        case 2: activityStep
        case 3: stepGoalStep
        case 4: permissionsStep
        default: welcomeStep
        }
    }

    // MARK: - Step 0: Welcome
    private var welcomeStep: some View {
        VStack(spacing: Theme.spacingLG) {
            // Logo mark
            ZStack {
                Circle()
                    .fill(settings.accentGradient)
                    .frame(width: 100, height: 100)
                    .shadow(color: settings.accentColor.opacity(0.4), radius: 20)
                Image(systemName: "bolt.fill")
                    .font(.system(size: 44, weight: .black))
                    .foregroundStyle(.white)
            }
            .scaleEffect(currentStep == 0 ? 1.0 : 0.8)
            .animation(.springBouncy.delay(0.1), value: currentStep)

            VStack(spacing: Theme.spacingSM) {
                Text("PRIME CUT")
                    .font(.system(size: 32, weight: .black))
                    .foregroundStyle(Theme.textPrimary)
                    .kerning(4)
                Text("Metabolic priming for\nserious athletes.")
                    .font(.titleMedium)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            VStack(spacing: 10) {
                featurePill(icon: "bolt.fill", text: "Auto meal timing around your training")
                featurePill(icon: "figure.martial.arts", text: "Built for BJJ, lifting, and walking")
                featurePill(icon: "heart.fill", text: "Adapts to recovery and step count")
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, Theme.spacingLG)
        .multilineTextAlignment(.center)
    }

    private func featurePill(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(settings.accentColor)
                .frame(width: 20)
            Text(text)
                .font(.bodyMedium)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))
        .overlay(RoundedRectangle(cornerRadius: Theme.radiusMedium).strokeBorder(Theme.separator, lineWidth: 0.5))
    }

    // MARK: - Step 1: Name
    private var nameStep: some View {
        VStack(spacing: Theme.spacingLG) {
            stepHeader(
                icon: "person.fill",
                title: "What should we\ncall you?",
                subtitle: "Optional — for personalized messages"
            )

            VStack(alignment: .leading, spacing: 8) {
                TextField("Your name", text: $userName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .tint(settings.accentColor)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.radiusMedium)
                            .strokeBorder(userName.isEmpty ? Theme.separator : settings.accentColor, lineWidth: 1.5)
                    )
            }
            .padding(.horizontal, Theme.spacingLG)
        }
        .padding(.horizontal, Theme.spacingMD)
    }

    // MARK: - Step 2: Activity
    private var activityStep: some View {
        VStack(spacing: Theme.spacingLG) {
            stepHeader(
                icon: "figure.strengthtraining.traditional",
                title: "Primary activity?",
                subtitle: "Sets your default macro approach"
            )

            VStack(spacing: 10) {
                ForEach(PrimaryActivity.allCases) { activity in
                    Button {
                        withAnimation(.springSnappy) { primaryActivity = activity }
                        HapticManager.selection()
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(primaryActivity == activity
                                          ? activity.color.opacity(0.2) : Theme.surfaceHigh)
                                    .frame(width: 48, height: 48)
                                Image(systemName: activity.icon)
                                    .font(.system(size: 20))
                                    .foregroundStyle(primaryActivity == activity ? activity.color : Theme.textTertiary)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(activity.rawValue)
                                    .font(.bodyLarge).fontWeight(.semibold)
                                    .foregroundStyle(Theme.textPrimary)
                                Text(activity.detail)
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                            if primaryActivity == activity {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(activity.color)
                            }
                        }
                        .padding(14)
                        .background(primaryActivity == activity
                                    ? activity.color.opacity(0.06) : Theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLarge))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.radiusLarge)
                                .strokeBorder(primaryActivity == activity ? activity.color.opacity(0.4) : Theme.separator,
                                              lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(primaryActivity == activity ? 1.02 : 1.0)
                    .animation(.springSnappy, value: primaryActivity)
                }
            }
            .padding(.horizontal, Theme.spacingLG)
        }
        .padding(.horizontal, Theme.spacingMD)
    }

    // MARK: - Step 3: Step goal
    private var stepGoalStep: some View {
        VStack(spacing: Theme.spacingLG) {
            stepHeader(
                icon: "figure.walk",
                title: "Daily step goal?",
                subtitle: "Auto Mode adjusts carbs around this target"
            )

            VStack(spacing: 12) {
                // Big display
                Text(selectedStepGoal.stepString)
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundStyle(settings.accentColor)
                    .contentTransition(.numericText())
                Text("steps per day")
                    .font(.titleMedium)
                    .foregroundStyle(Theme.textSecondary)

                // Slider
                Slider(value: $selectedStepGoal, in: 3000...20000, step: 500)
                    .tint(settings.accentColor)
                    .padding(.horizontal, Theme.spacingLG)
                    .onChange(of: selectedStepGoal) { _, _ in HapticManager.selection() }

                // Quick picks
                HStack(spacing: 8) {
                    ForEach([5000.0, 8000, 10000, 12000], id: \.self) { goal in
                        Button {
                            withAnimation(.springSnappy) { selectedStepGoal = goal }
                            HapticManager.impact(.light)
                        } label: {
                            Text(goal == 10000 ? "10k" : "\(Int(goal / 1000))k")
                                .font(.labelLarge)
                                .foregroundStyle(selectedStepGoal == goal ? .white : Theme.textSecondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(selectedStepGoal == goal ? settings.accentColor : Theme.surface)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .animation(.springSnappy, value: selectedStepGoal)
                    }
                }
            }
            .padding(.horizontal, Theme.spacingMD)
        }
        .padding(.horizontal, Theme.spacingMD)
    }

    // MARK: - Step 4: Permissions
    private var permissionsStep: some View {
        VStack(spacing: Theme.spacingLG) {
            stepHeader(
                icon: "lock.shield.fill",
                title: "Two quick things",
                subtitle: "Enable for the full experience"
            )

            VStack(spacing: 12) {
                // HealthKit
                PermissionRow(
                    icon: "heart.fill",
                    iconColor: .red,
                    title: "Apple Health",
                    subtitle: "Step count for ring + Auto Mode",
                    isGranted: healthKit.isAuthorized
                ) {
                    Task { await healthKit.requestAuthorization() }
                }

                // Notifications
                PermissionRow(
                    icon: "bell.fill",
                    iconColor: .yellow,
                    title: "Notifications",
                    subtitle: "Meal reminders + recovery nudges",
                    isGranted: settings.notificationsOn
                ) {
                    Task {
                        let granted = await NotificationManager.shared.requestAuthorization()
                        settings.notificationsOn = granted
                    }
                }
            }
            .padding(.horizontal, Theme.spacingMD)

            Text("You can change these anytime in Settings.")
                .font(.caption)
                .foregroundStyle(Theme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Theme.spacingMD)
    }

    // MARK: - Navigation buttons
    private var navigationButtons: some View {
        HStack(spacing: 14) {
            // Back
            if currentStep > 0 {
                Button { transition(to: currentStep - 1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 52, height: 52)
                        .background(Theme.surface)
                        .clipShape(Circle())
                }
                .buttonStyle(ScaleButtonStyle())
            }

            // Next / Finish
            Button {
                if currentStep < totalSteps - 1 {
                    transition(to: currentStep + 1)
                } else {
                    finishOnboarding()
                }
            } label: {
                HStack {
                    Text(currentStep == totalSteps - 1 ? "Let's Go" : "Continue")
                        .fontWeight(.bold)
                    Image(systemName: currentStep == totalSteps - 1 ? "bolt.fill" : "chevron.right")
                }
                .font(.bodyLarge)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(settings.accentGradient)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }

    // MARK: - Helpers
    private func stepHeader(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: Theme.spacingSM) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(settings.accentColor)
                .padding(.bottom, 4)
            Text(title)
                .font(.displayMedium)
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
            Text(subtitle)
                .font(.bodyLarge)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Theme.spacingMD)
    }

    private func transition(to step: Int) {
        let forward = step > currentStep
        withAnimation(.smooth) {
            slideOffset = forward ? 60 : -60
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            currentStep = step
            slideOffset = forward ? -60 : 60
            withAnimation(.springSnappy) {
                slideOffset = 0
                opacity = 1
            }
        }
        HapticManager.impact(.light)
    }

    private func finishOnboarding() {
        settings.stepGoal = selectedStepGoal
        if !userName.isEmpty {
            settings.userName = userName
        }
        settings.primaryActivity = primaryActivity.rawValue
        withAnimation(.springSnappy) {
            settings.onboardingComplete = true
        }
        HapticManager.notification(.success)
    }
}

// MARK: - Permission row
private struct PermissionRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let isGranted: Bool
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(iconColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.bodyLarge).fontWeight(.semibold).foregroundStyle(Theme.textPrimary)
                Text(subtitle).font(.caption).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            if isGranted {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.accent)
            } else {
                Button("Enable", action: onTap)
                    .font(.labelLarge)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Theme.accentGradient)
                    .clipShape(Capsule())
            }
        }
        .padding(14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLarge))
        .overlay(RoundedRectangle(cornerRadius: Theme.radiusLarge).strokeBorder(Theme.separator, lineWidth: 0.5))
    }
}

// MARK: - Primary activity type
enum PrimaryActivity: String, CaseIterable, Identifiable {
    case bjj      = "Brazilian Jiu-Jitsu"
    case lifting  = "Strength Training"
    case both     = "BJJ + Lifting"
    case walking  = "Walking / General Fitness"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .bjj:     return "figure.martial.arts"
        case .lifting: return "dumbbell.fill"
        case .both:    return "bolt.fill"
        case .walking: return "figure.walk"
        }
    }

    var color: Color {
        switch self {
        case .bjj:     return Theme.bjjColor
        case .lifting: return Theme.strengthColor
        case .both:    return Theme.accent
        case .walking: return .blue
        }
    }

    var detail: String {
        switch self {
        case .bjj:     return "High carb around sessions, protein focus"
        case .lifting: return "Balanced macros, strength-focused"
        case .both:    return "Flexible — adapts per session type"
        case .walking: return "Moderate carbs, steady protein"
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(SettingsStore())
        .environmentObject(HealthKitManager())
}
