import SwiftUI

struct ServiceReminderCard: View {

    let vehicle: Vehicle

    @State private var showingAddReminder = false

    var body: some View {

        VStack(alignment: .leading, spacing: 16) {

            HStack {

                Text("Service Reminders")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                Button {
                    showingAddReminder = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title3)
                }
            }

            Divider()

            if vehicle.serviceReminders.isEmpty {

                Text("No service reminders.")
                    .foregroundStyle(.secondary)

            } else {

                ForEach(Array(vehicle.serviceReminders.enumerated()), id: \.element) { index, reminder in

                    VStack(alignment: .leading, spacing: 0) {

                        NavigationLink(destination: ServiceReminderDetailView(reminder: reminder)) {

                            VStack(alignment: .leading, spacing: 6) {

                                Text(reminder.name)
                                    .fontWeight(.semibold)

                                switch reminder.type {

                                case .date:

                                    if let dueDate = reminder.dueDate {

                                        Text("Due: \(dueDate.formatted(date: .abbreviated, time: .omitted))")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)

                                    }

                                case .mileage:

                                    if let mileage = reminder.dueMileage {

                                        Text("Due at \(mileage.formatted()) km")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)

                                    }

                                case .whicheverComesFirst:

                                    if let dueDate = reminder.dueDate {

                                        Text("Date: \(dueDate.formatted(date: .abbreviated, time: .omitted))")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)

                                    }

                                    if let mileage = reminder.dueMileage {

                                        Text("Mileage: \(mileage.formatted()) km")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)

                                    }

                                }

                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())

                        }
                        .buttonStyle(.plain)

                        if index < vehicle.serviceReminders.count - 1 {
                            Divider()
                        }

                    }

                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .sheet(isPresented: $showingAddReminder) {

            AddServiceReminderView(vehicle: vehicle)
        }
    }
}
