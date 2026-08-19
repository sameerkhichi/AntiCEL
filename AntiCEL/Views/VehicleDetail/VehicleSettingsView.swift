import SwiftUI
import SwiftData

struct VehicleSettingsView: View {

    @Bindable var vehicle: Vehicle

    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings

    @State private var year = ""
    @State private var make = ""
    @State private var model = ""
    @State private var nickname = ""
    @State private var vin = ""
    @State private var mileage = ""
    @State private var didSave = false
    @State private var photoDraft = PhotoDraft()
    @State private var photoFraming = PhotoFraming.identity
    @State private var isSaving = false
    @State private var showingPhotoFramer = false

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
                        footnote: "Used as the garage bay background. You can reframe it below.",
                        style: .vehicleIcon,
                        usesInfotainmentChrome: false,
                        showsImagePreview: false,
                        draft: $photoDraft
                    )

                    if photoDraft.hasPhoto {
                        vehiclePhotoFramingPreview
                    }

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
        .onChange(of: photoDraft.pickGeneration) {
            photoFraming = .identity
        }
        .sheet(isPresented: $showingPhotoFramer) {
            if let image = photoDraft.preview {
                PhotoFramingEditorSheet(
                    image: image,
                    framing: $photoFraming,
                    year: Int(year) ?? vehicle.year,
                    make: make.isEmpty ? vehicle.make : make,
                    model: model.isEmpty ? vehicle.model : model,
                    nickname: nickname,
                    mileage: vehicle.currentMileage
                )
            }
        }
    }

    @ViewBuilder
    private var vehiclePhotoFramingPreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                showingPhotoFramer = photoDraft.preview != nil
            } label: {
                ZStack(alignment: .bottom) {
                    Color.black

                    if let preview = photoDraft.preview {
                        FramedPhotoView(image: preview, framing: photoFraming)
                    } else {
                        StoredPhotoView(ref: photoDraft.originalRef, framing: photoFraming) {
                            Color.black.opacity(0.35)
                        }
                    }

                    VehiclePhotoScrim()

                    VStack(spacing: 4) {
                        Text("Tap to adjust frame")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.white.opacity(0.92))
                            .shadow(color: .black.opacity(0.45), radius: 4, y: 1)
                    }
                    .padding(.bottom, 14)
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(1.5, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
            .disabled(photoDraft.preview == nil)

            Text("Drag and pinch in the editor if the roof or nose is getting cropped in the garage.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
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
        photoFraming = vehicle.photoFraming
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
            if vehicle.photoFileName == nil {
                vehicle.applyPhotoFraming(.identity)
            } else {
                vehicle.applyPhotoFraming(photoFraming)
            }
            photoDraft.load(from: vehicle.photoFileName)
            didSave = true
            isSaving = false
            WidgetReloader.reload()
            ReminderNotifications.refresh(using: modelContext)
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
