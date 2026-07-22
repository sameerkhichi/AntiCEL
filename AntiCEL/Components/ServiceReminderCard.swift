import SwiftUI

struct ServiceReminderCard: View {

    let vehicle: Vehicle

    var body: some View {

        VStack(alignment: .leading, spacing: 12) {

            HStack {

                Text("Service Reminders")
                    .font(.headline)

                Spacer()

                Button {

                    //TODO: Make a sheet to add a reminder

                } label: {

                    Image(systemName: "plus")

                }

            }

            Divider()

            if vehicle.serviceReminders.isEmpty {

                Text("No service reminders.")
                    .foregroundStyle(.secondary)

            } else {

                ForEach(vehicle.serviceReminders) { reminder in

                    VStack(alignment: .leading, spacing: 4) {

                        Text(reminder.name)
                            .fontWeight(.semibold)

                        switch reminder.type {

                        case .date:

                            if let dueDate = reminder.dueDate {

                                Text("Due: \(dueDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)

                            }

                        case .mileage:

                            if let mileage = reminder.dueMileage {

                                Text("Due at \(mileage.formatted()) km")
                                    .font(.caption)

                            }

                        case .whicheverComesFirst:

                            VStack(alignment: .leading) {

                                if let dueDate = reminder.dueDate {

                                    Text("Date: \(dueDate.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption)

                                }

                                if let mileage = reminder.dueMileage {

                                    Text("Mileage: \(mileage.formatted()) km")
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    Divider()
                }
            }
        }
    }
}
