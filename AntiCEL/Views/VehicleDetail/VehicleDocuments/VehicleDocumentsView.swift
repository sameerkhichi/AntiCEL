import SwiftUI
import SwiftData

struct VehicleDocumentsView: View {

    @Bindable var vehicle: Vehicle

    @State private var showingNewDocument = false
    @State private var showingHint = false

    private var sortedDocuments: [VehicleDocument] {
        vehicle.documents.sorted { $0.date > $1.date }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Documents")
                    .font(.title3.weight(.semibold).width(.condensed))

                HintButton(title: "Documents") {
                    showingHint = true
                }

                Spacer()

                Button {
                    showingNewDocument = true
                } label: {
                    Image(systemName: "plus")
                        .font(.body.weight(.semibold))
                }
                .buttonStyle(DashButtonStyle(kind: .compact))
            }
            .padding(.horizontal)

            Rectangle()
                .fill(.quaternary)
                .frame(height: 1)
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
            VehicleDocumentDetailView(vehicle: vehicle)
        }
        .sheet(isPresented: $showingHint) {
            HintSheet(topic: .documents)
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
    .appTheme()
}
