import Foundation
import CoreBluetooth

enum OBDConnectionState: Equatable {
    case disconnected
    case scanning
    case connecting
    case initializing
    case connected
    case unsupportedAdapter
}

enum OBDError: LocalizedError, Equatable {
    case bluetoothUnavailable
    case notConnected
    case timeout
    case handshakeFailed
    case noData
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .bluetoothUnavailable:
            return "Bluetooth is not available. Turn it on in Settings and try again."
        case .notConnected:
            return "No adapter is connected."
        case .timeout:
            return "The adapter did not respond in time."
        case .handshakeFailed:
            return "This adapter is not supported. AntiCEL works with BLE ELM327 adapters such as the Veepeak OBDCheck BLE+."
        case .noData:
            return "The vehicle did not return data for that request. The ignition may be off, or the PID may not be supported."
        case .commandFailed(let message):
            return message
        }
    }
}

struct OBDDiscoveredDevice: Identifiable, Hashable {
    var id: UUID
    var name: String
    var rssi: Int
}

struct OBDFaultReading: Hashable {
    var code: String
    var status: DiagnosticFaultStatus
}

struct MileageJumpProposal: Equatable {
    var vehicleID: UUID
    var currentKm: Int
    var proposedKm: Int
    var source: String
}

struct OBDLiveTelemetry: Equatable {
    var rpm: Double?
    var speedKmh: Double?
    var fuelPercent: Double?
    var odometerKm: Double?
    var milOn: Bool?
    var dtcCount: Int?
}
