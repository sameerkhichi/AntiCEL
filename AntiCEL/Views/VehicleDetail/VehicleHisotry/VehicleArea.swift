import Foundation

//areas of the vehicle used by the interactive model view
//and when tagging history / service records.

enum VehicleArea: String, Codable, CaseIterable, Identifiable {

    case drivetrain
    case body
    case wheels
    case misc

    var id: Self { self }

    var displayName: String {
        switch self {
        case .drivetrain:
            return "Drivetrain"
        case .body:
            return "Body"
        case .wheels:
            return "Wheels / Suspension"
        case .misc:
            return "Misc"
        }
    }

    var shortLabel: String {
        switch self {
        case .drivetrain:
            return "Engine"
        case .body:
            return "Body"
        case .wheels:
            return "Wheels"
        case .misc:
            return "Misc"
        }
    }

    var iconName: String {
        switch self {
        case .drivetrain:
            return "engine.combustion.fill"
        case .body:
            return "car.side.fill"
        case .wheels:
            return "circle.circle.fill"
        case .misc:
            return "shippingbox.fill"
        }
    }

    var prompt: String {
        switch self {
        case .drivetrain:
            return "Engine & drivetrain services"
        case .body:
            return "Body & exterior work"
        case .wheels:
            return "Wheels & suspension history"
        case .misc:
            return "Miscellaneous records"
        }
    }
}
