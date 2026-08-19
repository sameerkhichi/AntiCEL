import Foundation

struct VehicleShareOptions: Equatable {
    var includeVIN = false
    var includeHistory = true
    var includeDocuments = true
    var includeAlbum = true
    var includeReminders = true
    var includeNotes = true
    var includeShops = true
}

struct VehicleShareEstimate: Equatable {
    var byteCount: Int64
    var skippedPhotoCount: Int
    var includedPhotoCount: Int
}
