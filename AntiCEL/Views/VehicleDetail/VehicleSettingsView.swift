import SwiftUI
import SwiftData

struct VehicleSettingsView: View {

    @Bindable var vehicle: Vehicle

    @Environment(AppSettings.self) private var settings

    @State private var year = ""
    @State private var make = ""
    @State private var model = ""
    @State private var nickname = ""
    @State private var vin = ""
    @State private var mileage = ""
    @State private var didSave = false
    @State private var photoDraft = PhotoDraft()
    @State private var isSaving = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            DashPanel {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Identification")
                        .font(.title3.weight(.semibold).width(.condensed))

                    Rectangle()
                        .fill(.quaternary)
                        .frame(height: 1)

                    PhotoAttachmentField(
                        label: "Vehicle Photo",
                        footnote: "Used as the icon in your garage.",
                        style: .vehicleIcon,
                        usesInfotainmentChrome: false,
                        draft: $photoDraft
                    )

                    Rectangle()
                        .fill(.quaternary)
                        .frame(height: 1)

                    TextField("VIN", text: $vin)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }
            }
            .padding(.horizontal)

            DashPanel {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Vehicle Information")
                        .font(.title3.weight(.semibold).width(.condensed))

                    Rectangle()
                        .fill(.quaternary)
                        .frame(height: 1)

                    TextField("Year", text: $year)
                        .keyboardType(.numberPad)

                    Rectangle()
                        .fill(.quaternary)
                        .frame(height: 1)

                    TextField("Make", text: $make)

                    Rectangle()
                        .fill(.quaternary)
                        .frame(height: 1)

                    TextField("Model", text: $model)

                    Rectangle()
                        .fill(.quaternary)
                        .frame(height: 1)

                    TextField("Nickname", text: $nickname)

                    Rectangle()
                        .fill(.quaternary)
                        .frame(height: 1)

                    TextField("Mileage (\(settings.mileageUnit.abbreviation))", text: $mileage)
                        .keyboardType(.numberPad)
                }
            }
            .padding(.horizontal)

            DashButton(isSelected: canSave, kind: .bar, action: saveChanges) {
                Text("Save Changes")
            }
            .disabled(!canSave || isSaving)
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
        mileage = String(
            settings.mileageUnit.displayValue(fromStoredKilometers: vehicle.currentMileage)
        )
        photoDraft.load(from: vehicle.photoFileName)
        didSave = false
    }

    private func saveChanges() {
        guard
            !isSaving,
            let yearValue = Int(year),
            let mileageValue = Int(mileage)
        else {
            return
        }

        isSaving = true

        vehicle.year = yearValue
        vehicle.make = make.trimmingCharacters(in: .whitespacesAndNewlines)
        vehicle.model = model.trimmingCharacters(in: .whitespacesAndNewlines)
        vehicle.nickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        vehicle.vin = vin.trimmingCharacters(in: .whitespacesAndNewlines)
        vehicle.currentMileage = settings.mileageUnit.storedKilometers(fromDisplay: mileageValue)
        vehicle.updatedAt = Date()

        Task {
            vehicle.photoFileName = await photoDraft.commit(
                copyIntoApp: settings.savePhotosInApp,
                kind: .vehicleIcon
            )
            photoDraft.load(from: vehicle.photoFileName)
            didSave = true
            isSaving = false
            WidgetReloader.reload()
        }
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
    .appTheme()
}
