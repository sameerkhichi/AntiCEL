import Foundation
import SwiftData

// Shops the user uses for this vehicle (mechanic, tint, tires, etc.).

@Model
final class VehicleShop {

    var name: String
    var details: String

    var createdAt: Date
    var updatedAt: Date

    var vehicle: Vehicle?

    init(
        name: String,
        details: String
    ) {

        self.name = name
        self.details = details

        self.createdAt = Date()
        self.updatedAt = Date()

    }

}
