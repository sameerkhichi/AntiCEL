import Foundation

//Deciding what type the service reminder is going to be
//thats either mileage based or data based. Or well both.
enum ReminderType: String, Codable, CaseIterable {

    case date = "Date"

    case mileage = "Mileage"

    case whicheverComesFirst = "Whichever Comes First"

}
