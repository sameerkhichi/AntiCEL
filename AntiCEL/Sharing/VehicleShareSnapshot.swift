import Foundation

enum VehicleShareFormat {
    static let currentVersion = 1
}

struct VehicleShareManifest: Codable, Equatable {
    var formatVersion: Int
    var exportedAt: Date
    var includeVIN: Bool
    var includeHistory: Bool
    var includeDocuments: Bool
    var includeAlbum: Bool
    var includeReminders: Bool
    var includeNotes: Bool
    var includeShops: Bool
    var skippedPhotoCount: Int
}

struct VehicleShareSnapshot: Codable {
    var make: String
    var model: String
    var year: Int
    var nickname: String
    var vin: String
    var currentMileage: Int
    var photo: String?
    var photoScale: Double?
    var photoOffsetX: Double?
    var photoOffsetY: Double?
    var createdAt: Date
    var updatedAt: Date
    var historyEntries: [HistorySnapshot]
    var documents: [DocumentSnapshot]
    var albumPhotos: [AlbumPhotoSnapshot]
    var reminders: [ReminderSnapshot]
    var notes: [NoteSnapshot]
    var shops: [ShopSnapshot]

    var displayName: String {
        if !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return nickname
        }
        return "\(year) \(make) \(model)"
    }

    struct HistorySnapshot: Codable {
        var title: String
        var details: String
        var date: Date
        var mileage: Int?
        var category: HistoryCategory
        var vehicleArea: VehicleArea?
        var photo: String?
    }

    struct DocumentSnapshot: Codable {
        var title: String
        var details: String
        var category: DocumentCategory
        var date: Date
        var expirationDate: Date?
        var photo: String?
        var createdAt: Date
        var updatedAt: Date
    }

    struct AlbumPhotoSnapshot: Codable {
        var photo: String?
        var createdAt: Date
        var updatedAt: Date
        var capturedAt: Date?
    }

    struct ReminderSnapshot: Codable {
        var name: String
        var type: ReminderType
        var dueDate: Date?
        var dueMileage: Int?
        var notes: String
        var isCompleted: Bool
        var vehicleArea: VehicleArea?
    }

    struct NoteSnapshot: Codable {
        var title: String
        var content: String
        var createdAt: Date
        var updatedAt: Date
    }

    struct ShopSnapshot: Codable {
        var name: String
        var details: String
        var createdAt: Date
        var updatedAt: Date
    }
}
