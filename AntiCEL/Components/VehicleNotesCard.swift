import SwiftUI

struct VehicleNotesCard: View {

    let vehicle: Vehicle

    @State private var showingAddNote = false

    var body: some View {

        VStack(alignment: .leading, spacing: 16) {

            HStack {

                Text("Vehicle Notes")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                Button {
                    showingAddNote = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title3)
                }

            }

            Divider()

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
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .sheet(isPresented: $showingAddNote) {

            AddVehicleNoteView(vehicle: vehicle)

        }

    }

}
