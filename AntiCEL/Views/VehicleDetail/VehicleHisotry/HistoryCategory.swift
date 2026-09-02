enum HistoryCategory: String, Codable, CaseIterable {

    case maintenance
    case repair
    case modification
    case inspection
    case registration
    case accident
    case purchase
    case sale
    case note

    var systemImage: String {
        switch self {
        case .maintenance:
            return "wrench.and.screwdriver.fill"
        case .repair:
            return "hammer.fill"
        case .modification:
            return "engine.combustion.fill"
        case .inspection:
            return "checkmark.shield.fill"
        case .registration:
            return "doc.text.fill"
        case .accident:
            return "exclamationmark.triangle.fill"
        case .purchase:
            return "car.fill"
        case .sale:
            return "dollarsign.circle.fill"
        case .note:
            return "note.text"
        }
    }

}
