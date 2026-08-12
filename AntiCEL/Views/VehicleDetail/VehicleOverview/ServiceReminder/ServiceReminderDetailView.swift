import SwiftUI
import SwiftData

struct ServiceReminderDetailView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showDeleteAlert = false

    let reminder: ServiceReminder

    @State private var showCompletionSheet = false

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

                infoRow(
                    title: "Related To",
                    value: reminder.vehicleArea.displayName
                )


                switch reminder.type {

                case .date:

                    infoRow(
                        title: "Due Date",
                        value: reminder.dueDate?.formatted(
                            date: .abbreviated,
                            time: .omitted
                        ) ?? "Not Set"
                    )


                case .mileage:

                    infoRow(
                        title: "Due Mileage",
                        value: reminder.dueMileage?.formatted() ?? "Not Set"
                    )


                case .whicheverComesFirst:

                    infoRow(
                        title: "Due Date",
                        value: reminder.dueDate?.formatted(
                            date: .abbreviated,
                            time: .omitted
                        ) ?? "Not Set"
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

                //Opens the completion sheet before converting reminder into history.
                Button("Complete Service") {
                    showCompletionSheet = true
                }
                .buttonStyle(.borderedProminent)

                // Deletes the reminder.
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Text("Delete Reminder")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()

        }
        .navigationTitle("Reminder")
        .navigationBarTitleDisplayMode(.inline)

        //Completion Sheet
        .sheet(isPresented: $showCompletionSheet) {

            CompleteServiceSheet(reminder: reminder) { date, mileage in

                completeService(
                    completionDate: date,
                    completionMileage: mileage
                )
            }
        }

        //Delete Confirmation
        .alert(
            "Delete Reminder?",
            isPresented: $showDeleteAlert
        ) {

            Button("Delete", role: .destructive) {

                modelContext.delete(reminder)
                dismiss()

            }
            Button("Cancel", role: .cancel) {
            }

        } message: {

            Text("This reminder will be permanently deleted.")
        }
    }

    private func completeService(
        completionDate: Date,
        completionMileage: Int?
    ) {

        guard let vehicle = reminder.vehicle else {
            return
        }


        let newEntry = HistoryEntry(
            title: reminder.name,
            details: reminder.notes,
            date: completionDate,
            mileage: completionMileage,
            category: .maintenance,
            vehicleArea: reminder.vehicleArea,
            vehicle: vehicle
        )


        modelContext.insert(newEntry)

        vehicle.historyEntries.append(newEntry)


        modelContext.delete(reminder)


        dismiss()

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
