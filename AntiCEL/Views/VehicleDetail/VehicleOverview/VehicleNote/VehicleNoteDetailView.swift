import SwiftUI

struct VehicleNoteDetailView: View {

    let note: VehicleNote

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
                    // TODO
                } label: {
                    Text("Edit Note")
                }

                DashButton(kind: .bar, isDestructive: true) {
                    // TODO
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
    NavigationStack {
        VehicleNoteDetailView(
            note: VehicleNote(
                title: "Winter Tires",
                content: "Swap over before the first snowfall."
            )
        )
    }
    .appTheme()
}
