import Foundation
import SwiftUI

enum MileageUnit: String, CaseIterable, Identifiable, Codable {
    case kilometers
    case miles

    var id: String { rawValue }

    var abbreviation: String {
        switch self {
        case .kilometers: return "km"
        case .miles: return "mi"
        }
    }

    var displayName: String {
        switch self {
        case .kilometers: return "Kilometers"
        case .miles: return "Miles"
        }
    }

    var accessibilityName: String {
        switch self {
        case .kilometers: return "kilometers"
        case .miles: return "miles"
        }
    }

    func displayValue(fromStoredKilometers kilometers: Int) -> Int {
        switch self {
        case .kilometers:
            return kilometers
        case .miles:
            return Int((Double(kilometers) * 0.621371192).rounded())
        }
    }

    func storedKilometers(fromDisplay value: Int) -> Int {
        switch self {
        case .kilometers:
            return value
        case .miles:
            return Int((Double(value) / 0.621371192).rounded())
        }
    }

    func formatted(_ storedKilometers: Int?) -> String {
        guard let storedKilometers else {
            return "Not Set"
        }

        return "\(displayValue(fromStoredKilometers: storedKilometers).formatted()) \(abbreviation)"
    }
}

enum NotificationLeadDays: Int, CaseIterable, Identifiable, Codable {
    case three = 3
    case seven = 7
    case fourteen = 14
    case thirty = 30

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .three: return "3 days"
        case .seven: return "7 days"
        case .fourteen: return "14 days"
        case .thirty: return "30 days"
        }
    }
}

enum NotificationLeadMileage: Int, CaseIterable, Identifiable, Codable {
    case oneHundred = 100
    case twoFifty = 250
    case fiveHundred = 500
    case oneThousand = 1000

    var id: Int { rawValue }

    func displayName(using unit: MileageUnit) -> String {
        "\(rawValue.formatted()) \(unit.abbreviation)"
    }
}

@Observable
final class AppSettings {
    static let shared = AppSettings()

    var lightAccent: AccentOption {
        didSet { defaults.set(lightAccent.rawValue, forKey: Keys.lightAccent) }
    }

    var darkAccent: AccentOption {
        didSet { defaults.set(darkAccent.rawValue, forKey: Keys.darkAccent) }
    }

    var mileageUnit: MileageUnit {
        didSet {
            defaults.set(mileageUnit.rawValue, forKey: Keys.mileageUnit)
            WidgetReloader.reload()
        }
    }

    var notifyServiceReminders: Bool {
        didSet { defaults.set(notifyServiceReminders, forKey: Keys.notifyService) }
    }

    var notifyExpiringDocuments: Bool {
        didSet { defaults.set(notifyExpiringDocuments, forKey: Keys.notifyDocuments) }
    }

    var notificationLeadDays: NotificationLeadDays {
        didSet { defaults.set(notificationLeadDays.rawValue, forKey: Keys.notificationLeadDays) }
    }

    var serviceNotificationLeadMileage: NotificationLeadMileage {
        didSet { defaults.set(serviceNotificationLeadMileage.rawValue, forKey: Keys.serviceNotificationLeadMileage) }
    }

    var documentNotificationLeadDays: NotificationLeadDays {
        didSet { defaults.set(documentNotificationLeadDays.rawValue, forKey: Keys.documentNotificationLeadDays) }
    }

    var lowStorageMode: Bool {
        didSet { defaults.set(lowStorageMode, forKey: Keys.lowStorageMode) }
    }

    var savePhotosInApp: Bool { !lowStorageMode }

    private let defaults: UserDefaults

    private init() {
        defaults = UserDefaults(suiteName: AppGroup.identifier) ?? .standard

        lightAccent = AccentOption(rawValue: defaults.string(forKey: Keys.lightAccent) ?? "") ?? .amber
        darkAccent = AccentOption(rawValue: defaults.string(forKey: Keys.darkAccent) ?? "") ?? .amberRed
        mileageUnit = MileageUnit(rawValue: defaults.string(forKey: Keys.mileageUnit) ?? "") ?? .kilometers
        notifyServiceReminders = defaults.object(forKey: Keys.notifyService) as? Bool ?? false
        notifyExpiringDocuments = defaults.object(forKey: Keys.notifyDocuments) as? Bool ?? false

        let lead = defaults.object(forKey: Keys.notificationLeadDays) as? Int
        notificationLeadDays = NotificationLeadDays(rawValue: lead ?? 7) ?? .seven

        let mileageLead = defaults.object(forKey: Keys.serviceNotificationLeadMileage) as? Int
        serviceNotificationLeadMileage = NotificationLeadMileage(rawValue: mileageLead ?? 500) ?? .fiveHundred

        if let documentLead = defaults.object(forKey: Keys.documentNotificationLeadDays) as? Int,
           let parsed = NotificationLeadDays(rawValue: documentLead) {
            documentNotificationLeadDays = parsed
        } else {
            documentNotificationLeadDays = notificationLeadDays
        }

        if defaults.object(forKey: Keys.lowStorageMode) != nil {
            lowStorageMode = defaults.bool(forKey: Keys.lowStorageMode)
        } else {
            let saveInApp = defaults.object(forKey: Keys.savePhotosInApp) as? Bool ?? true
            lowStorageMode = !saveInApp
        }
    }

    func accentOption(for scheme: ColorScheme) -> AccentOption {
        scheme == .dark ? darkAccent : lightAccent
    }

    func formattedMileage(_ storedKilometers: Int?) -> String {
        mileageUnit.formatted(storedKilometers)
    }

    private enum Keys {
        static let lightAccent = "settings.lightAccent"
        static let darkAccent = "settings.darkAccent"
        static let mileageUnit = "settings.mileageUnit"
        static let notifyService = "settings.notifyServiceReminders"
        static let notifyDocuments = "settings.notifyExpiringDocuments"
        static let notificationLeadDays = "settings.notificationLeadDays"
        static let serviceNotificationLeadMileage = "settings.serviceNotificationLeadMileage"
        static let documentNotificationLeadDays = "settings.documentNotificationLeadDays"
        static let savePhotosInApp = "settings.savePhotosInApp"
        static let lowStorageMode = "settings.lowStorageMode"
    }
}
