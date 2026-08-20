import Foundation
import SwiftData

@Model
final class PairedAdapter {

    var id: UUID
    var peripheralIdentifier: UUID
    var name: String
    var lastSeenAt: Date
    var createdAt: Date

    var vehicle: Vehicle?

    init(
        peripheralIdentifier: UUID,
        name: String,
        vehicle: Vehicle? = nil
    ) {
        self.id = UUID()
        self.peripheralIdentifier = peripheralIdentifier
        self.name = name
        self.lastSeenAt = Date()
        self.createdAt = Date()
        self.vehicle = vehicle
    }
}
