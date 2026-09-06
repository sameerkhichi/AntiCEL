import SwiftUI

struct ConnectVehicleReadoutSheet: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(OBDSessionController.self) private var obd

    var body: some View {
        InfotainmentScaffold(
            title: "Vehicle Data",
            confirmTitle: "Done",
            cancelTitle: "Close",
            onCancel: { dismiss() },
            onConfirm: { dismiss() }
        ) {
            if let readout = obd.vehicleReadout {
                InfotainmentField(label: "Adapter") {
                    Text(readout.adapterName)
                }

                InfotainmentField(label: "Vehicle bus") {
                    Text(readout.busAwake
                         ? "The car is answering OBD requests."
                         : "No live data yet. Turn the ignition on and wait a few seconds.")
                    .fixedSize(horizontal: false, vertical: true)
                }

                InfotainmentField(label: "Mileage updates") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(readout.mileageMode.title)
                            .font(.subheadline.weight(.semibold))
                        Text(readout.mileageMode.explanation)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    InfotainmentSectionHeader(title: "What this car sends")
                    ForEach(readout.signals) { signal in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: iconName(for: signal.availability))
                                .foregroundStyle(color(for: signal.availability))
                                .frame(width: 18)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(signal.title)
                                    .font(.subheadline.weight(.medium))
                                Text(signal.statusText)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 4)
                    }
                }
            } else {
                Text("Connect the adapter with the ignition on. AntiCEL will list what this vehicle reports after the first successful read.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .appTheme()
        .onAppear {
            obd.refreshVehicleReadout()
        }
    }

    private func iconName(for availability: OBDSignalAvailability) -> String {
        switch availability {
        case .reported:
            return "checkmark.circle.fill"
        case .supported:
            return "circle.dashed"
        case .notSupported:
            return "xmark.circle"
        case .unknown:
            return "questionmark.circle"
        }
    }

    private func color(for availability: OBDSignalAvailability) -> AnyShapeStyle {
        switch availability {
        case .reported:
            AnyShapeStyle(Color.accentColor)
        case .supported:
            AnyShapeStyle(.secondary)
        case .notSupported, .unknown:
            AnyShapeStyle(.tertiary)
        }
    }
}
