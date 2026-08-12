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
    var vehicle: Vehicle?

    var resolvedVehicleArea: VehicleArea {
        vehicleArea ?? .misc
    }

    init(
        title: String,
        details: String = "",
        date: Date,
        mileage: Int? = nil,
        category: HistoryCategory,
        vehicleArea: VehicleArea = .misc,
        vehicle: Vehicle? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.details = details
        self.date = date
        self.mileage = mileage
        self.category = category
        self.vehicleArea = vehicleArea
        self.vehicle = vehicle
    }
}
