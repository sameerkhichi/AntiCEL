import SwiftUI

struct VehicleShopDetailView: View {

    let shop: VehicleShop

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
                    // TODO
                } label: {
                    Text("Edit Shop")
                }

                DashButton(kind: .bar, isDestructive: true) {
                    // TODO
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
        VehicleShopDetailView(
            shop: VehicleShop(
                name: "Eurotech",
                details: "Independent Audi specialist for inspections and suspension work."
            )
        )
    }
    .appTheme()
}
