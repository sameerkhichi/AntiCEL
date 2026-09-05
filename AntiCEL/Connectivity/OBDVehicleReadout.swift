import Foundation

enum OBDSignalAvailability: String {
    case reported
    case supported
    case notSupported
    case unknown
}

struct OBDSignalReadout: Identifiable, Equatable {
    var id: String
    var title: String
    var availability: OBDSignalAvailability
    var valueText: String?

    var statusText: String {
        switch availability {
        case .reported:
            return valueText ?? "Reported"
        case .supported:
            return "Supported, no reading yet"
        case .notSupported:
            return "Not sent by this vehicle"
        case .unknown:
            return "Not confirmed yet"
        }
    }
}

enum OBDMileageUpdateMode: Equatable {
    case vehicleOdometer
    case tripDistance
    case awaitingConfirmation
    case unknown

    var title: String {
        switch self {
        case .vehicleOdometer:
            return "Vehicle odometer"
        case .tripDistance:
            return "Trip distance from speed"
        case .awaitingConfirmation:
            return "Odometer waiting for confirmation"
        case .unknown:
            return "Not confirmed yet"
        }
    }

    var explanation: String {
        switch self {
        case .vehicleOdometer:
            return "This vehicle reports odometer over OBD (PID 01A6). AntiCEL copies that mileage when it is close to the garage value."
        case .tripDistance:
            return "This vehicle does not send odometer over standard OBD. Mileage is added from speed and time while you drive."
        case .awaitingConfirmation:
            return "The vehicle sent an odometer reading that is much higher than the garage mileage. Confirm the update so a large jump is not saved by mistake."
        case .unknown:
            return "AntiCEL has not confirmed a mileage source yet. Turn the ignition on and stay on Connect for a moment, then open this again."
        }
    }
}

struct OBDVehicleReadout: Equatable {
    var adapterName: String
    var busAwake: Bool
    var mileageMode: OBDMileageUpdateMode
    var signals: [OBDSignalReadout]
}

enum OBDVehicleReadoutBuilder {

    static func make(
        adapterName: String,
        supportedPIDs: Set<UInt8>,
        telemetry: OBDLiveTelemetry,
        mileageJumpPending: Bool,
        didApplyOdometer: Bool
    ) -> OBDVehicleReadout {
        let mapKnown = !supportedPIDs.isEmpty
        let mileageMode: OBDMileageUpdateMode
        if mileageJumpPending {
            mileageMode = .awaitingConfirmation
        } else if telemetry.odometerKm != nil || didApplyOdometer {
            mileageMode = .vehicleOdometer
        } else if mapKnown && !supportedPIDs.contains(0xA6) {
            mileageMode = .tripDistance
        } else {
            mileageMode = .unknown
        }

        let busAwake = telemetry.rpm != nil
            || telemetry.speedKmh != nil
            || telemetry.fuelPercent != nil
            || telemetry.coolantTempC != nil
            || telemetry.oilTempC != nil
            || telemetry.milOn != nil
            || telemetry.odometerKm != nil

        func signal(
            id: String,
            title: String,
            pid: UInt8?,
            value: String?
        ) -> OBDSignalReadout {
            if let value {
                return OBDSignalReadout(id: id, title: title, availability: .reported, valueText: value)
            }
            if let pid, mapKnown {
                return OBDSignalReadout(
                    id: id,
                    title: title,
                    availability: supportedPIDs.contains(pid) ? .supported : .notSupported,
                    valueText: nil
                )
            }
            return OBDSignalReadout(id: id, title: title, availability: .unknown, valueText: nil)
        }

        let milText: String?
        if let milOn = telemetry.milOn {
            let count = telemetry.dtcCount.map { " · \($0) stored" } ?? ""
            milText = (milOn ? "On" : "Off") + count
        } else {
            milText = nil
        }

        let odometerText = telemetry.odometerKm.map { "\(Int($0.rounded())) km" }

        let signals = [
            signal(id: "rpm", title: "Engine RPM", pid: 0x0C, value: telemetry.rpm.map { "\(Int($0.rounded())) rpm" }),
            signal(id: "speed", title: "Speed", pid: 0x0D, value: telemetry.speedKmh.map { "\(Int($0.rounded())) km/h" }),
            signal(id: "fuel", title: "Fuel level", pid: 0x2F, value: telemetry.fuelPercent.map { "\(Int($0.rounded()))%" }),
            signal(id: "coolant", title: "Coolant temperature", pid: 0x05, value: telemetry.coolantTempC.map { String(format: "%.0f°C", $0) }),
            signal(id: "oil", title: "Oil temperature", pid: 0x5C, value: telemetry.oilTempC.map { String(format: "%.0f°C", $0) }),
            signal(id: "odo", title: "Odometer", pid: 0xA6, value: odometerText),
            signal(id: "mil", title: "Check engine / MIL", pid: 0x01, value: milText),
            OBDSignalReadout(
                id: "faults",
                title: "Stored fault codes",
                availability: busAwake ? .supported : .unknown,
                valueText: busAwake ? "Scanned over Mode $03 / $07 / $0A" : nil
            )
        ]

        return OBDVehicleReadout(
            adapterName: adapterName,
            busAwake: busAwake,
            mileageMode: mileageMode,
            signals: signals
        )
    }
}
