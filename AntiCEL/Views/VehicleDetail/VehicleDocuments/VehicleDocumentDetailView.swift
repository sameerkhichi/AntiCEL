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

    var body: some View {

        Form {

            Section("Details") {

                TextField("Title", text: $title)

                Picker("Category", selection: $category) {

                    ForEach(DocumentCategory.allCases, id: \.self) { category in
                        Text(category.displayName)
                            .tag(category)
                    }

                }

                DatePicker(
                    "Date",
                    selection: $date,
                    displayedComponents: .date
                )

                Toggle("Expires", isOn: $hasExpirationDate)

                if hasExpirationDate {

                    DatePicker(
                        "Expiration Date",
                        selection: $expirationDate,
                        displayedComponents: .date
                    )

                }

            }

            Section("Notes") {

                TextField(
                    "Optional notes...",
                    text: $details,
                    axis: .vertical
                )
                .lineLimit(4...8)

            }

            if isEditing {

                Section {

                    Button("Delete Document", role: .destructive) {
                        deleteDocument()
                    }

                }

            }

        }
        .navigationTitle(isEditing ? "Edit Document" : "New Document")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {

            ToolbarItem(placement: .cancellationAction) {

                Button("Cancel") {
                    dismiss()
                }

            }

            ToolbarItem(placement: .confirmationAction) {

                Button("Save") {
                    saveDocument()
                }
                .bold()
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            }

        }
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

    }

    private func deleteDocument() {

        guard let document else { return }

        modelContext.delete(document)
        dismiss()

    }

}

#Preview {

    NavigationStack {

        VehicleDocumentDetailView(
            vehicle: Vehicle(
                make: "Audi",
                model: "S4",
                year: 2022,
                currentMileage: 79500
            )
        )

    }

}
