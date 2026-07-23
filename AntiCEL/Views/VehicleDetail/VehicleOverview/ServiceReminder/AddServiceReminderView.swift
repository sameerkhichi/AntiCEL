//this file is the view that lets the user add a service reminder to the overview page.
//This can either be a milege based or date based service reminder.
import SwiftUI
import SwiftData

struct AddServiceReminderView: View {

    let vehicle: Vehicle

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var reminderType: ReminderType = .date

    @State private var dueDate = Date()
    @State private var dueMileage = ""

    @State private var notes = ""

    var body: some View {

        NavigationStack {

            Form {

                Section("Reminder") {

                    TextField("Reminder Name", text: $name)

                    Picker("Reminder Type", selection: $reminderType) {

                        ForEach(ReminderType.allCases, id: \.self) {

                            Text($0.rawValue)
                                .tag($0)

                        }

                    }

                }

                Section("Due") {

                    switch reminderType {

                    case .date:

                        DatePicker(
                            "Due Date",
                            selection: $dueDate,
                            displayedComponents: .date
                        )

                    case .mileage:

                        TextField(
                            "Due Mileage",
                            text: $dueMileage
                        )
                        .keyboardType(.numberPad)

                    case .whicheverComesFirst:

                        DatePicker(
                            "Due Date",
                            selection: $dueDate,
                            displayedComponents: .date
                        )

                        TextField(
                            "Due Mileage",
                            text: $dueMileage
                        )
                        .keyboardType(.numberPad)

                    }

                }

                Section("Notes") {

                    TextField(
                        "Optional Notes",
                        text: $notes,
                        axis: .vertical
                    )

                }

            }
            .navigationTitle("New Reminder")
            .toolbar {

                ToolbarItem(placement: .topBarLeading) {

                    Button("Cancel") {
                        dismiss()
                    }

                }

                ToolbarItem(placement: .topBarTrailing) {

                    Button("Save") {
                        saveReminder()
                    }

                }

            }

        }

    }

    private func saveReminder() {

        guard !name.isEmpty else {
            return
        }

        let mileage = Int(dueMileage)

        let reminder = ServiceReminder(
            name: name,
            type: reminderType,
            dueDate: reminderType == .mileage ? nil : dueDate,
            dueMileage: reminderType == .date ? nil : mileage,
            notes: notes
        )

        reminder.vehicle = vehicle //appends this reminder to the array holding the in the model. This holds the relationship together.

        modelContext.insert(reminder)

        dismiss()

    }

}
