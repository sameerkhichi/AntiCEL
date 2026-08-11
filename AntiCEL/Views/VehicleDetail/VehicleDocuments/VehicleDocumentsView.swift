import SwiftUI
import SwiftData

struct VehicleDocumentsView: View {

    @Bindable var vehicle: Vehicle

    @State private var showingNewDocument = false

    private var sortedDocuments: [VehicleDocument] {
        vehicle.documents.sorted { $0.date > $1.date }
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 16) {

            HStack {

                Text("Documents")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                Button {
                    showingNewDocument = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title3)
                }

            }
            .padding(.horizontal)

            Divider()
                .padding(.horizontal)

            if sortedDocuments.isEmpty {

                Text("No documents yet.")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.vertical, 8)

            } else {

                LazyVStack(spacing: 12) {

                    ForEach(sortedDocuments) { document in

                        NavigationLink {

                            VehicleDocumentDetailView(
                                vehicle: vehicle,
                                document: document
                            )

                        } label: {

                            VehicleDocumentRow(document: document)

                        }
                        .buttonStyle(.plain)

                    }

                }

            }

        }
        .padding(.vertical)
        .sheet(isPresented: $showingNewDocument) {

            NavigationStack {
                VehicleDocumentDetailView(vehicle: vehicle)
            }

        }

    }

}

#Preview {
    VehicleDocumentsView(
        vehicle: Vehicle(
            make: "Audi",
            model: "S4",
            year: 2022,
            currentMileage: 79500
        )
    )
}
