import SwiftUI
import SwiftData

struct HistoryEntryDetailView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var vehicle: Vehicle

    var historyEntry: HistoryEntry?

    @State private var title = ""
    @State private var category: HistoryCategory = .maintenance
    @State private var date = Date()
    @State private var mileage = ""
    @State private var notes = ""

    private var isEditing: Bool {
        historyEntry != nil
    }

    var body: some View {

        Form {

            Section("Details") {

                TextField("Title", text: $title)

                Picker("Category", selection: $category) {

                    ForEach(HistoryCategory.allCases, id: \.self) { category in
                        Text(category.rawValue.capitalized)
                            .tag(category)
                    }
                }

                DatePicker(
                    "Date",
                    selection: $date,
                    displayedComponents: .date
                )

                TextField("Mileage", text: $mileage)
                    .keyboardType(.numberPad)

            }

            Section("Notes") {

                TextField(
                    "Notes",
                    text: $notes,
                    axis: .vertical
                )
                .lineLimit(4...8)

            }

        }
        .navigationTitle(isEditing ? "Edit Entry" : "New Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {

            ToolbarItem(placement: .cancellationAction) {

                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {

                Button("Save") {

                    saveEntry()

                }
                .bold()

            }
        }
        .onAppear {

            guard let historyEntry else { return }

            title = historyEntry.title
            category = historyEntry.category
            date = historyEntry.date
            notes = historyEntry.details

            if let mileageValue = historyEntry.mileage {
                mileage = String(mileageValue)
            }
        }
    }

    private func saveEntry() {

        if let historyEntry {

            historyEntry.title = title
            historyEntry.category = category
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
                vehicle: vehicle
            )

            modelContext.insert(newEntry)
            vehicle.historyEntries.append(newEntry)

        }

        dismiss()

    }

}
