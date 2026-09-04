import CoreBluetooth
import Foundation
import SwiftData

@Observable
final class OBDSessionController: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    static let shared = OBDSessionController()

    var bluetoothState: CBManagerState = .unknown
    var connectionState: OBDConnectionState = .disconnected
    var discoveredDevices: [OBDDiscoveredDevice] = []
    var connectedVehicleID: UUID?
    var connectedAdapterName: String?
    var lastError: String?
    var isScanningFaults = false
    var isClearingCodes = false
    var telemetry = OBDLiveTelemetry()
    var mileageJump: MileageJumpProposal?
    var statusMessage: String?
    var appliedMileageKm: Int?
    var isUsingMockAdapter = false

    var modelContainer: ModelContainer?

    var isForeground = true
    var fuelPercent: Double? { telemetry.fuelPercent }

    func isConnected(to vehicleID: UUID) -> Bool {
        connectionState == .connected && connectedVehicleID == vehicleID
    }

    var isBusy: Bool {
        switch connectionState {
        case .scanning, .connecting, .initializing:
            return true
        case .disconnected, .connected, .unsupportedAdapter:
            return false
        }
    }

    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?
    private var notifyCharacteristic: CBCharacteristic?
    private var pendingDiscoveries = 0
    private var pendingServiceIDs: Set<CBUUID> = []
    private var knownPeripherals: [UUID: CBPeripheral] = [:]
    private var advertisementNames: [UUID: String] = [:]
    private var showAllNamedDevices = false

    private var responseBuffer = ""
    private var pendingCommand: CheckedContinuation<String, Error>?
    private var timeoutTask: Task<Void, Never>?
    private var commandLock = false
    private var monitorTask: Task<Void, Never>?
    private var lastSpeedSample: (speed: Double, at: Date)?
    private var tripDistanceKm: Double = 0
    private var supportedPIDs: Set<UInt8> = []
    private var didApplyOdometerThisTrip = false
    private var connectingVehicleID: UUID?
    private var connectingPeripheralID: UUID?

    private let largeJumpKm = 80
    private let ecuSilenceTicks = 12
    private var suppressReconnect = false
    private static let connectLockedMessage = "Your Connect trial has ended. Choose a plan to keep using live OBD."

    private var tripStartedAt: Date?
    private var tripBaselineFaults: Set<String>?
    private var tripNewFaults: [String] = []
    private var lastFuelPercent: Double?
    private var maxCoolantC: Double?
    private var maxOilTempC: Double?
    private var consecutiveECUMisses = 0
    private var didScheduleTripEndAlerts = false
    private var handshakeTask: Task<Void, Never>?
    private var forgetIfUnsupported = false
    private var receivedNonElmTraffic = false
    private var uartPairs: [CBUUID: (notify: CBCharacteristic?, write: CBCharacteristic?)] = [:]
    private var probeNotifyCharacteristics: [CBCharacteristic] = []
    private var probeWriteCharacteristics: [CBCharacteristic] = []
    private var didDiscoverAllServices = false
    private var commandAwaitingResponse = false
    private var writeUsesWithoutResponse: Bool?
    private var commandTerminator = "\r"
    private var didEnableNotify = false
    private var notifyReadyContinuation: CheckedContinuation<Void, Never>?
    private var writeReadyContinuation: CheckedContinuation<Void, Never>?
    private var writeGeneration = 0
    private var idleNotifyBuffer = ""
    private var allCharacteristics: [CBCharacteristic] = []

    #if DEBUG
    private var mockFaults: [OBDFaultReading] = OBDMockAdapter.sampleFaults
    private var mockCoolantC: Double = OBDMockAdapter.coolantTempC
    private var mockOilTempC: Double = OBDMockAdapter.oilTempC
    #endif

    override init() {
        super.init()
        central = CBCentralManager(
            delegate: self,
            queue: .main,
            options: [CBCentralManagerOptionRestoreIdentifierKey: OBDAdapterProfile.restoreIdentifier]
        )
    }

    func startScanning(showAllNamedDevices: Bool = false) {
        lastError = nil
        self.showAllNamedDevices = showAllNamedDevices
        discoveredDevices = []
        #if DEBUG
        discoveredDevices = [OBDMockAdapter.discoveredDevice]
        #endif
        guard connectionState != .connected && connectionState != .connecting && connectionState != .initializing else {
            return
        }

        guard central.state == .poweredOn else {
            #if DEBUG
            connectionState = .scanning
            return
            #else
            lastError = OBDError.bluetoothUnavailable.errorDescription
            return
            #endif
        }

        connectionState = .scanning
        central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }

    func stopScanning() {
        central.stopScan()
        if connectionState == .scanning {
            connectionState = peripheral == nil ? .disconnected : connectionState
        }
    }

    func connect(to device: OBDDiscoveredDevice, vehicleID: UUID) {
        guard !denyIfConnectLocked(userFacing: true) else { return }
        #if DEBUG
        if device.id == OBDMockAdapter.identifier {
            startMockSession(vehicleID: vehicleID, name: device.name)
            return
        }
        #endif
        guard let match = knownPeripherals[device.id] else {
            lastError = "The adapter is no longer in range. Scan again."
            return
        }
        forgetIfUnsupported = true
        connect(peripheral: match, vehicleID: vehicleID)
    }

    func connectPairedAdapter(for vehicle: Vehicle) {
        guard !denyIfConnectLocked(userFacing: true) else { return }
        guard let adapter = OBDStore.pairedAdapter(on: vehicle) else { return }
        forgetIfUnsupported = false
        if let peripheral, peripheral.identifier == adapter.peripheralIdentifier, peripheral.state == .connected {
            retryHandshake()
            return
        }
        connect(identifier: adapter.peripheralIdentifier, vehicleID: vehicle.id, name: adapter.name)
    }

    func reconnectKnownAdapters() {
        guard !denyIfConnectLocked(userFacing: false) else { return }
        guard connectionState == .disconnected else { return }

        #if DEBUG
        let paired = OBDStore.allPairedAdapters()
        if let mock = paired.first(where: { $0.peripheralIdentifier == OBDMockAdapter.identifier }) {
            startMockSession(vehicleID: mock.vehicleID, name: mock.name)
            return
        }
        #endif

        forgetIfUnsupported = false
        guard central.state == .poweredOn else { return }

        let pairedAdapters = OBDStore.allPairedAdapters()
        for item in pairedAdapters {
            connect(identifier: item.peripheralIdentifier, vehicleID: item.vehicleID, name: item.name)
        }
    }

    func disconnect() {
        suppressReconnect = true
        monitorTask?.cancel()
        monitorTask = nil
        if let vehicleID = connectedVehicleID {
            OBDDriveNotifications.cancel(vehicleID: vehicleID)
        }
        finishTripMileageIfNeeded()
        failPendingCommand(OBDError.notConnected)
        if let peripheral {
            central.cancelPeripheralConnection(peripheral)
        }
        resetConnection(keepVehicle: false)
    }

    func enforceConnectAccess() {
        let store = ConnectEntitlementStore.shared
        if store.hasAccess { return }
        if store.status == .notStarted { return }
        switch connectionState {
        case .disconnected, .unsupportedAdapter, .scanning:
            return
        case .connecting, .initializing, .connected:
            lastError = Self.connectLockedMessage
            disconnect()
        }
    }

    func scanFaults(for vehicle: Vehicle) async {
        guard connectionState == .connected else { return }
        isScanningFaults = true
        defer { isScanningFaults = false }

        do {
            let readings = try await currentFaultReadings()
            let milOn = telemetry.milOn ?? false
            guard let context = vehicle.modelContext else { return }
            OBDStore.upsertFaults(readings, onto: vehicle, milOn: milOn, context: context)
            vehicle.updatedAt = Date()
            try? context.save()
            noteTripFaults(readings)
            statusMessage = readings.isEmpty ? "No faults reported" : nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func clearCodes(for vehicle: Vehicle) async {
        guard connectionState == .connected else { return }
        isClearingCodes = true
        defer { isClearingCodes = false }

        do {
            #if DEBUG
            if isUsingMockAdapter {
                mockFaults = []
                telemetry.milOn = false
                telemetry.dtcCount = 0
                await scanFaults(for: vehicle)
                return
            }
            #endif
            _ = try await send("04")
            try await Task.sleep(for: .milliseconds(400))
            await scanFaults(for: vehicle)
        } catch {
            lastError = error.localizedDescription
        }
    }

    #if DEBUG
    func connectMockAdapter(for vehicle: Vehicle) {
        guard !denyIfConnectLocked(userFacing: true) else { return }
        if let context = vehicle.modelContext {
            OBDStore.pair(
                vehicle: vehicle,
                peripheralIdentifier: OBDMockAdapter.identifier,
                name: OBDMockAdapter.name,
                context: context
            )
            try? context.save()
        }
        startMockSession(vehicleID: vehicle.id, name: OBDMockAdapter.name)
    }

    func simulateMileageJump(for vehicle: Vehicle) {
        guard isUsingMockAdapter, isConnected(to: vehicle.id) else { return }
        proposeMileageDelta(OBDMockAdapter.mileageJumpKm, vehicleID: vehicle.id)
    }

    func simulateLowFuel() {
        guard isUsingMockAdapter else { return }
        telemetry.fuelPercent = OBDMockAdapter.lowFuelPercent
        noteFuel(OBDMockAdapter.lowFuelPercent)
    }

    func simulateOverheat() {
        guard isUsingMockAdapter else { return }
        mockCoolantC = OBDMockAdapter.overheatTempC
        telemetry.coolantTempC = mockCoolantC
        noteCoolant(mockCoolantC)
    }

    func simulateOilOverheat() {
        guard isUsingMockAdapter else { return }
        mockOilTempC = OBDMockAdapter.oilOverheatTempC
        telemetry.oilTempC = mockOilTempC
        noteOilTemp(mockOilTempC)
    }

    func simulateNewDriveFault() {
        guard isUsingMockAdapter else { return }
        if !mockFaults.contains(where: { $0.code == OBDMockAdapter.extraDriveFault.code }) {
            mockFaults.append(OBDMockAdapter.extraDriveFault)
        }
        telemetry.dtcCount = mockFaults.count
        telemetry.milOn = true
    }

    func simulateTripEnd() {
        guard isUsingMockAdapter else { return }
        suppressReconnect = true
        finishTripMileageIfNeeded()
        scheduleTripEndAlertsIfNeeded()
        resetConnection(keepVehicle: true)
        statusMessage = "Trip ended · reminders in 15s if you stay disconnected"
    }
    #endif

    func confirmMileageJump(on vehicle: Vehicle) {
        guard let jump = mileageJump, jump.vehicleID == vehicle.id else {
            mileageJump = nil
            return
        }
        applyMileage(jump.proposedKm, to: vehicle)
        mileageJump = nil
    }

    func declineMileageJump() {
        mileageJump = nil
    }

    #if DEBUG
    private func startMockSession(vehicleID: UUID, name: String) {
        suppressReconnect = false
        stopScanning()
        lastError = nil
        isUsingMockAdapter = true
        mockFaults = OBDMockAdapter.sampleFaults
        mockCoolantC = OBDMockAdapter.coolantTempC
        mockOilTempC = OBDMockAdapter.oilTempC
        connectingVehicleID = vehicleID
        connectingPeripheralID = OBDMockAdapter.identifier
        connectedVehicleID = vehicleID
        connectedAdapterName = name
        tripDistanceKm = 0
        lastSpeedSample = nil
        didApplyOdometerThisTrip = false
        connectionState = .connecting
        statusMessage = "Connecting…"

        Task {
            try? await Task.sleep(for: .milliseconds(350))
            guard connectedVehicleID == vehicleID else { return }
            connectionState = .initializing
            statusMessage = "Talking to adapter…"
            try? await Task.sleep(for: .milliseconds(350))
            guard connectedVehicleID == vehicleID else { return }
            telemetry.rpm = OBDMockAdapter.rpm
            telemetry.speedKmh = OBDMockAdapter.speedKmh
            telemetry.fuelPercent = OBDMockAdapter.fuelPercent
            telemetry.coolantTempC = mockCoolantC
            telemetry.oilTempC = mockOilTempC
            telemetry.milOn = true
            telemetry.dtcCount = mockFaults.count
            connectionState = .connected
            ConnectEntitlementStore.shared.beginTrialIfNeeded()
            beginTripTracking()
            noteFuel(OBDMockAdapter.fuelPercent)
            noteCoolant(mockCoolantC)
            noteOilTemp(mockOilTempC)
            markAdapterSeen()
            statusMessage = "Connected · mock"
            startMonitor()
        }
    }

    private func currentFaultReadings() async throws -> [OBDFaultReading] {
        if isUsingMockAdapter {
            return mockFaults
        }
        return try await readAllFaults()
    }
    #else
    private func currentFaultReadings() async throws -> [OBDFaultReading] {
        try await readAllFaults()
    }
    #endif

    // MARK: - Core Bluetooth

    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let state = central.state
        hop { self.applyBluetoothState(state) }
    }

    nonisolated func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        let restored = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] ?? []
        hop { self.handleRestoredPeripherals(restored, central: central) }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let advertisedName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let services = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? []
        let rssi = RSSI.intValue
        hop { self.handleDiscovery(peripheral, advertisedName: advertisedName, services: services, rssi: rssi) }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        hop { self.handleDidConnect(peripheral) }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        let message = error?.localizedDescription
        let identifier = peripheral.identifier
        hop { self.handleDidFailToConnect(identifier: identifier, message: message) }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        let identifier = peripheral.identifier
        hop { self.handleDidDisconnect(identifier) }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        let message = error?.localizedDescription
        hop { self.handleDiscoveredServices(on: peripheral, errorMessage: message) }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        hop { self.handleDiscoveredCharacteristics(on: peripheral, service: service, errorMessage: error?.localizedDescription) }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let data = characteristic.value
        hop { self.handleValueUpdate(characteristic, data: data) }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        let enabled = error == nil
        hop { self.handleNotificationState(characteristic, enabled: enabled) }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        hop { self.handleDidWrite(characteristic, errorMessage: error?.localizedDescription) }
    }

    nonisolated func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        hop { self.handleWriteReady() }
    }

    /// BLE is created on the main queue, so callbacks are already on the main actor.
    /// Keep this non-escaping so Core Bluetooth objects do not cross a Sendable boundary.
    nonisolated private func hop(_ body: @MainActor () -> Void) {
        MainActor.assumeIsolated(body)
    }

    private func applyBluetoothState(_ state: CBManagerState) {
        bluetoothState = state
        if state == .poweredOn {
            reconnectKnownAdapters()
        } else if connectionState != .disconnected && !isUsingMockAdapter {
            lastError = OBDError.bluetoothUnavailable.errorDescription
            scheduleTripEndAlertsIfNeeded()
            resetConnection(keepVehicle: true)
        }
    }

    private func handleDidFailToConnect(identifier: UUID, message: String?) {
        if connectingPeripheralID == identifier {
            lastError = message ?? "Could not connect to the adapter."
            resetConnection(keepVehicle: true)
            if !suppressReconnect {
                reconnectKnownAdapters()
            }
        }
    }

    private func handleNotificationState(_ characteristic: CBCharacteristic, enabled: Bool) {
        guard enabled || characteristic.isNotifying else { return }
        didEnableNotify = true
        notifyReadyContinuation?.resume()
        notifyReadyContinuation = nil
    }

    private func handleDidWrite(_ characteristic: CBCharacteristic, errorMessage: String?) {
        // withoutResponse writes must not complete/fail the command here. A rejected
        // withoutResponse can also arrive late and would cancel the next withResponse.
        guard writeUsesWithoutResponse != true else { return }
        guard commandAwaitingResponse, let errorMessage else { return }
        failPendingCommand(OBDError.commandFailed(errorMessage))
    }

    private func handleWriteReady() {
        writeReadyContinuation?.resume()
        writeReadyContinuation = nil
    }

    private func handleDiscovery(
        _ peripheral: CBPeripheral,
        advertisedName: String?,
        services: [CBUUID],
        rssi: Int
    ) {
        knownPeripherals[peripheral.identifier] = peripheral
        if let advertisedName, !advertisedName.isEmpty {
            advertisementNames[peripheral.identifier] = advertisedName
        }

        let name = OBDAdapterProfile.displayName(for: peripheral, advertisementName: advertisedName)
        let likely = OBDAdapterProfile.isLikelyAdapter(name: name, advertisedServices: services)
        if !likely && !showAllNamedDevices {
            return
        }
        if name == "BLE Adapter" && !likely {
            return
        }

        let device = OBDDiscoveredDevice(id: peripheral.identifier, name: name, rssi: rssi)
        if let index = discoveredDevices.firstIndex(where: { $0.id == device.id }) {
            discoveredDevices[index] = device
        } else {
            discoveredDevices.append(device)
        }
        discoveredDevices.sort { lhs, rhs in
            #if DEBUG
            if lhs.id == OBDMockAdapter.identifier { return true }
            if rhs.id == OBDMockAdapter.identifier { return false }
            #endif
            return lhs.rssi > rhs.rssi
        }
    }

    private func handleRestoredPeripherals(_ restored: [CBPeripheral], central: CBCentralManager) {
        guard ConnectEntitlementStore.shared.canAttemptConnection else {
            for item in restored {
                central.cancelPeripheralConnection(item)
            }
            return
        }

        let pairedIDs = Set(OBDStore.allPairedAdapters().map(\.peripheralIdentifier))
        forgetIfUnsupported = false

        for item in restored {
            knownPeripherals[item.identifier] = item
            if !pairedIDs.contains(item.identifier) {
                central.cancelPeripheralConnection(item)
                continue
            }
            item.delegate = self
            if item.state == .connected {
                peripheral = item
                connectionState = .initializing
                statusMessage = "Talking to adapter…"
                connectedAdapterName = OBDAdapterProfile.displayName(for: item, advertisementName: advertisementNames[item.identifier])
                connectedVehicleID = OBDStore.vehicleID(for: item.identifier)
                item.discoverServices(nil)
            } else {
                central.connect(item, options: OBDAdapterProfile.connectOptions)
            }
        }
    }

    private func handleDidConnect(_ peripheral: CBPeripheral) {
        self.peripheral = peripheral
        peripheral.delegate = self
        connectionState = .initializing
        statusMessage = "Talking to adapter…"
        let resolvedName = OBDAdapterProfile.displayName(
            for: peripheral,
            advertisementName: advertisementNames[peripheral.identifier]
        )
        if resolvedName != "BLE Adapter" || connectedAdapterName == nil {
            connectedAdapterName = resolvedName
        }
        if connectedVehicleID == nil {
            connectedVehicleID = connectingVehicleID ?? OBDStore.vehicleID(for: peripheral.identifier)
        }
        pendingDiscoveries = 0
        pendingServiceIDs = []
        writeCharacteristic = nil
        notifyCharacteristic = nil
        handshakeTask?.cancel()
        handshakeTask = nil
        receivedNonElmTraffic = false
        commandAwaitingResponse = false
        writeUsesWithoutResponse = nil
        commandTerminator = "\r"
        didEnableNotify = false
        uartPairs = [:]
        probeNotifyCharacteristics = []
        probeWriteCharacteristics = []
        allCharacteristics = []
        idleNotifyBuffer = ""
        didDiscoverAllServices = true
        peripheral.discoverServices(nil)
    }

    private func handleDidDisconnect(_ identifier: UUID) {
        guard peripheral?.identifier == identifier else { return }
        finishTripMileageIfNeeded()
        scheduleTripEndAlertsIfNeeded()
        if let vehicleID = connectedVehicleID {
            OBDStore.markLastSeen(
                vehicleID: vehicleID,
                fuelPercent: lastFuelPercent ?? telemetry.fuelPercent,
                container: modelContainer
            )
        }
        failPendingCommand(OBDError.notConnected)
        let shouldReconnect = !suppressReconnect
        resetConnection(keepVehicle: true)
        if shouldReconnect {
            reconnectKnownAdapters()
        }
        suppressReconnect = false
    }

    private func handleDiscoveredServices(on peripheral: CBPeripheral, errorMessage: String?) {
        if errorMessage != nil {
            receivedNonElmTraffic = true
            failHandshake(message: "The adapter did not expose its serial service.", forget: false, timedOut: true)
            return
        }

        let services = (peripheral.services ?? []).filter { !OBDAdapterProfile.isSkippableService($0.uuid) }
        pendingServiceIDs = Set(services.map(\.uuid))
        pendingDiscoveries = services.count
        guard !pendingServiceIDs.isEmpty else {
            receivedNonElmTraffic = true
            failHandshake(message: "The adapter did not expose its serial service.", forget: false, timedOut: true)
            return
        }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    private func handleDiscoveredCharacteristics(on peripheral: CBPeripheral, service: CBService, errorMessage: String?) {
        pendingServiceIDs.remove(service.uuid)
        pendingDiscoveries = pendingServiceIDs.count
        if errorMessage == nil {
            var notify = uartPairs[service.uuid]?.notify
            var write = uartPairs[service.uuid]?.write
            for characteristic in service.characteristics ?? [] {
                if !allCharacteristics.contains(where: { $0.uuid == characteristic.uuid && $0.service?.uuid == service.uuid }) {
                    allCharacteristics.append(characteristic)
                }
                let knownNotify = OBDAdapterProfile.preferredNotify.contains(characteristic.uuid)
                let knownWrite = OBDAdapterProfile.preferredWrite.contains(characteristic.uuid)
                let canNotify = characteristic.properties.contains(.notify) || characteristic.properties.contains(.indicate)
                let canWrite = characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse)

                if knownNotify || canNotify {
                    if !probeNotifyCharacteristics.contains(where: { $0.uuid == characteristic.uuid && $0.service?.uuid == service.uuid }) {
                        probeNotifyCharacteristics.append(characteristic)
                    }
                    if notify == nil || knownNotify {
                        notify = characteristic
                    }
                }
                if knownWrite || canWrite {
                    if !probeWriteCharacteristics.contains(where: { $0.uuid == characteristic.uuid && $0.service?.uuid == service.uuid }) {
                        probeWriteCharacteristics.append(characteristic)
                    }
                    if write == nil || knownWrite {
                        write = characteristic
                    }
                }
            }
            uartPairs[service.uuid] = (notify, write)
        }

        if pendingServiceIDs.isEmpty {
            finishDiscovery(on: peripheral)
        }
    }

    private func handleValueUpdate(_ characteristic: CBCharacteristic, data: Data?) {
        guard let data, !data.isEmpty else { return }
        if connectionState != .initializing, !isNotifyTraffic(characteristic) {
            return
        }
        let chunk = String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .isoLatin1)
            ?? ""
        guard !chunk.isEmpty else { return }

        if connectionState == .initializing, !commandAwaitingResponse {
            idleNotifyBuffer += chunk
            return
        }
        guard commandAwaitingResponse else { return }
        notifyCharacteristic = characteristic
        responseBuffer += chunk
        if responseLooksComplete(responseBuffer) {
            completeCommand(responseBuffer)
        }
    }

    private func isNotifyTraffic(_ characteristic: CBCharacteristic) -> Bool {
        if characteristic.uuid == notifyCharacteristic?.uuid {
            return true
        }
        return probeNotifyCharacteristics.contains(where: { $0.uuid == characteristic.uuid })
    }

    private func responseLooksComplete(_ buffer: String) -> Bool {
        if buffer.contains(">") { return true }
        let upper = buffer.uppercased()
        return upper.contains("ELM")
            || upper.contains("OK")
            || upper.contains("VEEPEAK")
            || upper.contains("?")
    }

    // MARK: - Handshake and polling

    private func finishDiscovery(on peripheral: CBPeripheral) {
        let fff1 = CBUUID(string: "FFF1")
        let fff2 = CBUUID(string: "FFF2")
        notifyCharacteristic = probeNotifyCharacteristics.first(where: { $0.uuid == fff1 })
            ?? probeNotifyCharacteristics.first
        writeCharacteristic = probeWriteCharacteristics.first(where: { $0.uuid == fff2 })
            ?? OBDAdapterProfile.preferredWriteOrder(probeWriteCharacteristics).first

        guard notifyCharacteristic != nil || writeCharacteristic != nil || !probeWriteCharacteristics.isEmpty else {
            failHandshake(
                message: "Found the Veepeak but not its serial channel (notify \(probeNotifyCharacteristics.map { $0.uuid.uuidString }.joined(separator: ", ")); write \(probeWriteCharacteristics.map { $0.uuid.uuidString }.joined(separator: ", "))).",
                forget: false,
                timedOut: true
            )
            return
        }

        enableAllNotifications(on: peripheral)
        startHandshake()
    }

    private func enableAllNotifications(on peripheral: CBPeripheral) {
        var seen = Set<String>()
        for characteristic in probeNotifyCharacteristics + allCharacteristics {
            let key = "\(characteristic.service?.uuid.uuidString ?? "")-\(characteristic.uuid.uuidString)"
            guard seen.insert(key).inserted else { continue }
            let canNotify = characteristic.properties.contains(.notify)
                || characteristic.properties.contains(.indicate)
                || OBDAdapterProfile.preferredNotify.contains(characteristic.uuid)
            guard canNotify else { continue }
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }

    private func startHandshake() {
        guard handshakeTask == nil else { return }
        guard connectionState == .initializing || connectionState == .connecting else { return }
        // Core Bluetooth delivers notify on the main queue. Handshake must run there
        // or ATE0 replies are dropped before commandAwaitingResponse is visible.
        handshakeTask = Task { @MainActor [weak self] in
            await self?.handshake()
        }
    }

    private func retryHandshake() {
        handshakeTask?.cancel()
        handshakeTask = nil
        failPendingCommand(OBDError.notConnected)
        lastError = nil
        idleNotifyBuffer = ""
        didEnableNotify = false
        connectionState = .initializing
        statusMessage = "Talking to adapter…"
        if let peripheral {
            enableAllNotifications(on: peripheral)
        }
        startHandshake()
    }

    private func handshake() async {
        connectionState = .initializing
        statusMessage = "Talking to adapter…"
        await waitUntilNotifyEnabled()
        try? await Task.sleep(for: .milliseconds(600))

        if handshakeReplyLooksValid(idleNotifyBuffer) {
            do {
                try await completeHandshake(firstReply: idleNotifyBuffer)
                return
            } catch is CancellationError {
                return
            } catch {
                idleNotifyBuffer = ""
            }
        }

        let pairs = uartProbePairs()
        guard !pairs.isEmpty else {
            failHandshake(
                message: "Found the Veepeak but not a usable write characteristic.",
                forget: false,
                timedOut: true
            )
            return
        }

        var lastFailure: String?
        if let first = pairs.first {
            notifyCharacteristic = first.notify
            writeCharacteristic = first.write
        }
        commandTerminator = "\r"
        writeUsesWithoutResponse = false
        idleNotifyBuffer = ""
        if let wakeReply = try? await send("", timeout: 1.2), handshakeReplyLooksValid(wakeReply) {
            do {
                try await completeHandshake(firstReply: wakeReply)
                return
            } catch is CancellationError {
                return
            } catch {
                lastFailure = error.localizedDescription
            }
        } else if handshakeReplyLooksValid(idleNotifyBuffer) {
            do {
                try await completeHandshake(firstReply: idleNotifyBuffer)
                return
            } catch is CancellationError {
                return
            } catch {
                lastFailure = error.localizedDescription
            }
        }

        for (index, pair) in pairs.enumerated() {
            if Task.isCancelled { return }
            notifyCharacteristic = pair.notify
            writeCharacteristic = pair.write
            let terminators = index == 0 ? ["\r", "\r\n"] : ["\r"]
            for terminator in terminators {
                commandTerminator = terminator
                for withoutResponse in writeModes(for: pair.write) {
                    writeUsesWithoutResponse = withoutResponse
                    statusMessage = "Talking to adapter…"
                    do {
                        try Task.checkCancellation()
                        // Do not send ATZ first. On Veepeak BLE+ it resets the radio.
                        let firstReply = try await send("ATE0", timeout: 4)
                        try Task.checkCancellation()
                        try await completeHandshake(firstReply: firstReply)
                        return
                    } catch is CancellationError {
                        return
                    } catch {
                        lastFailure = error.localizedDescription
                        continue
                    }
                }
            }
        }

        failHandshake(
            message: lastFailure ?? "The adapter did not respond in time.",
            forget: false,
            timedOut: true
        )
    }

    private func completeHandshake(firstReply: String) async throws {
        _ = try await send("ATL0")
        _ = try await send("ATS0")
        _ = try await send("ATH0")
        let ident = (try? await send("ATI")) ?? firstReply
        _ = try? await send("ATSP0", timeout: 8)
        try Task.checkCancellation()

        let namedAdapter = OBDAdapterProfile.isLikelyAdapter(name: connectedAdapterName ?? "")
        let identified = ELM327Codec.looksLikeAdapter(firstReply)
            || ELM327Codec.looksLikeAdapter(ident)
        let acknowledged = firstReply.contains(">") || firstReply.uppercased().contains("OK")
        let veepeakUART = OBDAdapterProfile.isVeepeakUARTPair(
            notify: notifyCharacteristic?.uuid,
            write: writeCharacteristic?.uuid
        )
        guard namedAdapter || identified || acknowledged || veepeakUART else {
            receivedNonElmTraffic = true
            throw OBDError.handshakeFailed
        }

        connectionState = .connected
        lastError = nil
        statusMessage = "Connected"
        handshakeTask = nil
        forgetIfUnsupported = false
        ConnectEntitlementStore.shared.beginTrialIfNeeded()
        beginTripTracking()
        markAdapterSeen()
        await loadSupportedPIDs()
        await snapshot()
        persistBackgroundSnapshotIfNeeded()
        startMonitor()
    }

    private func handshakeReplyLooksValid(_ raw: String) -> Bool {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        if trimmed.contains(">") { return true }
        let upper = trimmed.uppercased()
        return upper.contains("OK")
            || ELM327Codec.looksLikeAdapter(trimmed)
    }

    private func uartProbePairs() -> [(notify: CBCharacteristic, write: CBCharacteristic)] {
        var pairs: [(notify: CBCharacteristic, write: CBCharacteristic)] = []
        func add(_ notify: CBCharacteristic?, _ write: CBCharacteristic?) {
            guard let notify, let write else { return }
            let exists = pairs.contains {
                $0.notify.uuid == notify.uuid
                    && $0.write.uuid == write.uuid
                    && $0.notify.service?.uuid == notify.service?.uuid
                    && $0.write.service?.uuid == write.service?.uuid
            }
            if !exists {
                pairs.append((notify, write))
            }
        }

        let fff1 = CBUUID(string: "FFF1")
        let fff2 = CBUUID(string: "FFF2")
        let notifyFFF1 = probeNotifyCharacteristics.first { $0.uuid == fff1 }
        let writeFFF2 = probeWriteCharacteristics.first { $0.uuid == fff2 }
        add(notifyFFF1, writeFFF2)

        for pair in OBDAdapterProfile.orderedUARTPairs(from: uartPairs) {
            add(pair.notify, pair.write)
        }

        // Some clones swap FFF1/FFF2 or use one characteristic both ways.
        add(allCharacteristics.first { $0.uuid == fff2 }, allCharacteristics.first { $0.uuid == fff1 })
        add(notifyFFF1, notifyFFF1)
        add(writeFFF2, writeFFF2)

        for notify in probeNotifyCharacteristics {
            for write in OBDAdapterProfile.preferredWriteOrder(probeWriteCharacteristics) {
                add(notify, write)
            }
        }
        return Array(pairs.prefix(4))
    }

    private func writeModes(for characteristic: CBCharacteristic) -> [Bool] {
        // Always try both ATT write types. iOS may accept withResponse while the
        // firmware only forwards write-without-response to the ELM UART, or the reverse.
        if characteristic.properties.contains(.writeWithoutResponse)
            && !characteristic.properties.contains(.write) {
            return [true, false]
        }
        return [false, true]
    }

    private func waitUntilNotifyEnabled() async {
        if didEnableNotify { return }
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            if didEnableNotify {
                continuation.resume()
                return
            }
            notifyReadyContinuation = continuation
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(4))
                await MainActor.run {
                    guard let self, let pending = self.notifyReadyContinuation else { return }
                    self.notifyReadyContinuation = nil
                    pending.resume()
                }
            }
        }
    }

    private func startMonitor() {
        guard ConnectEntitlementStore.shared.hasAccess else {
            enforceConnectAccess()
            return
        }
        monitorTask?.cancel()
        monitorTask = Task { @MainActor [weak self] in
            var ticks = 0
            while let self, !Task.isCancelled, self.connectionState == .connected {
                await self.pollTick(ticks: ticks)
                ticks += 1
                let interval = self.isForeground ? 1.0 : 5.0
                try? await Task.sleep(for: .seconds(interval))
            }
        }
    }

    private func pollTick(ticks: Int) async {
        guard connectionState == .connected else { return }
        ConnectEntitlementStore.shared.expireIfNeeded()
        if !ConnectEntitlementStore.shared.hasAccess {
            enforceConnectAccess()
            return
        }
        #if DEBUG
        if isUsingMockAdapter {
            telemetry.rpm = OBDMockAdapter.rpm + Double((ticks % 7) * 12)
            telemetry.speedKmh = OBDMockAdapter.speedKmh
            if telemetry.fuelPercent == nil {
                telemetry.fuelPercent = OBDMockAdapter.fuelPercent
            }
            telemetry.coolantTempC = mockCoolantC
            telemetry.oilTempC = mockOilTempC
            telemetry.dtcCount = mockFaults.count
            telemetry.milOn = !mockFaults.isEmpty
            if let fuel = telemetry.fuelPercent {
                noteFuel(fuel)
            }
            noteCoolant(mockCoolantC)
            noteOilTemp(mockOilTempC)
            if ticks == 0 || ticks % 15 == 0 {
                await scanFaultsInBackground()
            }
            return
        }
        #endif

        var gotECUData = false

        if let speed = await readSpeed() {
            accumulateTrip(speed: speed)
            telemetry.speedKmh = speed
            gotECUData = true
        }

        if ticks % 2 == 0 {
            if let rpm = await readRPM() {
                telemetry.rpm = rpm
                gotECUData = true
            }
        }
        if ticks % 3 == 0 {
            if let fuel = await readFuel() {
                telemetry.fuelPercent = fuel
                noteFuel(fuel)
                gotECUData = true
            }
            if let coolant = await readCoolant() {
                telemetry.coolantTempC = coolant
                noteCoolant(coolant)
                gotECUData = true
            }
            if let oil = await readOilTemp() {
                telemetry.oilTempC = oil
                noteOilTemp(oil)
                gotECUData = true
            }
        }
        if ticks % 5 == 0 {
            await readOdometerAndMaybeApply()
        }
        if ticks == 0 || ticks % 15 == 0 {
            if let status = await readMonitorStatus() {
                telemetry.milOn = status.milOn
                telemetry.dtcCount = status.dtcCount
                gotECUData = true
            }
            await scanFaultsInBackground()
        }

        if gotECUData {
            noteECUDataReceived()
        } else {
            noteECUMiss()
        }
    }

    private func snapshot() async {
        telemetry.rpm = await readRPM()
        telemetry.speedKmh = await readSpeed()
        if let fuel = await readFuel() {
            telemetry.fuelPercent = fuel
            noteFuel(fuel)
        }
        if let coolant = await readCoolant() {
            telemetry.coolantTempC = coolant
            noteCoolant(coolant)
        }
        if let oil = await readOilTemp() {
            telemetry.oilTempC = oil
            noteOilTemp(oil)
        }
        if let status = await readMonitorStatus() {
            telemetry.milOn = status.milOn
            telemetry.dtcCount = status.dtcCount
        }
        await readOdometerAndMaybeApply()
    }

    private func scanFaultsInBackground() async {
        guard let vehicleID = connectedVehicleID else { return }
        do {
            let readings = try await currentFaultReadings()
            noteTripFaults(readings)
            OBDStore.persistFaultsFromBackground(
                readings,
                vehicleID: vehicleID,
                milOn: telemetry.milOn ?? false,
                container: modelContainer
            )
        } catch {
            return
        }
    }

    private func persistBackgroundSnapshotIfNeeded() {
        guard !isForeground, let vehicleID = connectedVehicleID else { return }
        Task {
            await scanFaultsInBackground()
            _ = vehicleID
        }
    }

    // MARK: - PIDs

    private func loadSupportedPIDs() async {
        supportedPIDs = []
        var pid: UInt8? = 0x00
        while let current = pid {
            guard let raw = try? await send(String(format: "01%02X", current)), !ELM327Codec.isNoData(raw) else {
                break
            }
            let found = ELM327Codec.supportedPIDs(from: raw, pid: current)
            supportedPIDs.formUnion(found)
            let next = current &+ 0x20
            pid = found.contains(next) && current < 0xA0 ? next : nil
        }
    }

    private func pidSupported(_ pid: UInt8) -> Bool {
        supportedPIDs.isEmpty || supportedPIDs.contains(pid)
    }

    private func readRPM() async -> Double? {
        guard pidSupported(0x0C), let raw = try? await send("010C"), !ELM327Codec.isNoData(raw) else {
            return nil
        }
        return ELM327Codec.rpm(from: raw)
    }

    private func readSpeed() async -> Double? {
        guard pidSupported(0x0D), let raw = try? await send("010D"), !ELM327Codec.isNoData(raw) else {
            return nil
        }
        return ELM327Codec.speedKmh(from: raw)
    }

    private func readFuel() async -> Double? {
        guard pidSupported(0x2F), let raw = try? await send("012F"), !ELM327Codec.isNoData(raw) else {
            return nil
        }
        return ELM327Codec.fuelPercent(from: raw)
    }

    private func readCoolant() async -> Double? {
        guard pidSupported(0x05), let raw = try? await send("0105"), !ELM327Codec.isNoData(raw) else {
            return nil
        }
        return ELM327Codec.coolantTempC(from: raw)
    }

    private func readOilTemp() async -> Double? {
        guard pidSupported(0x5C), let raw = try? await send("015C"), !ELM327Codec.isNoData(raw) else {
            return nil
        }
        return ELM327Codec.oilTempC(from: raw)
    }

    private func readMonitorStatus() async -> (milOn: Bool, dtcCount: Int)? {
        guard pidSupported(0x01), let raw = try? await send("0101"), !ELM327Codec.isNoData(raw) else {
            return nil
        }
        return ELM327Codec.monitorStatus(from: raw)
    }

    private func readOdometerAndMaybeApply() async {
        guard pidSupported(0xA6), let raw = try? await send("01A6"), !ELM327Codec.isNoData(raw) else {
            return
        }
        guard let km = ELM327Codec.odometerKm(from: raw) else { return }
        telemetry.odometerKm = km
        proposeMileage(Int(km.rounded()), source: "vehicle odometer")
        didApplyOdometerThisTrip = true
    }

    private func readAllFaults() async throws -> [OBDFaultReading] {
        var readings: [OBDFaultReading] = []
        if let raw = try? await send("03"), !ELM327Codec.isNoData(raw) {
            readings.append(contentsOf: ELM327Codec.diagnosticCodes(from: raw, status: .stored))
        }
        if let raw = try? await send("07"), !ELM327Codec.isNoData(raw) {
            readings.append(contentsOf: ELM327Codec.diagnosticCodes(from: raw, status: .pending))
        }
        if let raw = try? await send("0A"), !ELM327Codec.isNoData(raw) {
            readings.append(contentsOf: ELM327Codec.diagnosticCodes(from: raw, status: .permanent))
        }
        return readings
    }

    // MARK: - Mileage

    private func accumulateTrip(speed: Double) {
        let now = Date()
        if let last = lastSpeedSample {
            let hours = now.timeIntervalSince(last.at) / 3600
            let average = (speed + last.speed) / 2
            if hours > 0, hours < 0.01, average >= 1 {
                tripDistanceKm += average * hours
            }
        }
        lastSpeedSample = (speed, now)
    }

    private func finishTripMileageIfNeeded() {
        defer {
            lastSpeedSample = nil
            tripDistanceKm = 0
            didApplyOdometerThisTrip = false
        }
        guard !didApplyOdometerThisTrip, tripDistanceKm >= 1, let vehicleID = connectedVehicleID else {
            return
        }
        let add = Int(tripDistanceKm.rounded(.down))
        guard add > 0 else { return }
        proposeMileageDelta(add, vehicleID: vehicleID)
    }

    private func proposeMileage(_ proposedKm: Int, source: String) {
        guard let vehicleID = connectedVehicleID else { return }
        do {
            guard let snapshot = try MileageWriter.snapshot(for: vehicleID) else { return }
            let current = snapshot.mileage
            guard proposedKm > current else { return }
            if proposedKm - current >= largeJumpKm {
                mileageJump = MileageJumpProposal(
                    vehicleID: vehicleID,
                    currentKm: current,
                    proposedKm: proposedKm,
                    source: source
                )
                return
            }
            try MileageWriter.set(vehicleID: vehicleID, mileage: proposedKm)
            appliedMileageKm = proposedKm
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func proposeMileageDelta(_ kilometers: Int, vehicleID: UUID) {
        do {
            guard let snapshot = try MileageWriter.snapshot(for: vehicleID) else { return }
            let proposed = snapshot.mileage + kilometers
            if kilometers >= largeJumpKm {
                mileageJump = MileageJumpProposal(
                    vehicleID: vehicleID,
                    currentKm: snapshot.mileage,
                    proposedKm: proposed,
                    source: "trip distance"
                )
                return
            }
            try MileageWriter.add(vehicleID: vehicleID, kilometers: kilometers)
            appliedMileageKm = snapshot.mileage + kilometers
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func applyMileage(_ kilometers: Int, to vehicle: Vehicle) {
        vehicle.currentMileage = max(kilometers, vehicle.currentMileage)
        vehicle.updatedAt = Date()
        try? vehicle.modelContext?.save()
        try? MileageWriter.set(vehicleID: vehicle.id, mileage: vehicle.currentMileage)
        appliedMileageKm = vehicle.currentMileage
    }

    private func completeCommandSafely(_ raw: String?, timedOut: Bool) {
        timeoutTask?.cancel()
        timeoutTask = nil
        commandAwaitingResponse = false
        guard let continuation = pendingCommand else { return }
        pendingCommand = nil
        responseBuffer = ""
        if timedOut && raw == nil {
            continuation.resume(throwing: OBDError.timeout)
        } else if let raw {
            continuation.resume(returning: raw)
        } else {
            continuation.resume(throwing: OBDError.timeout)
        }
    }

    // MARK: - Commands

    @MainActor
    private func send(_ command: String, timeout: TimeInterval = 4) async throws -> String {
        guard connectionState == .connected || connectionState == .initializing else {
            throw OBDError.notConnected
        }
        guard peripheral != nil, writeCharacteristic != nil else {
            throw OBDError.handshakeFailed
        }
        while commandLock {
            try Task.checkCancellation()
            try await Task.sleep(for: .milliseconds(40))
        }
        commandLock = true
        defer { commandLock = false }

        await waitUntilWritable()
        writeGeneration += 1
        return try await withCheckedThrowingContinuation { continuation in
            pendingCommand = continuation
            responseBuffer = ""
            commandAwaitingResponse = true
            write(command)
            timeoutTask = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(timeout))
                guard let self, self.pendingCommand != nil else { return }
                let snapshot = self.responseBuffer
                self.completeCommandSafely(snapshot.isEmpty ? nil : snapshot, timedOut: snapshot.isEmpty)
            }
        }
    }

    @MainActor
    private func write(_ command: String) {
        guard let peripheral, let writeCharacteristic else { return }
        let payload = (command + commandTerminator).data(using: .ascii) ?? Data()
        let type: CBCharacteristicWriteType = writeUsesWithoutResponse == true ? .withoutResponse : .withResponse
        peripheral.writeValue(payload, for: writeCharacteristic, type: type)
    }

    private func waitUntilWritable() async {
        guard let peripheral, willWriteWithoutResponse else { return }
        if peripheral.canSendWriteWithoutResponse { return }
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            if peripheral.canSendWriteWithoutResponse {
                continuation.resume()
                return
            }
            writeReadyContinuation = continuation
            Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(800))
                await MainActor.run {
                    guard let self, let pending = self.writeReadyContinuation else { return }
                    self.writeReadyContinuation = nil
                    pending.resume()
                }
            }
        }
    }

    private var willWriteWithoutResponse: Bool {
        guard let writeCharacteristic else { return false }
        if let override = writeUsesWithoutResponse {
            return override && writeCharacteristic.properties.contains(.writeWithoutResponse)
        }
        return writeCharacteristic.properties.contains(.writeWithoutResponse)
    }

    private func completeCommand(_ raw: String?, timedOut: Bool = false) {
        completeCommandSafely(raw, timedOut: timedOut)
    }

    private func failPendingCommand(_ error: OBDError) {
        timeoutTask?.cancel()
        timeoutTask = nil
        commandAwaitingResponse = false
        pendingCommand?.resume(throwing: error)
        pendingCommand = nil
        responseBuffer = ""
    }

    // MARK: - Connection helpers

    private func connect(identifier: UUID, vehicleID: UUID, name: String) {
        guard !denyIfConnectLocked(userFacing: true) else { return }
        #if DEBUG
        if identifier == OBDMockAdapter.identifier {
            startMockSession(vehicleID: vehicleID, name: name)
            return
        }
        #endif
        connectingVehicleID = vehicleID
        connectingPeripheralID = identifier
        connectedAdapterName = name
        connectedVehicleID = vehicleID

        if let existing = knownPeripherals[identifier] ?? central.retrievePeripherals(withIdentifiers: [identifier]).first {
            connect(peripheral: existing, vehicleID: vehicleID)
            return
        }

        let connected = central.retrieveConnectedPeripherals(withServices: OBDAdapterProfile.uartServices)
        if let match = connected.first(where: { $0.identifier == identifier }) {
            connect(peripheral: match, vehicleID: vehicleID)
        }
    }

    private func connect(peripheral: CBPeripheral, vehicleID: UUID) {
        guard !denyIfConnectLocked(userFacing: true) else { return }
        suppressReconnect = false
        stopScanning()
        lastError = nil
        connectingVehicleID = vehicleID
        connectingPeripheralID = peripheral.identifier
        connectedVehicleID = vehicleID
        knownPeripherals[peripheral.identifier] = peripheral
        connectionState = .connecting
        statusMessage = "Connecting…"
        tripDistanceKm = 0
        lastSpeedSample = nil
        didApplyOdometerThisTrip = false
        peripheral.delegate = self
        central.connect(peripheral, options: OBDAdapterProfile.connectOptions)
    }

    private func denyIfConnectLocked(userFacing: Bool) -> Bool {
        guard ConnectEntitlementStore.shared.canAttemptConnection else {
            if userFacing {
                lastError = Self.connectLockedMessage
                statusMessage = "Connect locked"
            }
            return true
        }
        return false
    }

    private func failHandshake(message: String? = nil, forget: Bool? = nil, timedOut: Bool = false) {
        handshakeTask?.cancel()
        handshakeTask = nil
        failPendingCommand(OBDError.handshakeFailed)
        suppressReconnect = true
        lastError = message ?? OBDError.handshakeFailed.errorDescription
        if timedOut {
            connectionState = .disconnected
            statusMessage = "No reply from adapter"
        } else {
            connectionState = .unsupportedAdapter
            statusMessage = "Adapter not supported"
        }

        let shouldForget = forget ?? ((forgetIfUnsupported || receivedNonElmTraffic) && message == nil)
        if shouldForget, let vehicleID = connectingVehicleID ?? connectedVehicleID {
            OBDStore.forgetAdapter(vehicleID: vehicleID, container: modelContainer)
        }
        forgetIfUnsupported = false
        receivedNonElmTraffic = false
    }

    private func resetConnection(keepVehicle: Bool) {
        isUsingMockAdapter = false
        handshakeTask?.cancel()
        handshakeTask = nil
        monitorTask?.cancel()
        monitorTask = nil
        peripheral = nil
        writeCharacteristic = nil
        notifyCharacteristic = nil
        uartPairs = [:]
        probeNotifyCharacteristics = []
        probeWriteCharacteristics = []
        allCharacteristics = []
        idleNotifyBuffer = ""
        didDiscoverAllServices = false
        writeUsesWithoutResponse = nil
        commandTerminator = "\r"
        pendingServiceIDs = []
        didEnableNotify = false
        notifyReadyContinuation?.resume()
        notifyReadyContinuation = nil
        writeReadyContinuation?.resume()
        writeReadyContinuation = nil
        pendingDiscoveries = 0
        telemetry = OBDLiveTelemetry()
        if !keepVehicle {
            connectedVehicleID = nil
            connectedAdapterName = nil
            connectingVehicleID = nil
            connectingPeripheralID = nil
        }
        if connectionState != .unsupportedAdapter {
            connectionState = .disconnected
        }
        statusMessage = nil
        resetTripTracking()
    }

    // MARK: - Drive alerts

    private func beginTripTracking() {
        if let vehicleID = connectedVehicleID {
            OBDDriveNotifications.cancel(vehicleID: vehicleID)
        }
        tripStartedAt = Date()
        tripBaselineFaults = nil
        tripNewFaults = []
        lastFuelPercent = telemetry.fuelPercent
        maxCoolantC = telemetry.coolantTempC
        maxOilTempC = telemetry.oilTempC
        consecutiveECUMisses = 0
        didScheduleTripEndAlerts = false
    }

    private func noteFuel(_ percent: Double) {
        lastFuelPercent = percent
        if let vehicleID = connectedVehicleID {
            OBDStore.persistLastFuel(percent, vehicleID: vehicleID, container: modelContainer)
        }
    }

    private func markAdapterSeen() {
        guard let vehicleID = connectedVehicleID else { return }
        OBDStore.markLastSeen(
            vehicleID: vehicleID,
            fuelPercent: lastFuelPercent ?? telemetry.fuelPercent,
            container: modelContainer
        )
    }

    private func noteCoolant(_ celsius: Double) {
        maxCoolantC = max(maxCoolantC ?? celsius, celsius)
    }

    private func noteOilTemp(_ celsius: Double) {
        maxOilTempC = max(maxOilTempC ?? celsius, celsius)
    }

    private func noteTripFaults(_ readings: [OBDFaultReading]) {
        let codes = Set(readings.map { $0.code.uppercased() })
        if tripBaselineFaults == nil {
            tripBaselineFaults = codes
            return
        }
        for code in codes where !tripBaselineFaults!.contains(code) {
            if !tripNewFaults.contains(code) {
                tripNewFaults.append(code)
            }
        }
    }

    private func noteECUDataReceived() {
        consecutiveECUMisses = 0
        guard didScheduleTripEndAlerts, let vehicleID = connectedVehicleID else { return }
        OBDDriveNotifications.cancel(vehicleID: vehicleID)
        didScheduleTripEndAlerts = false
    }

    private func noteECUMiss() {
        consecutiveECUMisses += 1
        if consecutiveECUMisses >= ecuSilenceTicks {
            scheduleTripEndAlertsIfNeeded()
        }
    }

    private func scheduleTripEndAlertsIfNeeded() {
        guard !didScheduleTripEndAlerts else { return }
        guard tripStartedAt != nil else { return }
        guard let vehicleID = connectedVehicleID else { return }

        let prefs = OBDStore.driveAlertPreferences(for: vehicleID, container: modelContainer)
        let fuel = lastFuelPercent ?? telemetry.fuelPercent
        let delay = OBDDriveNotifications.delay(isMock: isUsingMockAdapter)

        didScheduleTripEndAlerts = true
        OBDDriveNotifications.schedule(
            OBDDriveNotifications.TripSummary(
                vehicleID: vehicleID,
                vehicleName: prefs?.vehicleDisplayName ?? "Your vehicle",
                delay: delay,
                lastFuelPercent: fuel,
                fillUpThresholdPercent: prefs?.fillUpThresholdPercent ?? 15,
                notifyFillUp: prefs?.notifyFillUpReminders ?? true,
                newFaultCodes: tripNewFaults,
                notifyFaults: prefs?.notifyDriveFaults ?? true,
                maxCoolantC: maxCoolantC,
                notifyCoolant: prefs?.notifyHighCoolantTemp ?? true,
                coolantThresholdC: prefs?.coolantAlertThresholdC ?? OBDDriveNotifications.defaultCoolantAlertC,
                maxOilTempC: maxOilTempC,
                notifyOil: prefs?.notifyHighOilTemp ?? true,
                oilThresholdC: prefs?.oilAlertThresholdC ?? OBDDriveNotifications.defaultOilAlertC
            )
        )
    }

    private func resetTripTracking() {
        tripStartedAt = nil
        tripBaselineFaults = nil
        tripNewFaults = []
        lastFuelPercent = nil
        maxCoolantC = nil
        maxOilTempC = nil
        consecutiveECUMisses = 0
        didScheduleTripEndAlerts = false
    }
}