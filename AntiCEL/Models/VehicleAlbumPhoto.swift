import Foundation
import SwiftData

@Model
final class VehicleAlbumPhoto {

    var id: UUID
    var photoFileName: String? = nil
    var createdAt: Date
    var updatedAt: Date
    var capturedAt: Date? = nil

    var vehicle: Vehicle?

    var displayDate: Date {
        capturedAt ?? createdAt
    }

    init(
        photoFileName: String? = nil,
        capturedAt: Date? = nil,
        vehicle: Vehicle? = nil
    ) {
        self.id = UUID()
        self.photoFileName = photoFileName
        self.createdAt = Date()
        self.updatedAt = Date()
        self.capturedAt = capturedAt
        self.vehicle = vehicle
    }
}
