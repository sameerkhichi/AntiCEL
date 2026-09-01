import SwiftUI
import SwiftData

struct VehicleNoteDetailView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let vehicle: Vehicle
    @Bindable var note: VehicleNote

    @State private var showingEdit = false
    @State private var showDeleteAlert = false

    var body: some View {
        VStack(spacing: 20) {
            DashPanel {
                VStack(alignment: .leading, spacing: 16) {
                    Text(note.title)
                        .font(.largeTitle.weight(.bold).width(.condensed))

                    Rectangle()
                        .fill(.quaternary)
                        .frame(height: 1)

                    Text(note.content)

                    Rectangle()
                        .fill(.quaternary)
                        .frame(height: 1)

                    infoRow(
                        title: "Created",
                        value: note.createdAt.formatted(
                            date: .abbreviated,
                            time: .shortened
                        )
                    )

                    infoRow(
                        title: "Updated",
                        value: note.updatedAt.formatted(
                            date: .abbreviated,
                            time: .shortened
                        )
                    )
                }
            }
            .padding(.horizontal)

            Spacer()

            VStack(spacing: 12) {
                DashButton(isSelected: true, kind: .bar) {
                    showingEdit = true
                } label: {
                    Text("Edit Note")
                }

                DashButton(kind: .bar, isDestructive: true) {
                    showDeleteAlert = true
                } label: {
                    Text("Delete Note")
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .padding(.vertical)
        .appCanvas()
        .navigationTitle("Vehicle Note")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.clear, for: .navigationBar)
        .sheet(isPresented: $showingEdit) {
            AddVehicleNoteView(vehicle: vehicle, note: note)
        }
        .alert(
            "Delete Note?",
            isPresented: $showDeleteAlert
        ) {
            Button("Delete", role: .destructive) {
                modelContext.delete(note)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This note will be permanently deleted.")
        }
    }

    @ViewBuilder
    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.appBadge)
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    let vehicle = Vehicle(
        make: "Audi",
        model: "S4",
        year: 2022,
        currentMileage: 79000
    )

    NavigationStack {
        VehicleNoteDetailView(
            vehicle: vehicle,
            note: VehicleNote(
                title: "Winter Tires",
                content: "Swap over before the first snowfall."
            )
        )
    }
    .appTheme()
}
