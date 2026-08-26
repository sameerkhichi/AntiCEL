import Foundation

struct VehicleShareOptions: Equatable {
    var includeVIN = false
    var includeHistory = true
    var includeDocuments = false
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
