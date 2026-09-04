import SwiftUI
import SwiftData

struct FaultCodeDetailView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings

    let vehicle: Vehicle
    let fault: DiagnosticFault

    var body: some View {
        InfotainmentScaffold(
            title: fault.code,
            confirmTitle: "Done",
            cancelTitle: "Close",
            onCancel: { dismiss() },
            onConfirm: { dismiss() }
        ) {
            InfotainmentField(label: "Code") {
                Text(DTCDictionary.normalizedCode(fault.code))
                    .font(.body.monospaced())
            }

            InfotainmentField(label: "Status") {
                Text(fault.status.displayName + (fault.isActive ? "" : " · Cleared"))
            }

            InfotainmentField(label: "Description") {
                Text(DTCDictionary.description(for: fault.code))
                    .fixedSize(horizontal: false, vertical: true)
            }

            InfotainmentField(label: "First seen") {
                Text(fault.firstSeenAt.formatted(date: .abbreviated, time: .shortened))
            }

            InfotainmentField(label: "Mileage") {
                Text(settings.formattedMileage(fault.mileageAtFirstSeen))
            }

            InfotainmentField(label: "Related to") {
                Text(DTCHistoryMapper.vehicleArea(for: fault.code).displayName)
            }

            if !fault.promotedToHistory {
                DashButton(kind: .bar) {
                    OBDStore.promoteIfNeeded(fault, onto: vehicle, context: modelContext)
                    try? modelContext.save()
                } label: {
                    Text("Add to History")
                }
            } else {
                Text("Saved to History with this mileage and code.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .appTheme()
    }
}
