import CoreBluetooth
import Foundation

enum OBDAdapterProfile {

    static let restoreIdentifier = "SRKSolutions.AntiCEL.obd"

    static let uartServices: [CBUUID] = [
        CBUUID(string: "FFF0"),
        CBUUID(string: "FFE0"),
        CBUUID(string: "18F0"),
        CBUUID(string: "49535343-FE7D-4AE5-8FA9-9FAFD205E455"),
    ]

    static let preferredNotify: [CBUUID] = [
        CBUUID(string: "FFF1"),
        CBUUID(string: "FFE1"),
        CBUUID(string: "18F1"),
        CBUUID(string: "49535343-ACA3-481C-91EC-D85E28A60318"),
    ]

    static let preferredWrite: [CBUUID] = [
        CBUUID(string: "FFF2"),
        CBUUID(string: "FFE1"),
        CBUUID(string: "18F2"),
        CBUUID(string: "49535343-6DAA-4DA4-4D02-ABF619569ACA69FE"),
        CBUUID(string: "49535343-6DAA-4D02-ABF6-19569ACA69FE"),
    ]

    static let nameHints = [
        "VEEPEAK",
        "OBD",
        "ELM",
        "VGATE",
        "V-LINK",
        "VLINK",
        "OBDLINK",
        "CARISTA",
        "ICAR",
        "KONNWEI",
        "NEXLINK",
        "V-SCAN",
        "LELink",
        "LELINK",
    ]

    static func displayName(for peripheral: CBPeripheral, advertisementName: String?) -> String {
        let raw = (peripheral.name ?? advertisementName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if raw.isEmpty {
            return "BLE Adapter"
        }
        return raw
    }

    static func isLikelyAdapter(name: String, advertisedServices: [CBUUID]) -> Bool {
        let upper = name.uppercased()
        if nameHints.contains(where: { upper.contains($0) }) {
            return true
        }
        return advertisedServices.contains(where: { uartServices.contains($0) })
    }

    static let connectOptions: [String: Any] = [
        CBConnectPeripheralOptionNotifyOnConnectionKey: true,
        CBConnectPeripheralOptionNotifyOnDisconnectionKey: true,
    ]
}
