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

    private var suppressReconnect = false

    override init() {
        super.init()
        central = CBCentralManager(
            delegate: self,
            queue: nil,
            options: [CBCentralManagerOptionRestoreIdentifierKey: OBDAdapterProfile.restoreIdentifier]
        )
    }

    func startScanning(showAllNamedDevices: Bool = false) {
        lastError = nil
        self.showAllNamedDevices = showAllNamedDevices
        discoveredDevices = []
        guard central.state == .poweredOn else {
            lastError = OBDError.bluetoothUnavailable.errorDescription
            return
        }
        guard connectionState != .connected && connectionState != .connecting && connectionState != .initializing else {
            return
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
        guard let match = knownPeripherals[device.id] else {
            lastError = "The adapter is no longer in range. Scan again."
            return
        }
        connect(peripheral: match, vehicleID: vehicleID)
    }

    func connectPairedAdapter(for vehicle: Vehicle) {
        guard let adapter = OBDStore.pairedAdapter(on: vehicle) else { return }
        connect(identifier: adapter.peripheralIdentifier, vehicleID: vehicle.id, name: adapter.name)
    }

    func reconnectKnownAdapters() {
        guard central.state == .poweredOn else { return }
        guard connectionState == .disconnected else { return }

        let paired = OBDStore.allPairedAdapters()
        for item in paired {
            connect(identifier: item.peripheralIdentifier, vehicleID: item.vehicleID, name: item.name)
        }
    }

    func disconnect() {
        suppressReconnect = true
        monitorTask?.cancel()
        monitorTask = nil
        finishTripMileageIfNeeded()
        failPendingCommand(OBDError.notConnected)
        if let peripheral {
            central.cancelPeripheralConnection(peripheral)
        }
        resetConnection(keepVehicle: false)
    }

    func scanFaults(for vehicle: Vehicle) async {
        guard connectionState == .connected else { return }
        isScanningFaults = true
        defer { isScanningFaults = false }

        do {
            let readings = try await readAllFaults()
            let milOn = telemetry.milOn ?? false
            guard let context = vehicle.modelContext else { return }
            OBDStore.upsertFaults(readings, onto: vehicle, milOn: milOn, context: context)
            vehicle.updatedAt = Date()
            try? context.save()
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
            _ = try await send("04")
            try await Task.sleep(for: .milliseconds(400))
            await scanFaults(for: vehicle)
        } catch {
            lastError = error.localizedDescription
        }
    }

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

    // MARK: - Core Bluetooth

    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let state = central.state
        MainActor.assumeIsolated {
            bluetoothState = state
            if state == .poweredOn {
                reconnectKnownAdapters()
            } else if connectionState != .disconnected {
                lastError = OBDError.bluetoothUnavailable.errorDescription
                resetConnection(keepVehicle: true)
            }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        let restored = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] ?? []
        MainActor.assumeIsolated {
            for item in restored {
                knownPeripherals[item.identifier] = item
                item.delegate = self
                if item.state == .connected {
                    peripheral = item
                    connectionState = .initializing
                    connectedAdapterName = OBDAdapterProfile.displayName(for: item, advertisementName: advertisementNames[item.identifier])
                    connectedVehicleID = OBDStore.vehicleID(for: item.identifier)
                    item.discoverServices(nil)
                } else {
                    central.connect(item, options: nil)
                }
            }
        }
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
        MainActor.assumeIsolated {
            handleDiscovery(peripheral, advertisedName: advertisedName, services: services, rssi: rssi)
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        MainActor.assumeIsolated {
            handleDidConnect(peripheral)
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        let message = error?.localizedDescription
        let identifier = peripheral.identifier
        MainActor.assumeIsolated {
            if connectingPeripheralID == identifier {
                lastError = message ?? "Could not connect to the adapter."
                resetConnection(keepVehicle: true)
            }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        let identifier = peripheral.identifier
        MainActor.assumeIsolated {
            handleDidDisconnect(identifier)
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        let message = error?.localizedDescription
        MainActor.assumeIsolated {
            handleDiscoveredServices(on: peripheral, errorMessage: message)
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        MainActor.assumeIsolated {
            handleDiscoveredCharacteristics(on: peripheral, service: service)
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let data = characteristic.value
        MainActor.assumeIsolated {
            handleValueUpdate(characteristic, data: data)
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        let ok = error == nil
        MainActor.assumeIsolated {
            if characteristic == notifyCharacteristic, ok {
                Task { await handshake() }
            }
        }
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
            discoveredDevices.sort { $0.rssi > $1.rssi }
        }
    }

    private func handleDidConnect(_ peripheral: CBPeripheral) {
        self.peripheral = peripheral
        peripheral.delegate = self
        connectionState = .initializing
        statusMessage = "Talking to adapter…"
        connectedAdapterName = OBDAdapterProfile.displayName(
            for: peripheral,
            advertisementName: advertisementNames[peripheral.identifier]
        )
        if connectedVehicleID == nil {
            connectedVehicleID = connectingVehicleID ?? OBDStore.vehicleID(for: peripheral.identifier)
        }
        pendingDiscoveries = 0
        writeCharacteristic = nil
        notifyCharacteristic = nil
        peripheral.discoverServices(nil)
    }

    private func handleDidDisconnect(_ identifier: UUID) {
        guard peripheral?.identifier == identifier else { return }
        finishTripMileageIfNeeded()
        failPendingCommand(OBDError.notConnected)
        let shouldReconnect = isForeground && !suppressReconnect
        resetConnection(keepVehicle: true)
        if shouldReconnect {
            reconnectKnownAdapters()
        }
        suppressReconnect = false
    }

    private func handleDiscoveredServices(on peripheral: CBPeripheral, errorMessage: String?) {
        if let errorMessage {
            lastError = errorMessage
            connectionState = .unsupportedAdapter
            return
        }
        let services = peripheral.services ?? []
        pendingDiscoveries = services.count
        guard pendingDiscoveries > 0 else {
            failHandshake()
            return
        }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    private func handleDiscoveredCharacteristics(on peripheral: CBPeripheral, service: CBService) {
        pendingDiscoveries = max(pendingDiscoveries - 1, 0)
        for characteristic in service.characteristics ?? [] {
            if notifyCharacteristic == nil || OBDAdapterProfile.preferredNotify.contains(characteristic.uuid) {
                if characteristic.properties.contains(.notify) || characteristic.properties.contains(.indicate) {
                    notifyCharacteristic = characteristic
                }
            }
            if writeCharacteristic == nil || OBDAdapterProfile.preferredWrite.contains(characteristic.uuid) {
                if characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse) {
                    writeCharacteristic = characteristic
                }
            }
        }

        if pendingDiscoveries == 0 {
            finishDiscovery(on: peripheral)
        }
    }

    private func handleValueUpdate(_ characteristic: CBCharacteristic, data: Data?) {
        guard characteristic == notifyCharacteristic, let data else { return }
        let chunk = String(data: data, encoding: .utf8) ?? ""
        responseBuffer += chunk
        if responseBuffer.contains(">") {
            completeCommand(responseBuffer)
        }
    }

    // MARK: - Handshake and polling

    private func finishDiscovery(on peripheral: CBPeripheral) {
        guard let notifyCharacteristic, writeCharacteristic != nil else {
            failHandshake()
            return
        }
        peripheral.setNotifyValue(true, for: notifyCharacteristic)
    }

    private func handshake() async {
        connectionState = .initializing
        do {
            try await Task.sleep(for: .milliseconds(250))
            _ = try await send("ATZ", timeout: 8)
            _ = try await send("ATE0")
            _ = try await send("ATL0")
            _ = try await send("ATS0")
            _ = try await send("ATH0")
            _ = try await send("ATSP0", timeout: 8)
            _ = try? await send("ATI")

            connectionState = .connected
            lastError = nil
            statusMessage = "Connected"
            await loadSupportedPIDs()
            await snapshot()
            persistBackgroundSnapshotIfNeeded()
            startMonitor()
        } catch {
            failHandshake()
        }
    }

    private func startMonitor() {
        monitorTask?.cancel()
        monitorTask = Task { [weak self] in
            var ticks = 0
            while let self, !Task.isCancelled, self.connectionState == .connected {
                await self.pollTick(ticks: ticks)
                ticks += 1
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    private func pollTick(ticks: Int) async {
        guard connectionState == .connected else { return }

        if let speed = await readSpeed() {
            accumulateTrip(speed: speed)
            telemetry.speedKmh = speed
        }

        if ticks % 2 == 0 {
            telemetry.rpm = await readRPM()
        }
        if ticks % 3 == 0 {
            if let fuel = await readFuel() {
                telemetry.fuelPercent = fuel
            }
        }
        if ticks % 5 == 0 {
            await readOdometerAndMaybeApply()
        }
        if ticks == 0 || ticks % 15 == 0 {
            if let status = await readMonitorStatus() {
                telemetry.milOn = status.milOn
                telemetry.dtcCount = status.dtcCount
            }
            await scanFaultsInBackground()
        }

        if !isForeground && ticks > 0 && ticks % 20 == 0 {
            monitorTask?.cancel()
        }
    }

    private func snapshot() async {
        telemetry.rpm = await readRPM()
        telemetry.speedKmh = await readSpeed()
        if let fuel = await readFuel() {
            telemetry.fuelPercent = fuel
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
            let readings = try await readAllFaults()
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

    private func send(_ command: String, timeout: TimeInterval = 4) async throws -> String {
        guard connectionState == .connected || connectionState == .initializing else {
            throw OBDError.notConnected
        }
        while commandLock {
            try await Task.sleep(for: .milliseconds(40))
        }
        commandLock = true
        defer { commandLock = false }

        return try await withCheckedThrowingContinuation { continuation in
            pendingCommand = continuation
            responseBuffer = ""
            write(command)
            timeoutTask = Task {
                try? await Task.sleep(for: .seconds(timeout))
                if pendingCommand != nil {
                    let snapshot = responseBuffer
                    completeCommandSafely(snapshot.isEmpty ? nil : snapshot, timedOut: snapshot.isEmpty)
                }
            }
        }
    }

    private func write(_ command: String) {
        guard let peripheral, let writeCharacteristic else { return }
        let payload = (command + "\r").data(using: .ascii) ?? Data()
        let type: CBCharacteristicWriteType = writeCharacteristic.properties.contains(.writeWithoutResponse)
            ? .withoutResponse
            : .withResponse
        peripheral.writeValue(payload, for: writeCharacteristic, type: type)
    }

    private func completeCommand(_ raw: String?, timedOut: Bool = false) {
        completeCommandSafely(raw, timedOut: timedOut)
    }

    private func failPendingCommand(_ error: OBDError) {
        timeoutTask?.cancel()
        timeoutTask = nil
        pendingCommand?.resume(throwing: error)
        pendingCommand = nil
        responseBuffer = ""
    }

    // MARK: - Connection helpers

    private func connect(identifier: UUID, vehicleID: UUID, name: String) {
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
        central.connect(peripheral, options: [CBConnectPeripheralOptionNotifyOnConnectionKey: true])
    }

    private func failHandshake() {
        suppressReconnect = true
        lastError = OBDError.handshakeFailed.errorDescription
        connectionState = .unsupportedAdapter
        if let peripheral {
            central.cancelPeripheralConnection(peripheral)
        }
    }

    private func resetConnection(keepVehicle: Bool) {
        monitorTask?.cancel()
        monitorTask = nil
        peripheral = nil
        writeCharacteristic = nil
        notifyCharacteristic = nil
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
    }
}