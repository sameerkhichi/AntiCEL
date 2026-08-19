import Foundation

enum VehicleShareError: LocalizedError {
    case invalidPackage
    case unsupportedVersion(Int)
    case unsupportedCompression
    case writeFailed
    case missingVehicleData
    case copyFailed

    var errorDescription: String? {
        switch self {
        case .invalidPackage:
            return "This file isn’t a valid AntiCEL vehicle."
        case .unsupportedVersion(let version):
            return "This vehicle was shared from a newer version of AntiCEL (format \(version))."
        case .unsupportedCompression:
            return "This vehicle file uses compression AntiCEL can’t read."
        case .writeFailed:
            return "AntiCEL couldn’t create the share file."
        case .missingVehicleData:
            return "This vehicle file is missing its contents."
        case .copyFailed:
            return "AntiCEL couldn’t open the shared vehicle file."
        }
    }
}
