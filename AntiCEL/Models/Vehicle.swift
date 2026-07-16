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
    var currentMileage: Int

    init(
        make: String,
        model: String,
        year: Int,
        nickname: String = "",
        currentMileage: Int
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()

        self.make = make
        self.model = model
        self.year = year
        self.nickname = nickname
        self.currentMileage = currentMileage
    }
}
