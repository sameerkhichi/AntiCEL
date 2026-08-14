import SwiftUI
import SwiftData

struct UpdateMileageView: View {

    @Bindable var vehicle: Vehicle

    @Environment(\.dismiss) private var dismiss

    @State private var mileage: String

    init(vehicle: Vehicle) {
        self.vehicle = vehicle
        _mileage = State(initialValue: String(vehicle.currentMileage))
    }

    private var parsedMileage: Int? {
        guard let value = Int(mileage), value >= 0 else {
            return nil
        }
        return value
    }

    private var canSave: Bool {
        parsedMileage != nil
    }

    var body: some View {
        InfotainmentScaffold(
            title: "Update Mileage",
            confirmEnabled: canSave,
            onCancel: { dismiss() },
            onConfirm: saveMileage
        ) {
            OdometerView(mileage: parsedMileage ?? 0)
                .frame(maxWidth: .infinity)
                .padding(.trailing, 26)
                .padding(.vertical, 8)

            InfotainmentField(label: "Mileage") {
                TextField("Current mileage", text: $mileage)
                    .keyboardType(.numberPad)
            }
        }
        .appTheme()
    }

    private func saveMileage() {
        guard let parsedMileage else {
            return
        }

        vehicle.currentMileage = parsedMileage
        vehicle.updatedAt = Date()
        dismiss()
    }
}

#Preview {
    UpdateMileageView(
        vehicle: Vehicle(
            make: "Audi",
            model: "S4",
            year: 2022,
            currentMileage: 79500
        )
    )
    .appTheme()
}
