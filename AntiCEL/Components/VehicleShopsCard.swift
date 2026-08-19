import SwiftUI

struct VehicleShopsCard: View {

    let vehicle: Vehicle

    @State private var showingAddShop = false
    @State private var showingHint = false

    var body: some View {
        DashPanel {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Vehicle Shops")
                        .font(.title3.weight(.semibold).width(.condensed))

                    HintButton(title: "Vehicle Shops") {
                        showingHint = true
                    }

                    Spacer()

                    Button {
                        showingAddShop = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.body.weight(.semibold))
                    }
                    .buttonStyle(DashButtonStyle(kind: .compact))
                }

                Rectangle()
                    .fill(.quaternary)
                    .frame(height: 1)

                if vehicle.shops.isEmpty {
                    Text("No shops.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(vehicle.shops) { shop in
                        NavigationLink(destination: VehicleShopDetailView(shop: shop)) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(shop.name)
                                    .fontWeight(.semibold)

                                if !shop.details.isEmpty {
                                    Text(shop.details)
                                        .lineLimit(2)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
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
        .sheet(isPresented: $showingAddShop) {
            AddVehicleShopView(vehicle: vehicle)
        }
        .sheet(isPresented: $showingHint) {
            HintSheet(topic: .vehicleShops)
        }
    }
}
