import SwiftUI
import SwiftData

struct VehicleDocumentDetailView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var vehicle: Vehicle
    var document: VehicleDocument?

    @State private var title = ""
    @State private var category: DocumentCategory = .registration
    @State private var date = Date()
    @State private var hasExpirationDate = false
    @State private var expirationDate = Date()
    @State private var details = ""

    private var isEditing: Bool {
        document != nil
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        InfotainmentScaffold(
            title: isEditing ? "Edit Document" : "New Document",
            confirmEnabled: canSave,
            onCancel: { dismiss() },
            onConfirm: saveDocument
        ) {
            InfotainmentField(label: "Title") {
                TextField("Title", text: $title)
            }

            InfotainmentChipPicker(
                title: "Category",
                selection: $category,
                options: Array(DocumentCategory.allCases),
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

            InfotainmentField(label: "Expires") {
                Toggle("Expires", isOn: $hasExpirationDate)
            }

            if hasExpirationDate {
                InfotainmentField(label: "Expiration Date") {
                    DatePicker(
                        "Expiration Date",
                        selection: $expirationDate,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                }
            }

            InfotainmentField(label: "Notes") {
                TextField("Optional notes...", text: $details, axis: .vertical)
                    .lineLimit(4...8)
            }

            if isEditing {
                DashButton(kind: .bar, isDestructive: true, action: deleteDocument) {
                    Text("Delete Document")
                }
            }
        }
        .appTheme()
        .onAppear {
            if let document {
                title = document.title
                category = document.category
                date = document.date
                details = document.details

                if let expiration = document.expirationDate {
                    hasExpirationDate = true
                    expirationDate = expiration
                }
            }
        }
    }

    private func saveDocument() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let expiration = hasExpirationDate ? expirationDate : nil

        if let document {
            document.title = trimmedTitle
            document.category = category
            document.date = date
            document.details = details
            document.expirationDate = expiration
            document.updatedAt = Date()
        } else {
            let newDocument = VehicleDocument(
                title: trimmedTitle,
                details: details,
                category: category,
                date: date,
                expirationDate: expiration,
                vehicle: vehicle
            )

            modelContext.insert(newDocument)
            vehicle.documents.append(newDocument)
        }

        dismiss()
        ReminderNotifications.refresh(using: modelContext)
    }

    private func deleteDocument() {
        guard let document else { return }
        modelContext.delete(document)
        ReminderNotifications.refresh(using: modelContext)
        dismiss()
    }
}

#Preview {
    VehicleDocumentDetailView(
        vehicle: Vehicle(
            make: "Audi",
            model: "S4",
            year: 2022,
            currentMileage: 79500
        )
    )
    .appTheme()
}
