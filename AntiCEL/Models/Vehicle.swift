import Foundation
import SwiftData

//model to hold vehicles that are added to the garage

@Model
final class Vehicle {

    //these audit fields are added for tracking and filtering later just like any other inventory system.
    var id: UUID
    var createdAt: Date
    var updatedAt: Date

    var make: String
    var model: String
    var year: Int
    var nickname: String
    var vin: String
    var currentMileage: Int
    //optional so older store rows (created before this field existed) do not crash on read
    var photoFileName: String? = nil
    var photoScale: Double? = nil
    var photoOffsetX: Double? = nil
    var photoOffsetY: Double? = nil

    var photoFraming: PhotoFraming {
        PhotoFraming(
            scale: photoScale ?? 1,
            offsetX: photoOffsetX ?? 0,
            offsetY: photoOffsetY ?? 0
        ).clamped
    }

    func applyPhotoFraming(_ framing: PhotoFraming) {
        let clamped = framing.clamped
        photoScale = clamped.scale
        photoOffsetX = clamped.offsetX
        photoOffsetY = clamped.offsetY
    }
    
    //this is for the service reminders (A vehicle can have many ServiceReminder)
    @Relationship(deleteRule: .cascade, inverse: \ServiceReminder.vehicle) //when the vehicle is deleted, so are all of these.
    var serviceReminders: [ServiceReminder] = []
    
    //relationship for the notes related to the vehicle.
    @Relationship(deleteRule: .cascade, inverse: \VehicleNote.vehicle)
    var notes: [VehicleNote] = []

    //shops used for this vehicle (mechanic, tint, tires, etc.).
    @Relationship(deleteRule: .cascade, inverse: \VehicleShop.vehicle)
    var shops: [VehicleShop] = []
    
    @Relationship(deleteRule: .cascade, inverse: \HistoryEntry.vehicle)
    var historyEntries: [HistoryEntry] = []

    //relationship for documents related to the vehicle.
    @Relationship(deleteRule: .cascade, inverse: \VehicleDocument.vehicle)
    var documents: [VehicleDocument] = []

    @Relationship(deleteRule: .cascade, inverse: \VehicleAlbumPhoto.vehicle)
    var albumPhotos: [VehicleAlbumPhoto] = []

    init(
        make: String,
        model: String,
        year: Int,
        nickname: String = "",
        vin: String = "",
        currentMileage: Int
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()

        self.make = make
        self.model = model
        self.year = year
        self.nickname = nickname
        self.vin = vin
        self.currentMileage = currentMileage
        self.photoFileName = nil
        self.photoScale = nil
        self.photoOffsetX = nil
        self.photoOffsetY = nil
    }
}

//Shops the user uses for this vehicle - this is in here because it was causing some build issues when in its own file
//It was doing this because it wouldnt build the shop file at the target for some reason. This was built so I put it here.

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
