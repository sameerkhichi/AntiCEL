import SwiftUI
import SwiftData

struct AddVehicleNoteView: View {

    let vehicle: Vehicle

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var content = ""

    var body: some View {

        NavigationStack {

            Form {

                Section("Title") {

                    TextField(
                        "Optional",
                        text: $title
                    )

                }

                Section("Note") {

                    TextField(
                        "Write your note...",
                        text: $content,
                        axis: .vertical
                    )
                    .lineLimit(8)

                }

            }
            .navigationTitle("New Note")
            .toolbar {

                ToolbarItem(placement: .topBarLeading) {

                    Button("Cancel") {
                        dismiss()
                    }

                }

                ToolbarItem(placement: .topBarTrailing) {

                    Button("Save") {
                        saveNote()
                    }
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                }

            }

        }

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

}
