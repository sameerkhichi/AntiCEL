import Foundation
import SwiftData

enum OBDStore {

    static func pairedAdapter(on vehicle: Vehicle) -> PairedAdapter? {
        vehicle.pairedAdapters.sorted { $0.lastSeenAt > $1.lastSeenAt }.first
    }

    static func pair(
        vehicle: Vehicle,
        peripheralIdentifier: UUID,
        name: String,
        context: ModelContext
    ) {
        if let existing = pairedAdapter(on: vehicle) {
            existing.peripheralIdentifier = peripheralIdentifier
            existing.name = name
            existing.lastSeenAt = Date()
            return
        }

        let adapter = PairedAdapter(
            peripheralIdentifier: peripheralIdentifier,
            name: name,
            vehicle: vehicle
        )
        context.insert(adapter)
        vehicle.pairedAdapters.append(adapter)
    }

    static func forgetAdapter(on vehicle: Vehicle, context: ModelContext) {
        OBDDriveNotifications.cancel(vehicleID: vehicle.id)
        for adapter in vehicle.pairedAdapters {
            context.delete(adapter)
        }
        vehicle.pairedAdapters.removeAll()
    }

    static func markLastSeen(
        vehicleID: UUID,
        fuelPercent: Double? = nil,
        container: ModelContainer? = nil
    ) {
        mutateAdapter(vehicleID: vehicleID, container: container) { adapter in
            adapter.lastSeenAt = Date()
            if let fuelPercent {
                adapter.lastFuelPercent = fuelPercent
            }
        }
    }

    static func persistLastFuel(
        _ percent: Double,
        vehicleID: UUID,
        container: ModelContainer? = nil
    ) {
        mutateAdapter(vehicleID: vehicleID, container: container) { adapter in
            let previous = adapter.lastFuelPercent ?? -1
            if abs(previous - percent) >= 0.5 {
                adapter.lastFuelPercent = percent
            }
        }
    }

    private static func mutateAdapter(
        vehicleID: UUID,
        container: ModelContainer?,
        update: (PairedAdapter) -> Void
    ) {
        do {
            let container = try container ?? SharedModelContainer.make()
            let context = ModelContext(container)
            let target = vehicleID
            var descriptor = FetchDescriptor<Vehicle>(
                predicate: #Predicate { $0.id == target }
            )
            descriptor.fetchLimit = 1
            guard let vehicle = try context.fetch(descriptor).first,
                  let adapter = pairedAdapter(on: vehicle)
            else {
                return
            }
            update(adapter)
            try context.save()
        } catch {
            return
        }
    }

    static func driveAlertPreferences(
        for vehicleID: UUID,
        container: ModelContainer? = nil
    ) -> OBDDriveAlertPreferences? {
        do {
            let container = try container ?? SharedModelContainer.make()
            let context = ModelContext(container)
            let target = vehicleID
            var descriptor = FetchDescriptor<Vehicle>(
                predicate: #Predicate { $0.id == target }
            )
            descriptor.fetchLimit = 1
            guard let vehicle = try context.fetch(descriptor).first else {
                return nil
            }
            let adapter = pairedAdapter(on: vehicle)
            return OBDDriveAlertPreferences(
                vehicleDisplayName: vehicle.displayName,
                notifyFillUpReminders: adapter?.fillUpRemindersEnabled ?? true,
                fillUpThresholdPercent: adapter?.fillUpThresholdPercentValue ?? 15,
                notifyDriveFaults: adapter?.driveFaultsEnabled ?? true,
                notifyHighCoolantTemp: adapter?.highCoolantTempEnabled ?? true,
                coolantAlertThresholdC: adapter?.coolantAlertThresholdCValue ?? 110,
                notifyHighOilTemp: adapter?.highOilTempEnabled ?? true,
                oilAlertThresholdC: adapter?.oilAlertThresholdCValue ?? 130
            )
        } catch {
            return nil
        }
    }

    static func upsertFaults(
        _ readings: [OBDFaultReading],
        onto vehicle: Vehicle,
        milOn: Bool,
        context: ModelContext
    ) {
        let merged = merge(readings)
        let now = Date()
        let mileage = vehicle.currentMileage
        var seen = Set<String>()

        for reading in merged {
            seen.insert(reading.code)
            if let existing = vehicle.diagnosticFaults.first(where: { $0.code == reading.code }) {
                let returned = !existing.isActive
                existing.lastSeenAt = now
                existing.isActive = true
                existing.milOn = milOn
                if reading.status.rank >= existing.status.rank {
                    existing.status = reading.status
                }

                if returned {
                    existing.firstSeenAt = now
                    existing.mileageAtFirstSeen = mileage
                    existing.promotedToHistory = false
                    existing.historyEntryID = nil
                }

                if !existing.promotedToHistory {
                    promote(existing, onto: vehicle, context: context)
                }
            } else {
                let fault = DiagnosticFault(
                    code: reading.code,
                    title: DTCDictionary.title(for: reading.code),
                    status: reading.status,
                    mileageAtFirstSeen: mileage,
                    milOn: milOn,
                    vehicle: vehicle
                )
                context.insert(fault)
                vehicle.diagnosticFaults.append(fault)
                promote(fault, onto: vehicle, context: context)
            }
        }

        for fault in vehicle.diagnosticFaults where fault.isActive && !seen.contains(fault.code) {
            fault.isActive = false
        }
    }

    static func promoteIfNeeded(_ fault: DiagnosticFault, onto vehicle: Vehicle, context: ModelContext) {
        guard !fault.promotedToHistory else { return }
        promote(fault, onto: vehicle, context: context)
    }

    static func persistFaultsFromBackground(
        _ readings: [OBDFaultReading],
        vehicleID: UUID,
        milOn: Bool,
        container: ModelContainer? = nil
    ) {
        do {
            let container = try container ?? SharedModelContainer.make()
            let context = ModelContext(container)
            let target = vehicleID
            var descriptor = FetchDescriptor<Vehicle>(
                predicate: #Predicate { $0.id == target }
            )
            descriptor.fetchLimit = 1
            guard let vehicle = try context.fetch(descriptor).first else {
                return
            }
            upsertFaults(readings, onto: vehicle, milOn: milOn, context: context)
            try context.save()
        } catch {
            return
        }
    }

    static func allPairedAdapters() -> [(vehicleID: UUID, peripheralIdentifier: UUID, name: String)] {
        do {
            let container = try SharedModelContainer.make()
            let context = ModelContext(container)
            let adapters = try context.fetch(FetchDescriptor<PairedAdapter>())
            return adapters.compactMap { adapter in
                guard let vehicleID = adapter.vehicle?.id else { return nil }
                return (vehicleID, adapter.peripheralIdentifier, adapter.name)
            }
        } catch {
            return []
        }
    }

    static func vehicleID(for peripheralIdentifier: UUID) -> UUID? {
        allPairedAdapters().first(where: { $0.peripheralIdentifier == peripheralIdentifier })?.vehicleID
    }

    private static func merge(_ readings: [OBDFaultReading]) -> [OBDFaultReading] {
        var best: [String: OBDFaultReading] = [:]
        for reading in readings {
            let code = reading.code.uppercased()
            if let existing = best[code] {
                if reading.status.rank > existing.status.rank {
                    best[code] = OBDFaultReading(code: code, status: reading.status)
                }
            } else {
                best[code] = OBDFaultReading(code: code, status: reading.status)
            }
        }
        return Array(best.values).sorted { $0.code < $1.code }
    }

    private static func promote(_ fault: DiagnosticFault, onto vehicle: Vehicle, context: ModelContext) {
        guard !fault.promotedToHistory else { return }

        let entry = HistoryEntry(
            title: DTCHistoryMapper.historyTitle(for: fault.code),
            details: DTCHistoryMapper.historyDetails(code: fault.code, status: fault.status),
            date: fault.firstSeenAt,
            mileage: fault.mileageAtFirstSeen,
            category: DTCHistoryMapper.category(for: fault.code),
            vehicleArea: DTCHistoryMapper.vehicleArea(for: fault.code),
            vehicle: vehicle
        )
        context.insert(entry)
        vehicle.historyEntries.append(entry)
        fault.promotedToHistory = true
        fault.historyEntryID = entry.id
        vehicle.updatedAt = Date()
    }
}
