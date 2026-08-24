import Foundation
import UserNotifications

enum OBDDriveNotifications {
    static let identifierPrefix = "anticel.obd."
    static let defaultCoolantAlertC = 110
    static let defaultOilAlertC = 130
    static let productionDelay: TimeInterval = 10 * 60
    #if DEBUG
    static let mockDelay: TimeInterval = 15
    #endif

    static func delay(isMock: Bool) -> TimeInterval {
        #if DEBUG
        if isMock { return mockDelay }
        #endif
        return productionDelay
    }

    struct TripSummary {
        var vehicleID: UUID
        var vehicleName: String
        var delay: TimeInterval
        var lastFuelPercent: Double?
        var fillUpThresholdPercent: Int
        var notifyFillUp: Bool
        var newFaultCodes: [String]
        var notifyFaults: Bool
        var maxCoolantC: Double?
        var notifyCoolant: Bool
        var coolantThresholdC: Int
        var maxOilTempC: Double?
        var notifyOil: Bool
        var oilThresholdC: Int
    }

    static func identifiers(for vehicleID: UUID) -> [String] {
        let id = vehicleID.uuidString
        return [
            "\(identifierPrefix)fillup.\(id)",
            "\(identifierPrefix)dtc.\(id)",
            "\(identifierPrefix)temp.\(id)",
            "\(identifierPrefix)oil.\(id)",
        ]
    }

    static func cancel(vehicleID: UUID) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: identifiers(for: vehicleID))
    }

    static func schedule(_ summary: TripSummary) {
        cancel(vehicleID: summary.vehicleID)

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(summary.delay, 1),
            repeats: false
        )
        let ids = identifiers(for: summary.vehicleID)
        let name = summary.vehicleName

        if summary.notifyFillUp,
           let fuel = summary.lastFuelPercent,
           fuel <= Double(summary.fillUpThresholdPercent) {
            add(
                id: ids[0],
                title: "Time to fill up?",
                body: "\(name) finished a drive at \(Int(fuel.rounded()))% fuel, at or below your \(summary.fillUpThresholdPercent)% reminder.",
                trigger: trigger
            )
        }

        if summary.notifyFaults, !summary.newFaultCodes.isEmpty {
            let shown = summary.newFaultCodes.prefix(3).joined(separator: ", ")
            let extra = summary.newFaultCodes.count > 3
                ? " and \(summary.newFaultCodes.count - 3) more"
                : ""
            let title = summary.newFaultCodes.count == 1
                ? "Fault found on this drive"
                : "Faults found on this drive"
            add(
                id: ids[1],
                title: title,
                body: "\(name) reported \(shown)\(extra) during the last drive.",
                trigger: trigger
            )
        }

        if summary.notifyCoolant,
           let maxC = summary.maxCoolantC,
           maxC >= Double(summary.coolantThresholdC) {
            add(
                id: ids[2],
                title: "Coolant temperature spiked",
                body: "Coolant on \(name) reached \(formattedTemperature(maxC)), above your \(formattedTemperature(Double(summary.coolantThresholdC))) alert.",
                trigger: trigger
            )
        }

        if summary.notifyOil,
           let maxOilC = summary.maxOilTempC,
           maxOilC >= Double(summary.oilThresholdC) {
            add(
                id: ids[3],
                title: "Oil temperature spiked",
                body: "Oil on \(name) reached \(formattedTemperature(maxOilC)), above your \(formattedTemperature(Double(summary.oilThresholdC))) alert.",
                trigger: trigger
            )
        }
    }

    private static func add(
        id: String,
        title: String,
        body: String,
        trigger: UNTimeIntervalNotificationTrigger
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private static func formattedTemperature(_ celsius: Double) -> String {
        AppSettings.shared.formattedTemperature(celsius)
    }
}
