import SwiftUI
import SwiftData

struct HistoryEntryDetailView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings

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
    @State private var showingRelatedToHelp = false
    @State private var photoDraft = PhotoDraft()
    @State private var isSaving = false
    @State private var showDeleteAlert = false

    private var isEditing: Bool {
        historyEntry != nil
    }

    var body: some View {
        InfotainmentScaffold(
            title: isEditing ? "Edit Entry" : "New Entry",
            confirmEnabled: !isSaving,
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
                itemTitle: { $0.displayName },
                onHelp: { showingRelatedToHelp = true }
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

            VStack(alignment: .leading, spacing: 8) {
                InfotainmentField(label: "Mileage (\(settings.mileageUnit.abbreviation))") {
                    TextField("Mileage", text: $mileage)
                        .keyboardType(.numberPad)
                }

                HStack {
                    DashButton(kind: .compact) {
                        mileage = String(
                            settings.mileageUnit.displayValue(
                                fromStoredKilometers: vehicle.currentMileage
                            )
                        )
                    } label: {
                        Text("Use Current Mileage")
                    }
                    Spacer(minLength: 0)
                }
            }

            InfotainmentField(label: "Notes") {
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(4...8)
            }

            PhotoAttachmentField(
                label: "Photo",
                footnote: "Optional receipt or proof of the work.",
                draft: $photoDraft
            )

            if isEditing {
                DashButton(kind: .bar, isDestructive: true) {
                    showDeleteAlert = true
                } label: {
                    Text("Delete Entry")
                }
            }
        }
        .appTheme()
        .sheet(isPresented: $showingRelatedToHelp) {
            VehicleAreaHelpSheet()
        }
        .alert(
            "Delete Entry?",
            isPresented: $showDeleteAlert
        ) {
            Button("Delete", role: .destructive) {
                deleteEntry()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This history record will be permanently deleted.")
        }
        .onAppear {
            if let historyEntry {
                title = historyEntry.title
                category = historyEntry.category
                vehicleArea = historyEntry.resolvedVehicleArea
                date = historyEntry.date
                notes = historyEntry.details
                photoDraft.load(from: historyEntry.photoFileName)

                if let mileageValue = historyEntry.mileage {
                    mileage = String(settings.mileageUnit.displayValue(fromStoredKilometers: mileageValue))
                }
            } else {
                title = initialTitle ?? ""
                category = initialCategory ?? .maintenance
                vehicleArea = initialVehicleArea ?? .misc
                date = initialDate ?? Date()
                notes = ""
                photoDraft = PhotoDraft()

                if let initialMileage {
                    mileage = String(settings.mileageUnit.displayValue(fromStoredKilometers: initialMileage))
                }
            }
        }
    }

    private func saveEntry() {
        guard !isSaving else { return }
        isSaving = true

        Task {
            let photoRef = await photoDraft.commit(
                copyIntoApp: settings.savePhotosInApp,
                kind: .attachment
            )

            if let historyEntry {
                historyEntry.title = title
                historyEntry.category = category
                historyEntry.vehicleArea = vehicleArea
                historyEntry.date = date
                historyEntry.details = notes
                historyEntry.mileage = Int(mileage).map { settings.mileageUnit.storedKilometers(fromDisplay: $0) }
                historyEntry.photoFileName = photoRef
            } else {
                let newEntry = HistoryEntry(
                    title: title,
                    details: notes,
                    date: date,
                    mileage: Int(mileage).map { settings.mileageUnit.storedKilometers(fromDisplay: $0) },
                    category: category,
                    vehicleArea: vehicleArea,
                    photoFileName: photoRef,
                    vehicle: vehicle
                )

                modelContext.insert(newEntry)
                vehicle.historyEntries.append(newEntry)

                if let completedReminder {
                    modelContext.delete(completedReminder)
                }
            }
            ReminderNotifications.refresh(using: modelContext)
            dismiss()
        }
    }

    private func deleteEntry() {
        guard let historyEntry else { return }
        PhotoStore.deleteAppFile(historyEntry.photoFileName)
        modelContext.delete(historyEntry)
        ReminderNotifications.refresh(using: modelContext)
        dismiss()
    }
}
