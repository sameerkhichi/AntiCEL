import SwiftUI
import SwiftData

struct AddVehicleView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var year = ""
    @State private var make = ""
    @State private var model = ""
    @State private var nickname = ""
    @State private var mileage = ""

    private var canSave: Bool {
        Int(year) != nil && Int(mileage) != nil
    }

    var body: some View {
        InfotainmentScaffold(
            title: "Add Vehicle",
            confirmEnabled: canSave,
            onCancel: { dismiss() },
            onConfirm: saveVehicle
        ) {
            InfotainmentSectionHeader(title: "Vehicle Information")

            InfotainmentField(label: "Year") {
                TextField("Year", text: $year)
                    .keyboardType(.numberPad)
            }

            InfotainmentField(label: "Make") {
                TextField("Make", text: $make)
            }

            InfotainmentField(label: "Model") {
                TextField("Model", text: $model)
            }

            InfotainmentField(label: "Nickname") {
                TextField("Optional", text: $nickname)
            }

            InfotainmentField(label: "Mileage") {
                TextField("Mileage", text: $mileage)
                    .keyboardType(.numberPad)
            }
        }
        .appTheme()
    }

    private func saveVehicle() {
        guard let year = Int(year),
              let mileage = Int(mileage)
        else {
            return
        }

        let vehicle = Vehicle(
            make: make,
            model: model,
            year: year,
            nickname: nickname,
            currentMileage: mileage
        )

        modelContext.insert(vehicle)
        dismiss()
    }
}

#Preview {
    AddVehicleView()
        .appTheme()
}
