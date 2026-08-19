import SwiftUI

struct ServiceReminderCard: View {

    @Environment(AppSettings.self) private var settings

    let vehicle: Vehicle

    @State private var showingAddReminder = false
    @State private var showingHint = false

    private var sortedReminders: [ServiceReminder] {
        vehicle.serviceReminders.sorted { lhs, rhs in
            lhs.nextDueSortDate(currentMileage: vehicle.currentMileage)
                < rhs.nextDueSortDate(currentMileage: vehicle.currentMileage)
        }
    }

    var body: some View {
        DashPanel {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Service Reminders")
                        .font(.title3.weight(.semibold).width(.condensed))

                    HintButton(title: "Service Reminders") {
                        showingHint = true
                    }

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
                    ForEach(Array(sortedReminders.enumerated()), id: \.element) { index, reminder in
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
                                            Text("Due at \(settings.formattedMileage(mileage))")
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
                                            Text("Mileage: \(settings.formattedMileage(mileage))")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            if index < sortedReminders.count - 1 {
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
        .sheet(isPresented: $showingHint) {
            HintSheet(topic: .serviceReminders)
        }
    }
}
