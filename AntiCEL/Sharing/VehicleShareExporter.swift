import Foundation

enum VehicleShareExporter {
    private static let jsonOverhead: Int64 = 8_192

    @MainActor
    static func estimate(vehicle: Vehicle, options: VehicleShareOptions) -> VehicleShareEstimate {
        var byteCount = jsonOverhead
        var skipped = 0
        var included = 0

        for ref in photoRefs(on: vehicle, options: options) {
            if let size = portableSize(for: ref) {
                byteCount += size
                included += 1
            } else {
                skipped += 1
            }
        }

        return VehicleShareEstimate(
            byteCount: byteCount,
            skippedPhotoCount: skipped,
            includedPhotoCount: included
        )
    }

    @MainActor
    static func export(vehicle: Vehicle, options: VehicleShareOptions) async throws -> URL {
        let prepared = try prepare(vehicle: vehicle, options: options)
        let destination = FileManager.default.temporaryDirectory
            .appending(path: fileName(for: vehicle))

        try await Task.detached(priority: .userInitiated) {
            try AnticelArchive.write(
                manifestJSON: prepared.manifestJSON,
                vehicleJSON: prepared.vehicleJSON,
                photos: prepared.photos,
                to: destination
            )
        }.value

        return destination
    }

    static func fileName(for vehicle: Vehicle) -> String {
        let parts = [String(vehicle.year), vehicle.make, vehicle.model]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let base = parts.joined(separator: " ")
        let cleaned = base
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        return "\(cleaned.isEmpty ? "Vehicle" : cleaned).anticel"
    }

    @MainActor
    private static func prepare(vehicle: Vehicle, options: VehicleShareOptions) throws -> PreparedExport {
        var photos: [AnticelArchive.PhotoSource] = []
        var skipped = 0

        func pack(_ ref: String?) -> String? {
            guard let ref, !ref.isEmpty else { return nil }
            guard let url = PhotoStore.appFileURL(for: ref) else {
                skipped += 1
                return nil
            }

            let ext = url.pathExtension.isEmpty ? "jpg" : url.pathExtension
            let fileName = "\(UUID().uuidString).\(ext)"
            photos.append(
                AnticelArchive.PhotoSource(
                    archivePath: AnticelArchive.photosFolder + fileName,
                    fileURL: url
                )
            )
            return fileName
        }

        let snapshot = VehicleShareSnapshot(
            make: vehicle.make,
            model: vehicle.model,
            year: vehicle.year,
            nickname: vehicle.nickname,
            vin: options.includeVIN ? vehicle.vin : "",
            currentMileage: vehicle.currentMileage,
            photo: pack(vehicle.photoFileName),
            photoScale: vehicle.photoScale,
            photoOffsetX: vehicle.photoOffsetX,
            photoOffsetY: vehicle.photoOffsetY,
            createdAt: vehicle.createdAt,
            updatedAt: vehicle.updatedAt,
            historyEntries: options.includeHistory
                ? vehicle.historyEntries.map { entry in
                    VehicleShareSnapshot.HistorySnapshot(
                        title: entry.title,
                        details: entry.details,
                        date: entry.date,
                        mileage: entry.mileage,
                        category: entry.category,
                        vehicleArea: entry.vehicleArea,
                        photo: pack(entry.photoFileName)
                    )
                }
                : [],
            documents: options.includeDocuments
                ? vehicle.documents.map { document in
                    VehicleShareSnapshot.DocumentSnapshot(
                        title: document.title,
                        details: document.details,
                        category: document.category,
                        date: document.date,
                        expirationDate: document.expirationDate,
                        photo: pack(document.photoFileName),
                        createdAt: document.createdAt,
                        updatedAt: document.updatedAt
                    )
                }
                : [],
            albumPhotos: options.includeAlbum
                ? vehicle.albumPhotos.compactMap { photo in
                    guard let packed = pack(photo.photoFileName) else { return nil }
                    return VehicleShareSnapshot.AlbumPhotoSnapshot(
                        photo: packed,
                        createdAt: photo.createdAt,
                        updatedAt: photo.updatedAt,
                        capturedAt: photo.capturedAt
                    )
                }
                : [],
            reminders: options.includeReminders
                ? vehicle.serviceReminders.map { reminder in
                    VehicleShareSnapshot.ReminderSnapshot(
                        name: reminder.name,
                        type: reminder.type,
                        dueDate: reminder.dueDate,
                        dueMileage: reminder.dueMileage,
                        notes: reminder.notes,
                        isCompleted: reminder.isCompleted,
                        vehicleArea: reminder.vehicleArea
                    )
                }
                : [],
            notes: options.includeNotes
                ? vehicle.notes.map { note in
                    VehicleShareSnapshot.NoteSnapshot(
                        title: note.title,
                        content: note.content,
                        createdAt: note.createdAt,
                        updatedAt: note.updatedAt
                    )
                }
                : [],
            shops: options.includeShops
                ? vehicle.shops.map { shop in
                    VehicleShareSnapshot.ShopSnapshot(
                        name: shop.name,
                        details: shop.details,
                        createdAt: shop.createdAt,
                        updatedAt: shop.updatedAt
                    )
                }
                : []
        )

        let manifest = VehicleShareManifest(
            formatVersion: VehicleShareFormat.currentVersion,
            exportedAt: Date(),
            includeVIN: options.includeVIN,
            includeHistory: options.includeHistory,
            includeDocuments: options.includeDocuments,
            includeAlbum: options.includeAlbum,
            includeReminders: options.includeReminders,
            includeNotes: options.includeNotes,
            includeShops: options.includeShops,
            skippedPhotoCount: skipped
        )

        return PreparedExport(
            manifestJSON: try encode(manifest),
            vehicleJSON: try encode(snapshot),
            photos: photos
        )
    }

    private static func encode<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(value)
    }

    private static func photoRefs(on vehicle: Vehicle, options: VehicleShareOptions) -> [String] {
        var refs: [String] = []
        if let hero = vehicle.photoFileName, !hero.isEmpty {
            refs.append(hero)
        }
        if options.includeHistory {
            refs.append(contentsOf: vehicle.historyEntries.compactMap(\.photoFileName).filter { !$0.isEmpty })
        }
        if options.includeDocuments {
            refs.append(contentsOf: vehicle.documents.compactMap(\.photoFileName).filter { !$0.isEmpty })
        }
        if options.includeAlbum {
            refs.append(contentsOf: vehicle.albumPhotos.compactMap(\.photoFileName).filter { !$0.isEmpty })
        }
        return refs
    }

    private static func portableSize(for ref: String) -> Int64? {
        let size = PhotoStore.appFileSize(for: ref)
        return size > 0 ? size : nil
    }

    private struct PreparedExport: Sendable {
        var manifestJSON: Data
        var vehicleJSON: Data
        var photos: [AnticelArchive.PhotoSource]
    }
}
