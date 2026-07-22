import Foundation
import SwiftData

@Model
final class ServiceReminder {

    var name: String

    var type: ReminderType //based on the enum in the VehicleOverview folder.

    var dueDate: Date?

    var dueMileage: Int?

    var notes: String

    var isCompleted: Bool //for when we can turn it into a history event later.

    var vehicle: Vehicle? //every ServiceReminder has atleast one vehicle (many to one relationship in this case service reminder either has zero or one vehicle)
    
    

    init(
        name: String,
        type: ReminderType,
        dueDate: Date? = nil,
        dueMileage: Int? = nil,
        notes: String = "",
        isCompleted: Bool = false
    ) {

        self.name = name
        self.type = type
        self.dueDate = dueDate
        self.dueMileage = dueMileage
        self.notes = notes
        self.isCompleted = isCompleted

    }

}
