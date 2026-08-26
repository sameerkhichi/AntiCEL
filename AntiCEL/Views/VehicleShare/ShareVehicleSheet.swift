import SwiftUI

struct ShareVehicleSheet: View {
    @Environment(\.dismiss) private var dismiss

    let vehicle: Vehicle

    @State private var options = VehicleShareOptions()
    @State private var isExporting = false
    @State private var exportError: String?
    @State private var packagedURL: URL?
    @State private var showingActivity = false
    @State private var exportTask: Task<Void, Never>?

    private var estimate: VehicleShareEstimate {
        VehicleShareExporter.estimate(vehicle: vehicle, options: options)
    }

    private var confirmTitle: String {
        isExporting ? "Preparing…" : "Share"
    }

    var body: some View {
        InfotainmentScaffold(
            title: "Share Vehicle",
            confirmTitle: confirmTitle,
            cancelTitle: "Close",
            confirmEnabled: !isExporting,
            onCancel: { dismiss() },
            onConfirm: share
        ) {
            Text(vehicleTitle)
                .font(.title3.weight(.semibold).width(.condensed))

            Text("Sends a copy of this vehicle. The original stays in your garage.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            InfotainmentSectionHeader(title: "Include")

            includeToggle(
                "VIN",
                subtitle: "Left off unless you want to send it",
                isOn: $options.includeVIN
            )
            includeToggle(
                "History",
                subtitle: countLabel(vehicle.historyEntries.count, singular: "entry", plural: "entries"),
                isOn: $options.includeHistory
            )
            includeToggle(
                "Documents",
                subtitle: "Left off unless you want to send them",
                isOn: $options.includeDocuments
            )
            includeToggle(
                "Album",
                subtitle: countLabel(vehicle.albumPhotos.count, singular: "photo", plural: "photos"),
                isOn: $options.includeAlbum
            )
            includeToggle(
                "Service reminders",
                subtitle: countLabel(vehicle.serviceReminders.count, singular: "reminder", plural: "reminders"),
                isOn: $options.includeReminders
            )
            includeToggle(
                "Vehicle notes",
                subtitle: countLabel(vehicle.notes.count, singular: "note", plural: "notes"),
                isOn: $options.includeNotes
            )
            includeToggle(
                "Shops",
                subtitle: countLabel(vehicle.shops.count, singular: "shop", plural: "shops"),
                isOn: $options.includeShops
            )

            Text("About \(formattedSize(estimate.byteCount))")
                .font(.footnote)
                .foregroundStyle(.secondary)

            if estimate.skippedPhotoCount > 0 {
                Text(skippedPhotoMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let exportError {
                Text(exportError)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .appTheme()
        .interactiveDismissDisabled(isExporting)
        .sheet(isPresented: $showingActivity, onDismiss: cleanupPackage) {
            if let packagedURL {
                ShareActivityView(url: packagedURL) {
                    showingActivity = false
                }
                .ignoresSafeArea()
            }
        }
        .onDisappear {
            exportTask?.cancel()
            if !showingActivity {
                cleanupPackage()
            }
        }
    }

    private var vehicleTitle: String {
        if !vehicle.nickname.isEmpty {
            return vehicle.nickname
        }
        return "\(vehicle.year) \(vehicle.make) \(vehicle.model)"
    }

    private var skippedPhotoMessage: String {
        let count = estimate.skippedPhotoCount
        if count == 1 {
            return "1 photo is only in your camera roll and can’t be included."
        }
        return "\(count) photos are only in your camera roll and can’t be included."
    }

    private func includeToggle(_ title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        InfotainmentField {
            Toggle(isOn: isOn) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body.weight(.medium))
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .tint(Color.accentColor)
        }
    }

    private func countLabel(_ count: Int, singular: String, plural: String) -> String {
        "\(count) \(count == 1 ? singular : plural)"
    }

    private func formattedSize(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    private func share() {
        guard !isExporting else { return }

        isExporting = true
        exportError = nil
        cleanupPackage()

        exportTask = Task {
            do {
                let url = try await VehicleShareExporter.export(vehicle: vehicle, options: options)
                if Task.isCancelled {
                    try? FileManager.default.removeItem(at: url)
                } else {
                    packagedURL = url
                    showingActivity = true
                }
            } catch is CancellationError {
                ()
            } catch {
                if !Task.isCancelled {
                    exportError = error.localizedDescription
                }
            }
            isExporting = false
        }
    }

    private func cleanupPackage() {
        if let packagedURL {
            try? FileManager.default.removeItem(at: packagedURL)
        }
        packagedURL = nil
    }
}
