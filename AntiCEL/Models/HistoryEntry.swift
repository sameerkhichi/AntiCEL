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
    var vehicleArea: VehicleArea = VehicleArea.misc
    var vehicle: Vehicle?

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
