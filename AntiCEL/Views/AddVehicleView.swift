import SwiftUI
import SwiftData

struct AddVehicleView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings

    @State private var year = ""
    @State private var make = ""
    @State private var model = ""
    @State private var nickname = ""
    @State private var mileage = ""
    @State private var photoDraft = PhotoDraft()
    @State private var isSaving = false

    private var canSave: Bool {
        Int(year) != nil && Int(mileage) != nil && !isSaving
    }

    var body: some View {
        InfotainmentScaffold(
            title: "Add Vehicle",
            confirmEnabled: canSave,
            onCancel: { dismiss() },
            onConfirm: saveVehicle
        ) {
            InfotainmentSectionHeader(title: "Vehicle Information")

            PhotoAttachmentField(
                label: "Vehicle Photo",
                footnote: "Used as the garage bay background. You can reframe it later in vehicle settings.",
                style: .vehicleIcon,
                draft: $photoDraft
            )

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

            InfotainmentField(label: "Mileage (\(settings.mileageUnit.abbreviation))") {
                TextField("Mileage", text: $mileage)
                    .keyboardType(.numberPad)
            }
        }
        .appTheme()
    }

    private func saveVehicle() {
        guard let year = Int(year),
              let mileage = Int(mileage),
              !isSaving
        else {
            return
        }

        isSaving = true

        let vehicle = Vehicle(
            make: make,
            model: model,
            year: year,
            nickname: nickname,
            currentMileage: settings.mileageUnit.storedKilometers(fromDisplay: mileage)
        )

        Task {
            vehicle.photoFileName = await photoDraft.commit(
                copyIntoApp: settings.savePhotosInApp,
                kind: .vehicleIcon
            )
            modelContext.insert(vehicle)
            WidgetReloader.reload()
            dismiss()
        }
    }
}

#Preview {
    AddVehicleView()
        .appTheme()
}
