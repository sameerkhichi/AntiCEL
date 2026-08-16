import SwiftUI
import SwiftData

struct UpdateMileageView: View {

    @Bindable var vehicle: Vehicle

    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var settings

    @State private var mileage: String

    private let digitCount = 6

    init(vehicle: Vehicle) {
        self.vehicle = vehicle
        _mileage = State(
            initialValue: String(
                AppSettings.shared.mileageUnit.displayValue(fromStoredKilometers: vehicle.currentMileage)
            )
        )
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

    private var mileageValueBinding: Binding<Int> {
        Binding(
            get: { parsedMileage ?? 0 },
            set: { mileage = String($0) }
        )
    }

    var body: some View {
        InfotainmentScaffold(
            title: "Update Mileage",
            confirmEnabled: canSave,
            scrolls: false,
            onCancel: { dismiss() },
            onConfirm: saveMileage
        ) {
            OdometerView(
                mileage: settings.mileageUnit.storedKilometers(fromDisplay: parsedMileage ?? 0)
            )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)

            InfotainmentField(label: "Mileage (\(settings.mileageUnit.abbreviation))") {
                TextField("Current mileage", text: $mileage)
                    .keyboardType(.numberPad)
                    .onChange(of: mileage) { _, newValue in
                        let digitsOnly = newValue.filter(\.isNumber)
                        if digitsOnly.count > digitCount {
                            mileage = String(digitsOnly.prefix(digitCount))
                        } else if digitsOnly != newValue {
                            mileage = digitsOnly
                        }
                    }
            }

            Spacer(minLength: 12)

            MileageDigitScroller(
                mileage: mileageValueBinding,
                digitCount: digitCount
            )
            .frame(maxWidth: .infinity)

            Spacer(minLength: 12)
        }
        .appTheme()
    }

    private func saveMileage() {
        guard let parsedMileage else {
            return
        }

        vehicle.currentMileage = settings.mileageUnit.storedKilometers(fromDisplay: parsedMileage)
        vehicle.updatedAt = Date()
        WidgetReloader.reload()
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
