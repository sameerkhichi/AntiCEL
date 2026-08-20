import Foundation

enum VehicleDetailSection: String, CaseIterable, Identifiable {

    case overview = "Overview"
    case history = "History"
    case documents = "Documents"
    case album = "Album"
    case connect = "Connect"

    var id: Self { self }

    var iconName: String {
        switch self {
        case .overview:
            return "gauge"
        case .history:
            return "clock.fill"
        case .documents:
            return "folder.fill"
        case .album:
            return "photo.on.rectangle.fill"
        case .connect:
            return "dot.radiowaves.left.and.right"
        }
    }
}
