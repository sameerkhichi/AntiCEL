import SwiftUI
import SwiftData

struct VehicleConnectView: View {

    @Bindable var vehicle: Vehicle

    @Environment(\.modelContext) private var modelContext
    @Environment(OBDSessionController.self) private var obd
    @Environment(AppSettings.self) private var settings

    @State private var showingHint = false
    @State private var showingPicker = false
    @State private var showingClearConfirm = false
    @State private var showingForgetConfirm = false

    private var adapter: PairedAdapter? {
        OBDStore.pairedAdapter(on: vehicle)
    }

    private var sortedFaults: [DiagnosticFault] {
        vehicle.diagnosticFaults
            .filter(\.isActive)
            .sorted { $0.lastSeenAt > $1.lastSeenAt }
    }

    private var connectedToThisVehicle: Bool {
        obd.isConnected(to: vehicle.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Connect")
                    .font(.title3.weight(.semibold).width(.condensed))

                HintButton(title: "Connect") {
                    showingHint = true
                }

                Spacer()

                if adapter != nil {
                    Button {
                        showingPicker = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.body.weight(.semibold))
                    }
                    .buttonStyle(DashButtonStyle(kind: .compact))
                    .accessibilityLabel("Scan for adapter")
                }
            }
            .padding(.horizontal)

            Rectangle()
                .fill(.quaternary)
                .frame(height: 1)
                .padding(.horizontal)

            if adapter == nil {
                ConnectEmptyStateView(
                    onScan: { showingPicker = true },
                    onUseMock: {
                        #if DEBUG
                        obd.connectMockAdapter(for: vehicle)
                        #endif
                    }
                )
            } else {
                pairedContent
            }
        }
        .padding(.vertical)
        .sheet(isPresented: $showingHint) {
            HintSheet(topic: .connect)
        }
        .sheet(isPresented: $showingPicker) {
            ConnectDevicePickerSheet(vehicle: vehicle)
                .environment(obd)
        }
        .confirmationDialog(
            "Clear diagnostic codes?",
            isPresented: $showingClearConfirm,
            titleVisibility: .visible
        ) {
            Button("Clear Codes", role: .destructive) {
                Task { await obd.clearCodes(for: vehicle) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This asks the vehicle to clear stored OBD-II codes. It does not repair the fault. Only do this if you understand why the codes are present.")
        }
        .confirmationDialog(
            "Forget this adapter?",
            isPresented: $showingForgetConfirm,
            titleVisibility: .visible
        ) {
            Button("Forget Adapter", role: .destructive) {
                forgetAdapter()
            }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear {
            if adapter != nil, obd.connectionState == .disconnected {
                obd.connectPairedAdapter(for: vehicle)
            }
        }
    }

    private var pairedContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            connectionPanel

            if let adapter {
                ConnectDriveAlertsSection(adapter: adapter)
            }

            #if DEBUG
            if obd.isUsingMockAdapter, connectedToThisVehicle {
                mockTools
            }
            #endif

            if let lastError = obd.lastError, obd.connectedVehicleID == vehicle.id || obd.connectionState == .unsupportedAdapter {
                Text(lastError)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            HStack(spacing: 10) {
                DashButton(kind: .bar) {
                    Task { await obd.scanFaults(for: vehicle) }
                } label: {
                    Text(obd.isScanningFaults ? "Scanning…" : "Scan Now")
                }
                .disabled(!connectedToThisVehicle || obd.isScanningFaults)

                DashButton(kind: .bar) {
                    showingClearConfirm = true
                } label: {
                    Text("Clear Codes")
                }
                .disabled(!connectedToThisVehicle || obd.isClearingCodes)
            }
            .padding(.horizontal)

            if sortedFaults.isEmpty {
                Text(connectedToThisVehicle ? "No faults reported." : "Connect to scan this vehicle for faults.")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            } else {
                Text("Faults")
                    .font(.headline.width(.condensed))
                    .padding(.horizontal)

                LazyVStack(spacing: 12) {
                    ForEach(sortedFaults, id: \.id) { fault in
                        NavigationLink {
                            FaultCodeDetailView(vehicle: vehicle, fault: fault)
                        } label: {
                            FaultCodeRow(fault: fault)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            DashButton(kind: .bar, isDestructive: true) {
                showingForgetConfirm = true
            } label: {
                Text("Forget Adapter")
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }

    private var connectionPanel: some View {
        DashPanel(padding: 14, cornerRadius: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    DashLED(isOn: connectedToThisVehicle)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(adapter?.name ?? "Adapter")
                            .font(.headline)
                        Text(statusText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if obd.connectionState == .disconnected || obd.connectionState == .unsupportedAdapter {
                        DashButton(kind: .compact) {
                            obd.connectPairedAdapter(for: vehicle)
                        } label: {
                            Text("Reconnect")
                        }
                    }
                }

                if connectedToThisVehicle, hasLiveReadings {
                    HStack(spacing: 16) {
                        if let fuel = obd.telemetry.fuelPercent {
                            liveReading(title: "Fuel", value: "\(Int(fuel.rounded()))%")
                        }
                        if let coolant = obd.telemetry.coolantTempC {
                            liveReading(title: "Coolant", value: formattedTemperature(coolant))
                        }
                        if let oil = obd.telemetry.oilTempC {
                            liveReading(title: "Oil", value: formattedTemperature(oil))
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private var hasLiveReadings: Bool {
        obd.telemetry.fuelPercent != nil
            || obd.telemetry.coolantTempC != nil
            || obd.telemetry.oilTempC != nil
    }

    private func liveReading(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold).monospacedDigit())
        }
    }

    private func formattedTemperature(_ celsius: Double) -> String {
        settings.formattedTemperature(celsius)
    }

    #if DEBUG
    private var mockTools: some View {
        DashPanel(padding: 14, cornerRadius: 14) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Mock Adapter")
                    .font(.subheadline.weight(.semibold))
                Text("No dongle is connected. These actions fake a drive so you can check fuel, faults, History, mileage confirmation, and drive alerts.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                DashButton(kind: .bar) {
                    Task { await obd.scanFaults(for: vehicle) }
                } label: {
                    Text("Load Sample Faults")
                }

                DashButton(kind: .bar) {
                    obd.simulateNewDriveFault()
                    Task { await obd.scanFaults(for: vehicle) }
                } label: {
                    Text("Add P0171 This Drive")
                }

                DashButton(kind: .bar) {
                    obd.simulateMileageJump(for: vehicle)
                } label: {
                    Text("Simulate 95 km Trip")
                }

                DashButton(kind: .bar) {
                    obd.simulateLowFuel()
                } label: {
                    Text("Set Fuel to 12%")
                }

                DashButton(kind: .bar) {
                    obd.simulateOverheat()
                } label: {
                    Text("Spike Coolant")
                }

                DashButton(kind: .bar) {
                    obd.simulateOilOverheat()
                } label: {
                    Text("Spike Oil Temp")
                }

                DashButton(kind: .bar) {
                    obd.simulateTripEnd()
                } label: {
                    Text("End Trip (alerts in 15s)")
                }
            }
        }
        .padding(.horizontal)
    }
    #endif

    private var statusText: String {
        if obd.connectedVehicleID == vehicle.id, let message = obd.statusMessage {
            return message
        }
        switch obd.connectionState {
        case .disconnected:
            return "Disconnected"
        case .scanning:
            return "Scanning"
        case .connecting:
            return "Connecting"
        case .initializing:
            return "Talking to adapter"
        case .connected:
            return connectedToThisVehicle ? "Connected" : "Connected to another vehicle"
        case .unsupportedAdapter:
            return "Adapter not supported"
        }
    }

    private func forgetAdapter() {
        if obd.connectedVehicleID == vehicle.id {
            obd.disconnect()
        }
        OBDStore.forgetAdapter(on: vehicle, context: modelContext)
        try? modelContext.save()
    }
}

#Preview {
    VehicleConnectView(
        vehicle: Vehicle(
            make: "Audi",
            model: "S4",
            year: 2022,
            currentMileage: 79500
        )
    )
    .appTheme()
    .environment(OBDSessionController.shared)
}
