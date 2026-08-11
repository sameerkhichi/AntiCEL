import Foundation

enum DocumentCategory: String, Codable, CaseIterable {

    case registration
    case insurance
    case billOfSale
    case other

    var displayName: String {
        switch self {
        case .registration:
            return "Registration"
        case .insurance:
            return "Insurance"
        case .billOfSale:
            return "Bill of Sale"
        case .other:
            return "Other"
        }
    }

    var iconName: String {
        switch self {
        case .registration:
            return "doc.text.fill"
        case .insurance:
            return "shield.fill"
        case .billOfSale:
            return "dollarsign.circle.fill"
        case .other:
            return "folder.fill"
        }
    }
}
