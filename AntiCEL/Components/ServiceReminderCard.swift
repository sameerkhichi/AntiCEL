import SwiftUI

struct ServiceReminderCard: View {

    let vehicle: Vehicle

    @State private var showingAddReminder = false

    var body: some View {
        DashPanel {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Service Reminders")
                        .font(.title3.weight(.semibold).width(.condensed))

                    Spacer()

                    Button {
                        showingAddReminder = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.body.weight(.semibold))
                    }
                    .buttonStyle(DashButtonStyle(kind: .compact))
                }

                Rectangle()
                    .fill(.quaternary)
                    .frame(height: 1)

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

                                    Text(reminder.resolvedVehicleArea.displayName)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)

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
                                Rectangle()
                                    .fill(.quaternary)
                                    .frame(height: 1)
                                    .padding(.vertical, 10)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .sheet(isPresented: $showingAddReminder) {
            AddServiceReminderView(vehicle: vehicle)
        }
    }
}
