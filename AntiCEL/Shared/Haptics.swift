import UIKit

enum AppHaptic {
    /// Sharp click used for vehicle cards and the bottom tab bar.
    case flashlight
    /// Lighter tap used when More Haptics is on.
    case button

    func play() {
        let settings = AppSettings.shared
        guard settings.hapticsEnabled else { return }

        switch self {
        case .flashlight:
            Self.rigid.prepare()
            Self.rigid.impactOccurred(intensity: 1.0)
        case .button:
            guard settings.moreHaptics else { return }
            Self.light.prepare()
            Self.light.impactOccurred(intensity: 0.75)
        }
    }

    private static let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private static let light = UIImpactFeedbackGenerator(style: .light)
}
