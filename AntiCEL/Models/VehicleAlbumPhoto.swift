import Foundation
import SwiftData

@Model
final class VehicleAlbumPhoto {

    var id: UUID
    var photoFileName: String? = nil
    var createdAt: Date
    var updatedAt: Date

    var vehicle: Vehicle?

    init(
        photoFileName: String? = nil,
        vehicle: Vehicle? = nil
    ) {
        self.id = UUID()
        self.photoFileName = photoFileName
        self.createdAt = Date()
        self.updatedAt = Date()
        self.vehicle = vehicle
    }
}
