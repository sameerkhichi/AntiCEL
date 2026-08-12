import Foundation

//this enum is to track what section the user is currently viewing on the vehicle detail page.

enum VehicleDetailSection: String, CaseIterable, Identifiable {

    case overview = "Overview"
    case history = "History"
    case documents = "Documents"
    case settings = "Settings"

    var id: Self { self }

    var iconName: String {
        switch self {
        case .overview:
            return "house.fill"
        case .history:
            return "clock.fill"
        case .documents:
            return "doc.text.fill"
        case .settings:
            return "gearshape.fill"
        }
    }
}
