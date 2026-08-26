import Foundation
import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable, Codable {
    case dark
    case light
    case system

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dark: return "Dark"
        case .light: return "Light"
        case .system: return "Follow System"
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .dark: return .dark
        case .light: return .light
        case .system: return nil
        }
    }
}

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

enum TemperatureUnit: String, CaseIterable, Identifiable, Codable {
    case celsius
    case fahrenheit

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .celsius: return "Celsius"
        case .fahrenheit: return "Fahrenheit"
        }
    }

    var abbreviation: String {
        switch self {
        case .celsius: return "°C"
        case .fahrenheit: return "°F"
        }
    }

    static var deviceDefault: TemperatureUnit {
        Locale.current.measurementSystem == .metric ? .celsius : .fahrenheit
    }

    func displayValue(fromCelsius celsius: Double) -> Double {
        switch self {
        case .celsius:
            return celsius
        case .fahrenheit:
            return celsius * 9 / 5 + 32
        }
    }

    func formatted(_ celsius: Double) -> String {
        "\(Int(displayValue(fromCelsius: celsius).rounded()))\(abbreviation)"
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

    var appearanceMode: AppearanceMode {
        didSet {
            defaults.set(appearanceMode.rawValue, forKey: Keys.appearanceMode)
            WidgetReloader.reload()
        }
    }

    var mileageUnit: MileageUnit {
        didSet {
            defaults.set(mileageUnit.rawValue, forKey: Keys.mileageUnit)
            WidgetReloader.reload()
        }
    }

    var temperatureUnit: TemperatureUnit {
        didSet { defaults.set(temperatureUnit.rawValue, forKey: Keys.temperatureUnit) }
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

    var showHints: Bool {
        didSet { defaults.set(showHints, forKey: Keys.showHints) }
    }

    var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Keys.hapticsEnabled) }
    }

    var moreHaptics: Bool {
        didSet { defaults.set(moreHaptics, forKey: Keys.moreHaptics) }
    }

    var savePhotosInApp: Bool { !lowStorageMode }

    private let defaults: UserDefaults

    private init() {
        defaults = UserDefaults(suiteName: AppGroup.identifier) ?? .standard

        lightAccent = AccentOption(rawValue: defaults.string(forKey: Keys.lightAccent) ?? "") ?? .amber
        darkAccent = AccentOption(rawValue: defaults.string(forKey: Keys.darkAccent) ?? "") ?? .amberRed
        appearanceMode = AppearanceMode(rawValue: defaults.string(forKey: Keys.appearanceMode) ?? "") ?? .dark
        mileageUnit = MileageUnit(rawValue: defaults.string(forKey: Keys.mileageUnit) ?? "") ?? .kilometers
        if let storedTemperature = defaults.string(forKey: Keys.temperatureUnit),
           let unit = TemperatureUnit(rawValue: storedTemperature) {
            temperatureUnit = unit
        } else {
            temperatureUnit = .deviceDefault
        }
        notifyServiceReminders = defaults.object(forKey: Keys.notifyService) as? Bool ?? false
        notifyExpiringDocuments = defaults.object(forKey: Keys.notifyDocuments) as? Bool ?? false

        let lead = defaults.object(forKey: Keys.notificationLeadDays) as? Int
        let leadDays = NotificationLeadDays(rawValue: lead ?? 7) ?? .seven
        notificationLeadDays = leadDays

        let mileageLead = defaults.object(forKey: Keys.serviceNotificationLeadMileage) as? Int
        serviceNotificationLeadMileage = NotificationLeadMileage(rawValue: mileageLead ?? 500) ?? .fiveHundred

        if let documentLead = defaults.object(forKey: Keys.documentNotificationLeadDays) as? Int,
           let parsed = NotificationLeadDays(rawValue: documentLead) {
            documentNotificationLeadDays = parsed
        } else {
            documentNotificationLeadDays = leadDays
        }

        if defaults.object(forKey: Keys.lowStorageMode) != nil {
            lowStorageMode = defaults.bool(forKey: Keys.lowStorageMode)
        } else {
            let saveInApp = defaults.object(forKey: Keys.savePhotosInApp) as? Bool ?? true
            lowStorageMode = !saveInApp
        }

        if defaults.object(forKey: Keys.showHints) != nil {
            showHints = defaults.bool(forKey: Keys.showHints)
        } else {
            showHints = true
        }

        if defaults.object(forKey: Keys.hapticsEnabled) != nil {
            hapticsEnabled = defaults.bool(forKey: Keys.hapticsEnabled)
        } else {
            hapticsEnabled = true
        }

        if defaults.object(forKey: Keys.moreHaptics) != nil {
            moreHaptics = defaults.bool(forKey: Keys.moreHaptics)
        } else {
            moreHaptics = false
        }
    }

    func accentOption(for scheme: ColorScheme) -> AccentOption {
        scheme == .dark ? darkAccent : lightAccent
    }

    func formattedMileage(_ storedKilometers: Int?) -> String {
        mileageUnit.formatted(storedKilometers)
    }

    func formattedTemperature(_ celsius: Double) -> String {
        temperatureUnit.formatted(celsius)
    }

    private enum Keys {
        static let lightAccent = "settings.lightAccent"
        static let darkAccent = "settings.darkAccent"
        static let appearanceMode = "settings.appearanceMode"
        static let mileageUnit = "settings.mileageUnit"
        static let temperatureUnit = "settings.temperatureUnit"
        static let notifyService = "settings.notifyServiceReminders"
        static let notifyDocuments = "settings.notifyExpiringDocuments"
        static let notificationLeadDays = "settings.notificationLeadDays"
        static let serviceNotificationLeadMileage = "settings.serviceNotificationLeadMileage"
        static let documentNotificationLeadDays = "settings.documentNotificationLeadDays"
        static let savePhotosInApp = "settings.savePhotosInApp"
        static let lowStorageMode = "settings.lowStorageMode"
        static let showHints = "settings.showHints"
        static let hapticsEnabled = "settings.hapticsEnabled"
        static let moreHaptics = "settings.moreHaptics"
    }
}
