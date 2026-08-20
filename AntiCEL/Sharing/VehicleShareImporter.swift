import Foundation
import SwiftData
import UniformTypeIdentifiers

struct PendingVehicleImport: Identifiable {
    let id = UUID()
    let url: URL
    var deleteOnDismiss = true
}

enum VehicleShareImporter {
    struct Preview {
        var manifest: VehicleShareManifest
        var snapshot: VehicleShareSnapshot
        var byteCount: Int64
    }

    static func isVehiclePackage(_ url: URL) -> Bool {
        if url.pathExtension.lowercased() == "anticel" {
            return true
        }
        return UTType(filenameExtension: url.pathExtension)?.conforms(to: .anticelVehicle) == true
    }

    static func copyToTemporaryFile(_ url: URL) throws -> URL {
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let ext = url.pathExtension.isEmpty ? "anticel" : url.pathExtension
        let destination = FileManager.default.temporaryDirectory
            .appending(path: "import-\(UUID().uuidString).\(ext)")

        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }

        do {
            try FileManager.default.copyItem(at: url, to: destination)
        } catch {
            throw VehicleShareError.copyFailed
        }

        return destination
    }

    static func preview(from url: URL) throws -> Preview {
        let files = try AnticelArchive.readFiles(
            [AnticelArchive.manifestPath, AnticelArchive.vehiclePath],
            from: url
        )
        var preview = try decodePreview(files)
        preview.byteCount = payloadByteCount(for: url)
        return preview
    }

    @MainActor
    static func importVehicle(from url: URL, into context: ModelContext) throws -> Vehicle {
        let files = try AnticelArchive.readAll(from: url)
        let preview = try decodePreview(files)
        try validate(preview.manifest)

        var photoMap: [String: String] = [:]
        for (path, data) in files where path.hasPrefix(AnticelArchive.photosFolder) {
            let fileName = (path as NSString).lastPathComponent
            guard !fileName.isEmpty else { continue }
            let ext = URL(fileURLWithPath: fileName).pathExtension
            if let imported = PhotoStore.importAppFile(data: data, fileExtension: ext) {
                photoMap[fileName] = imported
            }
        }

        let snapshot = preview.snapshot
        let now = Date()
        let vehicle = Vehicle(
            make: snapshot.make,
            model: snapshot.model,
            year: snapshot.year,
            nickname: snapshot.nickname,
            vin: snapshot.vin,
            currentMileage: snapshot.currentMileage
        )
        vehicle.createdAt = now
        vehicle.updatedAt = now
        vehicle.photoFileName = resolvedPhoto(snapshot.photo, map: photoMap)
        if vehicle.photoFileName != nil {
            vehicle.photoScale = snapshot.photoScale
            vehicle.photoOffsetX = snapshot.photoOffsetX
            vehicle.photoOffsetY = snapshot.photoOffsetY
        }

        context.insert(vehicle)

        if preview.manifest.includeHistory {
            for entry in snapshot.historyEntries {
                let history = HistoryEntry(
                    title: entry.title,
                    details: entry.details,
                    date: entry.date,
                    mileage: entry.mileage,
                    category: entry.category,
                    vehicleArea: entry.vehicleArea ?? .misc,
                    photoFileName: resolvedPhoto(entry.photo, map: photoMap),
                    vehicle: vehicle
                )
                context.insert(history)
            }
        }

        if preview.manifest.includeDocuments {
            for document in snapshot.documents {
                let imported = VehicleDocument(
                    title: document.title,
                    details: document.details,
                    category: document.category,
                    date: document.date,
                    expirationDate: document.expirationDate,
                    photoFileName: resolvedPhoto(document.photo, map: photoMap),
                    vehicle: vehicle
                )
                imported.createdAt = document.createdAt
                imported.updatedAt = document.updatedAt
                context.insert(imported)
            }
        }

        if preview.manifest.includeAlbum {
            for photo in snapshot.albumPhotos {
                guard let ref = resolvedPhoto(photo.photo, map: photoMap) else { continue }
                let imported = VehicleAlbumPhoto(photoFileName: ref, vehicle: vehicle)
                imported.createdAt = photo.createdAt
                imported.updatedAt = photo.updatedAt
                context.insert(imported)
            }
        }

        if preview.manifest.includeReminders {
            for reminder in snapshot.reminders {
                let imported = ServiceReminder(
                    name: reminder.name,
                    type: reminder.type,
                    dueDate: reminder.dueDate,
                    dueMileage: reminder.dueMileage,
                    notes: reminder.notes,
                    isCompleted: reminder.isCompleted,
                    vehicleArea: reminder.vehicleArea ?? .misc
                )
                imported.vehicle = vehicle
                context.insert(imported)
            }
        }

        if preview.manifest.includeNotes {
            for note in snapshot.notes {
                let imported = VehicleNote(title: note.title, content: note.content)
                imported.createdAt = note.createdAt
                imported.updatedAt = note.updatedAt
                imported.vehicle = vehicle
                context.insert(imported)
            }
        }

        if preview.manifest.includeShops {
            for shop in snapshot.shops {
                let imported = VehicleShop(name: shop.name, details: shop.details)
                imported.createdAt = shop.createdAt
                imported.updatedAt = shop.updatedAt
                imported.vehicle = vehicle
                context.insert(imported)
            }
        }

        try context.save()
        WidgetReloader.reload()
        ReminderNotifications.refresh(using: context)
        return vehicle
    }

    private static func decodePreview(_ files: [String: Data]) throws -> Preview {
        guard let manifestData = files[AnticelArchive.manifestPath],
              let vehicleData = files[AnticelArchive.vehiclePath]
        else {
            throw VehicleShareError.missingVehicleData
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let manifest: VehicleShareManifest
        let snapshot: VehicleShareSnapshot
        do {
            manifest = try decoder.decode(VehicleShareManifest.self, from: manifestData)
            snapshot = try decoder.decode(VehicleShareSnapshot.self, from: vehicleData)
        } catch {
            throw VehicleShareError.invalidPackage
        }

        try validate(manifest)
        return Preview(manifest: manifest, snapshot: snapshot, byteCount: 0)
    }

    private static func payloadByteCount(for url: URL) -> Int64 {
        if let counted = try? AnticelArchive.payloadByteCount(from: url), counted > 0 {
            return counted
        }

        let values = try? url.resourceValues(forKeys: [.fileSizeKey])
        return Int64(values?.fileSize ?? 0)
    }

    private static func validate(_ manifest: VehicleShareManifest) throws {
        if manifest.formatVersion < 1 {
            throw VehicleShareError.invalidPackage
        }
        if manifest.formatVersion > VehicleShareFormat.currentVersion {
            throw VehicleShareError.unsupportedVersion(manifest.formatVersion)
        }
    }

    private static func resolvedPhoto(_ name: String?, map: [String: String]) -> String? {
        guard let name, !name.isEmpty else { return nil }
        return map[name]
    }
}
