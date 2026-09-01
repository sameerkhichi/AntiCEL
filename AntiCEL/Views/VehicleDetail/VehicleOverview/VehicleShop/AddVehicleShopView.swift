import SwiftUI
import SwiftData

struct AddVehicleShopView: View {

    let vehicle: Vehicle
    var shop: VehicleShop? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name: String
    @State private var details: String

    private var isEditing: Bool {
        shop != nil
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(vehicle: Vehicle, shop: VehicleShop? = nil) {
        self.vehicle = vehicle
        self.shop = shop
        _name = State(initialValue: shop?.name ?? "")
        _details = State(initialValue: shop?.details ?? "")
    }

    var body: some View {
        InfotainmentScaffold(
            title: isEditing ? "Edit Shop" : "New Shop",
            confirmEnabled: canSave,
            onCancel: { dismiss() },
            onConfirm: saveShop
        ) {
            InfotainmentField(label: "Name") {
                TextField("Shop name", text: $name)
            }

            InfotainmentField(label: "Description") {
                TextField("What this shop is for...", text: $details, axis: .vertical)
                    .lineLimit(8)
            }
        }
        .appTheme()
    }

    private func saveShop() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDetails = details.trimmingCharacters(in: .whitespacesAndNewlines)

        if let shop {
            shop.name = trimmedName
            shop.details = trimmedDetails
            shop.updatedAt = Date()
        } else {
            let shop = VehicleShop(
                name: trimmedName,
                details: trimmedDetails
            )

            vehicle.shops.append(shop)
            modelContext.insert(shop)
        }

        dismiss()
    }
}

#Preview {
    AddVehicleShopView(
        vehicle: Vehicle(
            make: "Audi",
            model: "S4",
            year: 2022,
            currentMileage: 79000
        )
    )
    .appTheme()
}
