import Foundation
import SwiftData

//VERY simple model for the notes related to the vehicle. 

@Model
final class VehicleNote {

    var title: String
    var content: String

    var createdAt: Date
    var updatedAt: Date

    var vehicle: Vehicle?

    init(
        title: String,
        content: String
    ) {

        self.title = title
        self.content = content

        self.createdAt = Date()
        self.updatedAt = Date()

    }

}
