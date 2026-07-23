import SwiftUI

struct VehicleNoteDetailView: View {

    let note: VehicleNote

    var body: some View {

        VStack(spacing: 20) {

            VStack(alignment: .leading, spacing: 16) {

                Text(note.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Divider()

                Text(note.content)

                Divider()

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
            .padding()

            Spacer()

            VStack(spacing: 12) {

                Button("Edit Note") {

                    // TODO

                }
                .buttonStyle(.borderedProminent)

                Button("Delete Note") {

                    // TODO

                }
                .foregroundStyle(.red)

            }
            .padding()

        }
        .navigationTitle("Vehicle Note")
        .navigationBarTitleDisplayMode(.inline)

    }

    @ViewBuilder
    private func infoRow(title: String, value: String) -> some View {

        HStack {

            Text(title)

            Spacer()

            Text(value)
                .foregroundStyle(.secondary)

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

}
