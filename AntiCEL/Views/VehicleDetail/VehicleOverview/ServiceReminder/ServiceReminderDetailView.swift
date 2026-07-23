//When a user taps on a reminder, it will show them the details of it, then it will prompt them either to delete it, update their mileage that is currently on their car, or complete the reminder which will auto transfer it to the history page for the vehicle.
import SwiftUI

struct ServiceReminderDetailView: View {

    let reminder: ServiceReminder

    var body: some View {

        VStack(spacing: 20) {

            VStack(alignment: .leading, spacing: 16) {

                Text(reminder.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Divider()

                infoRow(
                    title: "Type",
                    value: reminder.type.rawValue
                )

                switch reminder.type {

                case .date:

                    infoRow(
                        title: "Due Date",
                        value: reminder.dueDate?.formatted(date: .abbreviated,
                                                           time: .omitted)
                        ?? "Not Set"
                    )

                case .mileage:

                    infoRow(
                        title: "Due Mileage",
                        value: reminder.dueMileage?.formatted() ?? "Not Set"
                    )

                case .whicheverComesFirst:

                    infoRow(
                        title: "Due Date",
                        value: reminder.dueDate?.formatted(date: .abbreviated,
                                                           time: .omitted)
                        ?? "Not Set"
                    )

                    infoRow(
                        title: "Due Mileage",
                        value: reminder.dueMileage?.formatted() ?? "Not Set"
                    )

                }

                Divider()

                Text("Notes")
                    .font(.headline)

                Text(
                    reminder.notes.isEmpty
                    ? "No notes."
                    : reminder.notes
                )

            }
            .padding()

            Spacer()

            VStack(spacing: 12) {

                Button("Update Mileage") {

                    // TODO

                }
                .buttonStyle(.borderedProminent)

                Button("Complete Service") {

                    // TODO

                }
                .buttonStyle(.borderedProminent)

                Button("Delete Reminder") {

                    // TODO

                }
                .foregroundStyle(.red)

            }
            .padding()

        }
        .navigationTitle("Reminder")
        .navigationBarTitleDisplayMode(.inline)

    }

    @ViewBuilder
    private func infoRow(title: String, value: String) -> some View {

        HStack {

            Text(title)

            Spacer()

            Text(value)
                .foregroundStyle(.secondary)

        }

    }

}

#Preview {

    NavigationStack {

        ServiceReminderDetailView(
            reminder: ServiceReminder(
                name: "Oil Change",
                type: .whicheverComesFirst,
                dueDate: .now,
                dueMileage: 80000,
                notes: "Use Liqui Moly 5W-40"
            )
        )

    }

}
