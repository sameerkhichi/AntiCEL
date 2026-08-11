import Foundation
import SwiftData

//simple model for documents related to the vehicle (registration, insurance, etc).

@Model
final class VehicleDocument {

    var id: UUID
    var title: String
    var details: String
    var category: DocumentCategory
    var date: Date
    var expirationDate: Date?

    var createdAt: Date
    var updatedAt: Date

    var vehicle: Vehicle?

    init(
        title: String,
        details: String = "",
        category: DocumentCategory,
        date: Date = Date(),
        expirationDate: Date? = nil,
        vehicle: Vehicle? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.details = details
        self.category = category
        self.date = date
        self.expirationDate = expirationDate
        self.createdAt = Date()
        self.updatedAt = Date()
        self.vehicle = vehicle
    }
}
