import Foundation

#if DEBUG
enum OBDMockAdapter {
    static let identifier = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEE1")!
    static let name = "Veepeak Mock"

    static var discoveredDevice: OBDDiscoveredDevice {
        OBDDiscoveredDevice(id: identifier, name: name, rssi: -42)
    }

    static let sampleFaults: [OBDFaultReading] = [
        OBDFaultReading(code: "P0420", status: .stored),
        OBDFaultReading(code: "P0300", status: .pending),
    ]

    static let fuelPercent = 28.0
    static let rpm = 2_140.0
    static let speedKmh = 72.0
    static let mileageJumpKm = 95
}
#endif
