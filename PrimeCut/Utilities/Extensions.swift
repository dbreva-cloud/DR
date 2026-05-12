import SwiftUI

// MARK: - View modifiers
extension View {
    func primeCutCard(padding: CGFloat = Theme.spacingMD) -> some View {
        self
            .padding(padding)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLarge))
            .shadow(color: Theme.cardShadow, radius: 12, x: 0, y: 4)
    }

    func cardBorder() -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: Theme.radiusLarge)
                .strokeBorder(Theme.separator, lineWidth: 0.5)
        )
    }

    func scaleOnPress() -> some View {
        self.buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Button style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

// MARK: - Date helpers
extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var hourMinuteString: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: self)
    }

    var weekdayShort: String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: self)
    }

    func adding(hours: Double) -> Date {
        addingTimeInterval(hours * 3600)
    }

    func adding(minutes: Double) -> Date {
        addingTimeInterval(minutes * 60)
    }

    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }
}

// MARK: - Number formatting
extension Double {
    var stepString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: self)) ?? "\(Int(self))"
    }

    var percentString: String { "\(Int(self * 100))%" }
    var gramString: String { "\(Int(self))g" }
}

// MARK: - Animation presets
extension Animation {
    static let springSnappy = Animation.spring(response: 0.35, dampingFraction: 0.75)
    static let springBouncy = Animation.spring(response: 0.45, dampingFraction: 0.65)
    static let smooth = Animation.easeInOut(duration: 0.3)
    static let smoothSlow = Animation.easeInOut(duration: 0.55)
}
