import Foundation

enum AppGroup {
    static let identifier = "group.SRKSolutions.AntiCEL"
    static let storeFileName = "AntiCEL.store"
    static let appBundleIdentifier = "SRKSolutions.AntiCEL"

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }

    static var storeURL: URL? {
        containerURL?.appending(path: storeFileName)
    }
}

enum AntiCELWidgetKind {
    static let mileage = "SRKSolutions.AntiCEL.mileage"
}

enum AntiCELDeepLink {
    static let scheme = "anticel"

    static func mileage(vehicleID: UUID) -> URL {
        URL(string: "\(scheme)://vehicle/\(vehicleID.uuidString)/mileage")!
    }

    static func vehicleIDForMileage(from url: URL) -> UUID? {
        guard url.scheme == scheme, url.host == "vehicle" else {
            return nil
        }

        let parts = url.pathComponents.filter { $0 != "/" }
        guard parts.count >= 2, parts[1] == "mileage" else {
            return nil
        }

        return UUID(uuidString: parts[0])
    }
}
