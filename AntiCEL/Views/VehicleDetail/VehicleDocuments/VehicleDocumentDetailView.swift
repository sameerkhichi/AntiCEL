import SwiftUI
import SwiftData

struct VehicleDocumentDetailView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings

    @Bindable var vehicle: Vehicle
    var document: VehicleDocument?

    @State private var title = ""
    @State private var category: DocumentCategory = .registration
    @State private var date = Date()
    @State private var hasExpirationDate = false
    @State private var expirationDate = Date()
    @State private var details = ""
    @State private var photoDraft = PhotoDraft()
    @State private var isSaving = false

    private var isEditing: Bool {
        document != nil
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        InfotainmentScaffold(
            title: isEditing ? "Edit Document" : "New Document",
            confirmEnabled: canSave && !isSaving,
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

            PhotoAttachmentField(
                label: "Photo",
                footnote: "Optional photo of the document.",
                draft: $photoDraft
            )

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

                photoDraft.load(from: document.photoFileName)
            }
        }
    }

    private func saveDocument() {
        guard !isSaving else { return }
        isSaving = true

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let expiration = hasExpirationDate ? expirationDate : nil

        Task {
            let photoRef = await photoDraft.commit(
                copyIntoApp: settings.savePhotosInApp,
                kind: .attachment
            )

            if let document {
                document.title = trimmedTitle
                document.category = category
                document.date = date
                document.details = details
                document.expirationDate = expiration
                document.photoFileName = photoRef
                document.updatedAt = Date()
            } else {
                let newDocument = VehicleDocument(
                    title: trimmedTitle,
                    details: details,
                    category: category,
                    date: date,
                    expirationDate: expiration,
                    photoFileName: photoRef,
                    vehicle: vehicle
                )

                modelContext.insert(newDocument)
                vehicle.documents.append(newDocument)
            }

            dismiss()
            ReminderNotifications.refresh(using: modelContext)
        }
    }

    private func deleteDocument() {
        guard let document else { return }
        PhotoStore.deleteAppFile(document.photoFileName)
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
