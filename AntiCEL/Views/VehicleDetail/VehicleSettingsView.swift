import SwiftUI
import SwiftData

struct VehicleSettingsView: View {

    @Bindable var vehicle: Vehicle

    @State private var year = ""
    @State private var make = ""
    @State private var model = ""
    @State private var nickname = ""
    @State private var vin = ""
    @State private var mileage = ""
    @State private var didSave = false

    var body: some View {

        VStack(alignment: .leading, spacing: 20) {

            settingsCard(title: "Identification") {

                TextField("VIN", text: $vin)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()

            }

            settingsCard(title: "Vehicle Information") {

                TextField("Year", text: $year)
                    .keyboardType(.numberPad)

                Divider()

                TextField("Make", text: $make)

                Divider()

                TextField("Model", text: $model)

                Divider()

                TextField("Nickname", text: $nickname)

                Divider()

                TextField("Mileage", text: $mileage)
                    .keyboardType(.numberPad)

            }

            Button("Save Changes") {
                saveChanges()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .disabled(!canSave)
            .padding(.horizontal)

            if didSave {

                Text("Changes saved.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)

            }

        }
        .padding(.vertical)
        .onAppear {
            loadValues()
        }

    }

    @ViewBuilder
    private func settingsCard<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {

        VStack(alignment: .leading, spacing: 16) {

            Text(title)
                .font(.title3)
                .fontWeight(.semibold)

            Divider()

            content()

        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)

    }

    private var canSave: Bool {
        Int(year) != nil
            && !make.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && Int(mileage) != nil
    }

    private func loadValues() {
        year = String(vehicle.year)
        make = vehicle.make
        model = vehicle.model
        nickname = vehicle.nickname
        vin = vehicle.vin
        mileage = String(vehicle.currentMileage)
        didSave = false
    }

    private func saveChanges() {

        guard
            let yearValue = Int(year),
            let mileageValue = Int(mileage)
        else {
            return
        }

        vehicle.year = yearValue
        vehicle.make = make.trimmingCharacters(in: .whitespacesAndNewlines)
        vehicle.model = model.trimmingCharacters(in: .whitespacesAndNewlines)
        vehicle.nickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        vehicle.vin = vin.trimmingCharacters(in: .whitespacesAndNewlines)
        vehicle.currentMileage = mileageValue
        vehicle.updatedAt = Date()

        didSave = true

    }

}

#Preview {
    VehicleSettingsView(
        vehicle: Vehicle(
            make: "Audi",
            model: "S4",
            year: 2022,
            currentMileage: 79500
        )
    )
}
