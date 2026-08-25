import Foundation
import SwiftData

@Model
final class PairedAdapter {

    var id: UUID
    var peripheralIdentifier: UUID
    var name: String
    var lastSeenAt: Date
    var createdAt: Date

    // Optional so older stores (created before drive alerts) still load.
    var notifyFillUpReminders: Bool? = true
    var fillUpThresholdPercent: Int? = 15
    var notifyDriveFaults: Bool? = true
    var notifyHighEngineTemp: Bool? = true
    var notifyHighCoolantTemp: Bool? = nil
    var notifyHighOilTemp: Bool? = nil
    var coolantAlertThresholdC: Int? = 110
    var oilAlertThresholdC: Int? = 130
    var lastFuelPercent: Double? = nil

    var vehicle: Vehicle?

    var fillUpRemindersEnabled: Bool {
        get { notifyFillUpReminders ?? true }
        set { notifyFillUpReminders = newValue }
    }

    var fillUpThresholdPercentValue: Int {
        get { fillUpThresholdPercent ?? 15 }
        set { fillUpThresholdPercent = newValue }
    }

    var driveFaultsEnabled: Bool {
        get { notifyDriveFaults ?? true }
        set { notifyDriveFaults = newValue }
    }

    var highCoolantTempEnabled: Bool {
        get { notifyHighCoolantTemp ?? notifyHighEngineTemp ?? true }
        set { notifyHighCoolantTemp = newValue }
    }

    var coolantAlertThresholdCValue: Int {
        get { min(max(coolantAlertThresholdC ?? 110, 80), 150) }
        set { coolantAlertThresholdC = min(max(newValue, 80), 150) }
    }

    var highOilTempEnabled: Bool {
        get { notifyHighOilTemp ?? notifyHighEngineTemp ?? true }
        set { notifyHighOilTemp = newValue }
    }

    var oilAlertThresholdCValue: Int {
        get { min(max(oilAlertThresholdC ?? 130, 90), 170) }
        set { oilAlertThresholdC = min(max(newValue, 90), 170) }
    }

    init(
        peripheralIdentifier: UUID,
        name: String,
        vehicle: Vehicle? = nil
    ) {
        self.id = UUID()
        self.peripheralIdentifier = peripheralIdentifier
        self.name = name
        self.lastSeenAt = Date()
        self.createdAt = Date()
        self.vehicle = vehicle
    }
}
