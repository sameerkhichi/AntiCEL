import SwiftUI

struct VehicleNotesCard: View {

    let vehicle: Vehicle

    @State private var showingAddNote = false
    @State private var showingHint = false

    var body: some View {
        DashPanel {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Vehicle Notes")
                        .font(.title3.weight(.semibold).width(.condensed))

                    HintButton(title: "Vehicle Notes") {
                        showingHint = true
                    }

                    Spacer()

                    Button {
                        showingAddNote = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.body.weight(.semibold))
                    }
                    .buttonStyle(DashButtonStyle(kind: .compact))
                }

                Rectangle()
                    .fill(.quaternary)
                    .frame(height: 1)

                if vehicle.notes.isEmpty {
                    Text("No notes.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(vehicle.notes) { note in
                        NavigationLink(destination: VehicleNoteDetailView(note: note)) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(note.title)
                                    .fontWeight(.semibold)

                                Text(note.content)
                                    .lineLimit(2)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal)
        .sheet(isPresented: $showingAddNote) {
            AddVehicleNoteView(vehicle: vehicle)
        }
        .sheet(isPresented: $showingHint) {
            HintSheet(topic: .vehicleNotes)
        }
    }
}
