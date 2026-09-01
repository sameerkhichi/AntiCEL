import SwiftUI
import SwiftData

struct AddVehicleNoteView: View {

    let vehicle: Vehicle
    var note: VehicleNote? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title: String
    @State private var content: String

    private var isEditing: Bool {
        note != nil
    }

    private var canSave: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(vehicle: Vehicle, note: VehicleNote? = nil) {
        self.vehicle = vehicle
        self.note = note
        _title = State(initialValue: note?.title ?? "")
        _content = State(initialValue: note?.content ?? "")
    }

    var body: some View {
        InfotainmentScaffold(
            title: isEditing ? "Edit Note" : "New Note",
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

        if let note {
            note.title = finalTitle
            note.content = content
            note.updatedAt = Date()
        } else {
            let note = VehicleNote(
                title: finalTitle,
                content: content
            )

            vehicle.notes.append(note)
            modelContext.insert(note)
        }

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
