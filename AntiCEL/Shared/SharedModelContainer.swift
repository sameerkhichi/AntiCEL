import Foundation
import SwiftData

enum SharedModelContainer {

    static let schema = Schema([
        Vehicle.self,
        ServiceReminder.self,
        VehicleNote.self,
        HistoryEntry.self,
        VehicleDocument.self
    ])

    static func make() throws -> ModelContainer {
        if let storeURL = AppGroup.storeURL {
            migrateLegacyStoreIfNeeded(to: storeURL)
            let configuration = ModelConfiguration(schema: schema, url: storeURL)
            return try ModelContainer(for: schema, configurations: [configuration])
        }

        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private static func migrateLegacyStoreIfNeeded(to destination: URL) {
        guard Bundle.main.bundleIdentifier == AppGroup.appBundleIdentifier else {
            return
        }

        let fileManager = FileManager.default
        guard !fileManager.fileExists(atPath: destination.path) else {
            return
        }

        guard
            let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        else {
            return
        }

        let legacyStore = appSupport.appending(path: "default.store")
        guard fileManager.fileExists(atPath: legacyStore.path) else {
            return
        }

        let destinationDirectory = destination.deletingLastPathComponent()
        try? fileManager.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)

        for suffix in ["", "-wal", "-shm"] {
            let source = URL(fileURLWithPath: legacyStore.path + suffix)
            let target = URL(fileURLWithPath: destination.path + suffix)
            guard fileManager.fileExists(atPath: source.path) else {
                continue
            }
            try? fileManager.copyItem(at: source, to: target)
        }
    }
}
