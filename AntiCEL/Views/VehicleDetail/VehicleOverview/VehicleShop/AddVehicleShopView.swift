import SwiftUI
import SwiftData

struct AddVehicleShopView: View {

    let vehicle: Vehicle

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var details = ""

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        InfotainmentScaffold(
            title: "New Shop",
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
        let shop = VehicleShop(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            details: details.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        vehicle.shops.append(shop)
        modelContext.insert(shop)
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
