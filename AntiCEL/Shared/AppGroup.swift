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
