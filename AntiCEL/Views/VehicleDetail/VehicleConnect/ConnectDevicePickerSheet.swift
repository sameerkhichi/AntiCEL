import SwiftUI

struct ConnectDevicePickerSheet: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(OBDSessionController.self) private var obd

    let vehicle: Vehicle

    @State private var showAllNamedDevices = false

    var body: some View {
        InfotainmentScaffold(
            title: "Adapters",
            confirmTitle: "Done",
            cancelTitle: "Cancel",
            confirmEnabled: true,
            onCancel: close,
            onConfirm: close
        ) {
            Text("Choose a BLE ELM327 adapter. Veepeak OBDCheck BLE+ is recommended. Connect from AntiCEL, not from iOS Settings.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let lastError = obd.lastError {
                Text(lastError)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            if obd.discoveredDevices.isEmpty {
                Text(obd.connectionState == .scanning ? "Scanning for adapters…" : "No adapters found yet.")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 10) {
                    ForEach(obd.discoveredDevices) { device in
                        DashPanel(padding: 14, cornerRadius: 14) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(device.name)
                                        .font(.headline)
                                    Text("Signal \(device.rssi) dBm")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                DashButton(kind: .compact) {
                                    pair(device)
                                } label: {
                                    Text("Connect")
                                }
                            }
                        }
                    }
                }
            }

            Toggle("Show other named BLE devices", isOn: $showAllNamedDevices)
                .font(.subheadline)
                .onChange(of: showAllNamedDevices) { _, value in
                    obd.startScanning(showAllNamedDevices: value)
                }
        }
        .onAppear {
            obd.startScanning(showAllNamedDevices: showAllNamedDevices)
        }
        .onDisappear {
            if obd.connectionState == .scanning {
                obd.stopScanning()
            }
        }
        .appTheme()
    }

    private func pair(_ device: OBDDiscoveredDevice) {
        if let context = vehicle.modelContext {
            OBDStore.pair(
                vehicle: vehicle,
                peripheralIdentifier: device.id,
                name: device.name,
                context: context
            )
            try? context.save()
        }
        obd.connect(to: device, vehicleID: vehicle.id)
        dismiss()
    }

    private func close() {
        if obd.connectionState == .scanning {
            obd.stopScanning()
        }
        dismiss()
    }
}
