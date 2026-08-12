import Foundation

enum VehicleDetailSection: String, CaseIterable, Identifiable {

    case overview = "Overview"
    case history = "History"
    case documents = "Documents"
    case settings = "Settings"

    var id: Self { self }

    var iconName: String {
        switch self {
        case .overview:
            return "gauge"
        case .history:
            return "clock.fill"
        case .documents:
            return "folder.fill"
        case .settings:
            return "slider.horizontal.3"
        }
    }
}
