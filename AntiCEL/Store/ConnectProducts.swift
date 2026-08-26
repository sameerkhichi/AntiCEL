import Foundation

enum ConnectProductID: String, CaseIterable, Identifiable {
    case lifetime = "connect.lifetime"
    case monthly = "connect.monthly"
    case yearly = "connect.yearly"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .lifetime: return "Lifetime"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }

    var subtitle: String? {
        switch self {
        case .lifetime: return nil
        case .monthly: return "Want to try Connect out a little longer?"
        case .yearly: return "Save over $25 a year!"
        }
    }

    var fallbackPrice: String {
        switch self {
        case .lifetime: return "$24.99"
        case .monthly: return "$3.99"
        case .yearly: return "$19.99"
        }
    }

    var periodLabel: String {
        switch self {
        case .lifetime: return "ONE TIME"
        case .monthly: return "per month"
        case .yearly: return "per year"
        }
    }

    var isRecommended: Bool {
        self == .lifetime
    }
}

enum ConnectAccessStatus: Equatable {
    case notStarted
    case trial(daysRemaining: Int, endsAt: Date)
    case subscribed(productID: String, expiresAt: Date?, willAutoRenew: Bool)
    case lifetime
    case expired
}
