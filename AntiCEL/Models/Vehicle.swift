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
    
    //this is for the service reminders (A vehicle can have many ServiceReminder)
    @Relationship(deleteRule: .cascade, inverse: \ServiceReminder.vehicle) //when the vehicle is deleted, so are all of these.
    var serviceReminders: [ServiceReminder] = []
    
    //relationship for the notes related to the vehicle.
    @Relationship(deleteRule: .cascade, inverse: \VehicleNote.vehicle)
    var notes: [VehicleNote] = []

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
    }
}
