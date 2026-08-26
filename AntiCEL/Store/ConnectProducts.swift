import Foundation

enum ConnectProductID: String, CaseIterable, Identifiable {
    case monthly = "connect.monthly"
    case yearly = "connect.yearly"
    case lifetime = "connect.lifetime"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        case .lifetime: return "Lifetime"
        }
    }

    var subtitle: String {
        switch self {
        case .monthly: return "Month to month, if you want a little more time before a longer plan."
        case .yearly: return "A full year of Connect, billed once."
        case .lifetime: return "Pay once. Keep Connect on this Apple ID."
        }
    }

    var fallbackPrice: String {
        switch self {
        case .monthly: return "$3.99"
        case .yearly: return "$24.99"
        case .lifetime: return "$29.99"
        }
    }

    var periodLabel: String {
        switch self {
        case .monthly: return "per month"
        case .yearly: return "per year"
        case .lifetime: return "one time"
        }
    }

    var isRecommended: Bool {
        self == .yearly || self == .lifetime
    }
}

enum ConnectAccessStatus: Equatable {
    case notStarted
    case trial(daysRemaining: Int, endsAt: Date)
    case subscribed(productID: String, expiresAt: Date?, willAutoRenew: Bool)
    case lifetime
    case expired
}
