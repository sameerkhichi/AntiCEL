import Foundation
import SwiftData

@Model
final class HistoryEntry {

    var id: UUID
    var title: String
    var details: String
    var date: Date
    var mileage: Int?
    var category: HistoryCategory
    //optional so older store rows (created before this field existed) do not crash on read
    var vehicleArea: VehicleArea?
    var photoFileName: String? = nil
    var vehicle: Vehicle?
    // optional so older store rows (created before this field existed) do not crash on read
    var createdFromScannedFault: Bool? = nil
    var scannedFaultCode: String? = nil

    var resolvedVehicleArea: VehicleArea {
        vehicleArea ?? .misc
    }

    var isAutoScannedFault: Bool {
        if createdFromScannedFault == true { return true }
        if scannedFaultCode != nil { return true }
        return Self.dtcPrefix(from: details) != nil
    }

    var displayTitle: String {
        let code = (scannedFaultCode ?? Self.dtcPrefix(from: details))?.uppercased()
        if let code, !title.uppercased().contains(code) {
            return "\(code) · \(title)"
        }
        return title
    }

    init(
        title: String,
        details: String = "",
        date: Date,
        mileage: Int? = nil,
        category: HistoryCategory,
        vehicleArea: VehicleArea = .misc,
        photoFileName: String? = nil,
        vehicle: Vehicle? = nil,
        createdFromScannedFault: Bool? = nil,
        scannedFaultCode: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.details = details
        self.date = date
        self.mileage = mileage
        self.category = category
        self.vehicleArea = vehicleArea
        self.photoFileName = photoFileName
        self.vehicle = vehicle
        self.createdFromScannedFault = createdFromScannedFault
        self.scannedFaultCode = scannedFaultCode
    }

    private static func dtcPrefix(from details: String) -> String? {
        let head = details
            .split(separator: "—", maxSplits: 1)
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        guard let head, head.range(of: #"^[PCBU][0-9A-F]{4}$"#, options: .regularExpression) != nil else {
            return nil
        }
        return head
    }
}
