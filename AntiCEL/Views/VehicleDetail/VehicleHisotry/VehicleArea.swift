import Foundation

//areas of the vehicle used by the interactive model view
//and when tagging history / service records.

enum VehicleArea: String, Codable, CaseIterable, Identifiable {

    case drivetrain
    case body
    case wheels
    case chassis
    case interior
    case misc

    var id: Self { self }

    var displayName: String {
        switch self {
        case .drivetrain:
            return "Drivetrain"
        case .body:
            return "Body"
        case .wheels:
            return "Wheels"
        case .chassis:
            return "Chassis"
        case .interior:
            return "Interior"
        case .misc:
            return "Misc"
        }
    }

    var shortLabel: String {
        displayName
    }

    var iconName: String {
        switch self {
        case .drivetrain:
            return "engine.combustion.fill"
        case .body:
            return "car.side.fill"
        case .wheels:
            return "circle.circle.fill"
        case .chassis:
            return "axle.2"
        case .interior:
            return "steeringwheel"
        case .misc:
            return "shippingbox.fill"
        }
    }

    var prompt: String {
        switch self {
        case .drivetrain:
            return "Motor, Transmission, Differential etc"
        case .body:
            return "Body & exterior work"
        case .wheels:
            return "Wheels & tires"
        case .chassis:
            return "Chassis, Brakes, Frame & Suspension"
        case .interior:
            return "Interior modifications"
        case .misc:
            return "Miscellaneous records"
        }
    }

    var helpDescription: String {
        switch self {
        case .drivetrain:
            return "Items related to powering the vehicle and related components that use the vehicles power to move the wheels."
        case .body:
            return "Anything related to the exterior body panels."
        case .wheels:
            return "Wheels, Tires, Bearings and any components related to the vehicles wheel assembly."
        case .chassis:
            return "Frame, Suspension, brakes and other components related to the build of the vehicles bones."
        case .interior:
            return "Components related to or located on the inside of the vehicle."
        case .misc:
            return "Items that are not related to any other category."
        }
    }
}
