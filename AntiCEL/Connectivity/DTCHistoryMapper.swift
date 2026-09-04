import Foundation

enum DTCHistoryMapper {

    static func vehicleArea(for code: String) -> VehicleArea {
        switch code.uppercased().first {
        case "P":
            return .drivetrain
        case "C":
            return .chassis
        case "B":
            return .body
        case "U":
            return .misc
        default:
            return .misc
        }
    }

    static func category(for _: String) -> HistoryCategory {
        .repair
    }

    static func historyTitle(for code: String) -> String {
        DTCDictionary.title(for: code)
    }

    static func historyDetails(code: String, status: DiagnosticFaultStatus) -> String {
        let key = DTCDictionary.normalizedCode(code)
        return "\(key) — \(DTCDictionary.description(for: key)). Status: \(status.displayName)."
    }
}
