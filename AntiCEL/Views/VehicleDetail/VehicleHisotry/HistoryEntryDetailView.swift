import SwiftUI
import SwiftData

struct HistoryEntryDetailView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var vehicle: Vehicle

    var initialTitle: String?
    var initialCategory: HistoryCategory?
    var initialVehicleArea: VehicleArea?
    var initialDate: Date?
    var initialMileage: Int?
    var completedReminder: ServiceReminder?

    var historyEntry: HistoryEntry?

    @State private var title = ""
    @State private var category: HistoryCategory = .maintenance
    @State private var vehicleArea: VehicleArea = .misc
    @State private var date = Date()
    @State private var mileage = ""
    @State private var notes = ""

    private var isEditing: Bool {
        historyEntry != nil
    }

    var body: some View {
        InfotainmentScaffold(
            title: isEditing ? "Edit Entry" : "New Entry",
            onCancel: { dismiss() },
            onConfirm: saveEntry
        ) {
            InfotainmentField(label: "Title") {
                TextField("Title", text: $title)
            }

            InfotainmentChipPicker(
                title: "Category",
                selection: $category,
                options: Array(HistoryCategory.allCases),
                itemTitle: { $0.rawValue.capitalized }
            )

            InfotainmentChipPicker(
                title: "Related To",
                selection: $vehicleArea,
                options: Array(VehicleArea.allCases),
                itemTitle: { $0.displayName }
            )

            InfotainmentField(label: "Date") {
                DatePicker(
                    "Date",
                    selection: $date,
                    displayedComponents: .date
                )
                .labelsHidden()
                .datePickerStyle(.compact)
            }

            InfotainmentField(label: "Mileage") {
                TextField("Mileage", text: $mileage)
                    .keyboardType(.numberPad)
            }

            InfotainmentField(label: "Notes") {
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(4...8)
            }
        }
        .appTheme()
        .onAppear {
            if let historyEntry {
                title = historyEntry.title
                category = historyEntry.category
                vehicleArea = historyEntry.resolvedVehicleArea
                date = historyEntry.date
                notes = historyEntry.details

                if let mileageValue = historyEntry.mileage {
                    mileage = String(mileageValue)
                }
            } else {
                title = initialTitle ?? ""
                category = initialCategory ?? .maintenance
                vehicleArea = initialVehicleArea ?? .misc
                date = initialDate ?? Date()
                notes = ""

                if let initialMileage {
                    mileage = String(initialMileage)
                }
            }
        }
    }

    private func saveEntry() {
        if let historyEntry {
            historyEntry.title = title
            historyEntry.category = category
            historyEntry.vehicleArea = vehicleArea
            historyEntry.date = date
            historyEntry.details = notes
            historyEntry.mileage = Int(mileage)
        } else {
            let newEntry = HistoryEntry(
                title: title,
                details: notes,
                date: date,
                mileage: Int(mileage),
                category: category,
                vehicleArea: vehicleArea,
                vehicle: vehicle
            )

            modelContext.insert(newEntry)
            vehicle.historyEntries.append(newEntry)

            if let completedReminder {
                modelContext.delete(completedReminder)
            }
        }
        dismiss()
    }
}
