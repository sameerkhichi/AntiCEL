import SwiftUI
import SwiftData

struct ImportVehicleSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let packageURL: URL

    @State private var preview: VehicleShareImporter.Preview?
    @State private var loadError: String?
    @State private var isImporting = false
    @State private var importError: String?

    private var confirmEnabled: Bool {
        preview != nil && !isImporting && loadError == nil
    }

    var body: some View {
        InfotainmentScaffold(
            title: "Add Vehicle",
            confirmTitle: isImporting ? "Adding…" : "Add to Garage",
            cancelTitle: "Close",
            confirmEnabled: confirmEnabled,
            onCancel: { dismiss() },
            onConfirm: importVehicle
        ) {
            if let loadError {
                Text(loadError)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            } else if let preview {
                previewContent(preview)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            }

            if let importError {
                Text(importError)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .appTheme()
        .task {
            loadPreview()
        }
    }

    @ViewBuilder
    private func previewContent(_ preview: VehicleShareImporter.Preview) -> some View {
        let snapshot = preview.snapshot
        let manifest = preview.manifest

        Text(snapshot.displayName)
            .font(.title3.weight(.semibold).width(.condensed))

        Text("\(snapshot.year) \(snapshot.make) \(snapshot.model)")
            .font(.subheadline)
            .foregroundStyle(.secondary)

        Text("This adds a copy to your garage. It won’t stay in sync with the sender.")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)

        InfotainmentSectionHeader(title: "Included")

        InfotainmentField {
            VStack(alignment: .leading, spacing: 10) {
                includeRow("VIN", included: manifest.includeVIN && !snapshot.vin.isEmpty)
                includeRow(
                    "History",
                    included: manifest.includeHistory,
                    detail: countLabel(snapshot.historyEntries.count, singular: "entry", plural: "entries")
                )
                includeRow(
                    "Documents",
                    included: manifest.includeDocuments,
                    detail: countLabel(snapshot.documents.count, singular: "document", plural: "documents")
                )
                includeRow(
                    "Album",
                    included: manifest.includeAlbum,
                    detail: countLabel(snapshot.albumPhotos.count, singular: "photo", plural: "photos")
                )
                includeRow(
                    "Service reminders",
                    included: manifest.includeReminders,
                    detail: countLabel(snapshot.reminders.count, singular: "reminder", plural: "reminders")
                )
                includeRow(
                    "Vehicle notes",
                    included: manifest.includeNotes,
                    detail: countLabel(snapshot.notes.count, singular: "note", plural: "notes")
                )
                includeRow(
                    "Shops",
                    included: manifest.includeShops,
                    detail: countLabel(snapshot.shops.count, singular: "shop", plural: "shops")
                )
            }
        }
    }

    private func includeRow(_ title: String, included: Bool, detail: String? = nil) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.body.weight(.medium))
            Spacer()
            Text(included ? (detail ?? "Included") : "Not included")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func countLabel(_ count: Int, singular: String, plural: String) -> String {
        "\(count) \(count == 1 ? singular : plural)"
    }

    private func loadPreview() {
        do {
            preview = try VehicleShareImporter.preview(from: packageURL)
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func importVehicle() {
        guard !isImporting else { return }

        isImporting = true
        importError = nil

        do {
            _ = try VehicleShareImporter.importVehicle(from: packageURL, into: modelContext)
            dismiss()
        } catch {
            importError = error.localizedDescription
            isImporting = false
        }
    }
}
