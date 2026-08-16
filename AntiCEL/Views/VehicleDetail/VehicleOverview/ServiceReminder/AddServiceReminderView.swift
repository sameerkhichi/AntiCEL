import SwiftUI
import SwiftData

struct AddServiceReminderView: View {

    let vehicle: Vehicle

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings

    @State private var name = ""
    @State private var reminderType: ReminderType = .date
    @State private var vehicleArea: VehicleArea = .misc
    @State private var dueDate = Date()
    @State private var dueMileage = ""
    @State private var notes = ""

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        InfotainmentScaffold(
            title: "New Reminder",
            confirmEnabled: canSave,
            onCancel: { dismiss() },
            onConfirm: saveReminder
        ) {
            InfotainmentField(label: "Reminder Name") {
                TextField("Name", text: $name)
            }

            InfotainmentChipPicker(
                title: "Reminder Type",
                selection: $reminderType,
                options: ReminderType.allCases,
                itemTitle: { $0.rawValue }
            )

            InfotainmentChipPicker(
                title: "Related To",
                selection: $vehicleArea,
                options: Array(VehicleArea.allCases),
                itemTitle: { $0.displayName }
            )

            InfotainmentSectionHeader(title: "Due")

            switch reminderType {
            case .date:
                InfotainmentField(label: "Due Date") {
                    DatePicker(
                        "Due Date",
                        selection: $dueDate,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                }

            case .mileage:
                InfotainmentField(label: "Due Mileage (\(settings.mileageUnit.abbreviation))") {
                    TextField("Due Mileage", text: $dueMileage)
                        .keyboardType(.numberPad)
                }

            case .whicheverComesFirst:
                InfotainmentField(label: "Due Date") {
                    DatePicker(
                        "Due Date",
                        selection: $dueDate,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                }

                InfotainmentField(label: "Due Mileage (\(settings.mileageUnit.abbreviation))") {
                    TextField("Due Mileage", text: $dueMileage)
                        .keyboardType(.numberPad)
                }
            }

            InfotainmentField(label: "Notes") {
                TextField("Optional notes", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
        .appTheme()
    }

    private func saveReminder() {
        guard !name.isEmpty else {
            return
        }

        let mileage = Int(dueMileage).map { settings.mileageUnit.storedKilometers(fromDisplay: $0) }

        let reminder = ServiceReminder(
            name: name,
            type: reminderType,
            dueDate: reminderType == .mileage ? nil : dueDate,
            dueMileage: reminderType == .date ? nil : mileage,
            notes: notes,
            vehicleArea: vehicleArea
        )

        reminder.vehicle = vehicle
        modelContext.insert(reminder)
        ReminderNotifications.refresh(using: modelContext)
        dismiss()
    }
}
