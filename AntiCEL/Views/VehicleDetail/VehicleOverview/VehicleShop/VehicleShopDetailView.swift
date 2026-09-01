import SwiftUI
import SwiftData

struct VehicleShopDetailView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let vehicle: Vehicle
    @Bindable var shop: VehicleShop

    @State private var showingEdit = false
    @State private var showDeleteAlert = false

    var body: some View {
        VStack(spacing: 20) {
            DashPanel {
                VStack(alignment: .leading, spacing: 16) {
                    Text(shop.name)
                        .font(.largeTitle.weight(.bold).width(.condensed))

                    Rectangle()
                        .fill(.quaternary)
                        .frame(height: 1)

                    if shop.details.isEmpty {
                        Text("No description.")
                            .foregroundStyle(.secondary)
                    } else {
                        Text(shop.details)
                    }

                    Rectangle()
                        .fill(.quaternary)
                        .frame(height: 1)

                    infoRow(
                        title: "Created",
                        value: shop.createdAt.formatted(
                            date: .abbreviated,
                            time: .shortened
                        )
                    )

                    infoRow(
                        title: "Updated",
                        value: shop.updatedAt.formatted(
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
                    Text("Edit Shop")
                }

                DashButton(kind: .bar, isDestructive: true) {
                    showDeleteAlert = true
                } label: {
                    Text("Delete Shop")
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .padding(.vertical)
        .appCanvas()
        .navigationTitle("Vehicle Shop")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.clear, for: .navigationBar)
        .sheet(isPresented: $showingEdit) {
            AddVehicleShopView(vehicle: vehicle, shop: shop)
        }
        .alert(
            "Delete Shop?",
            isPresented: $showDeleteAlert
        ) {
            Button("Delete", role: .destructive) {
                modelContext.delete(shop)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This shop will be permanently deleted.")
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
        VehicleShopDetailView(
            vehicle: vehicle,
            shop: VehicleShop(
                name: "Eurotech",
                details: "Independent Audi specialist for inspections and suspension work."
            )
        )
    }
    .appTheme()
}
