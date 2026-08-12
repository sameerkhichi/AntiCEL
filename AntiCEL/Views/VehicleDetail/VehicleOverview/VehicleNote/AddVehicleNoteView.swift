import SwiftUI
import SwiftData

struct AddVehicleNoteView: View {

    let vehicle: Vehicle

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var content = ""

    private var canSave: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        InfotainmentScaffold(
            title: "New Note",
            confirmEnabled: canSave,
            onCancel: { dismiss() },
            onConfirm: saveNote
        ) {
            InfotainmentField(label: "Title") {
                TextField("Optional", text: $title)
            }

            InfotainmentField(label: "Note") {
                TextField("Write your note...", text: $content, axis: .vertical)
                    .lineLimit(8)
            }
        }
        .appTheme()
    }

    private func saveNote() {
        let finalTitle: String

        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            finalTitle = String(content.prefix(30))
        } else {
            finalTitle = title
        }

        let note = VehicleNote(
            title: finalTitle,
            content: content
        )

        vehicle.notes.append(note)
        modelContext.insert(note)
        dismiss()
    }
}

#Preview {
    AddVehicleNoteView(
        vehicle: Vehicle(
            make: "Audi",
            model: "S4",
            year: 2022,
            currentMileage: 79000
        )
    )
    .appTheme()
}
