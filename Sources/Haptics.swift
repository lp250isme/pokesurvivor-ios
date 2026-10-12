import UIKit

@MainActor
enum Haptics {
    private static let key = "haptics.enabled"

    static func tap() {
        guard UserDefaults.standard.object(forKey: key) as? Bool ?? true else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func select() {
        guard UserDefaults.standard.object(forKey: key) as? Bool ?? true else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func warn() {
        guard UserDefaults.standard.object(forKey: key) as? Bool ?? true else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
