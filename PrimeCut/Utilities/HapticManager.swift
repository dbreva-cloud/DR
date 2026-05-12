import UIKit

enum HapticManager {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    static func checkmark() {
        impact(.rigid)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            impact(.light)
        }
    }

    static func streak() {
        notification(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            impact(.heavy)
        }
    }
}
