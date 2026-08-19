import Foundation
import Photos
import UIKit

enum PhotoKind {
    case vehicleIcon
    case attachment

    var maxDimension: CGFloat {
        switch self {
        case .vehicleIcon: return 900
        case .attachment: return 1600
        }
    }
}

enum PhotoStore {

    private static let filePrefix = "file:"
    private static let libraryPrefix = "lib:"
    private static let cache = NSCache<NSString, UIImage>()

    static var photosDirectory: URL? {
        let directory = AppGroup.containerURL?.appending(path: "Photos", directoryHint: .isDirectory)
        if let directory {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }

    static func isAppFile(_ ref: String?) -> Bool {
        guard let ref else { return false }
        return ref.hasPrefix(filePrefix)
    }

    static func persist(
        image: UIImage?,
        libraryID: String?,
        replacing oldRef: String?,
        copyIntoApp: Bool,
        kind: PhotoKind
    ) async -> String? {
        let newRef: String?

        if let image {
            if copyIntoApp {
                newRef = saveAppFile(image, kind: kind)
            } else if let libraryID, !libraryID.isEmpty {
                newRef = encodeLibrary(libraryID)
            } else if let savedID = await saveToPhotoLibrary(image) {
                newRef = encodeLibrary(savedID)
            } else {
                newRef = saveAppFile(image, kind: kind)
            }
        } else {
            newRef = nil
        }

        if let oldRef, oldRef != newRef {
            deleteAppFile(oldRef)
        }

        if let newRef, let image {
            cache.setObject(image, forKey: newRef as NSString)
        }

        return newRef
    }

    static func load(_ ref: String?) async -> UIImage? {
        guard let ref, !ref.isEmpty else { return nil }

        if let cached = cache.object(forKey: ref as NSString) {
            return cached
        }

        let image: UIImage?
        if isAppFile(ref) {
            image = loadAppFile(ref)
        } else if let libraryID = libraryIdentifier(from: ref) {
            image = await loadFromPhotoLibrary(libraryID)
        } else {
            image = loadAppFile(ref)
        }

        if let image {
            cache.setObject(image, forKey: ref as NSString)
        }
        return image
    }

    static func loadSync(_ ref: String?) -> UIImage? {
        guard let ref, !ref.isEmpty else { return nil }

        if let cached = cache.object(forKey: ref as NSString) {
            return cached
        }

        guard isAppFile(ref) || !ref.hasPrefix(libraryPrefix) else {
            return nil
        }

        let image = loadAppFile(ref)
        if let image {
            cache.setObject(image, forKey: ref as NSString)
        }
        return image
    }

    static func deleteAppFile(_ ref: String?) {
        guard let ref else { return }
        cache.removeObject(forKey: ref as NSString)

        guard isAppFile(ref) || !ref.hasPrefix(libraryPrefix) else { return }
        guard let url = fileURL(for: ref) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    static func deleteAll(for vehicle: Vehicle) {
        deleteAppFile(vehicle.photoFileName)
        for entry in vehicle.historyEntries {
            deleteAppFile(entry.photoFileName)
        }
        for document in vehicle.documents {
            deleteAppFile(document.photoFileName)
        }
    }

    static func clearAppCopies(in vehicles: [Vehicle]) {
        for vehicle in vehicles {
            if isAppFile(vehicle.photoFileName) {
                deleteAppFile(vehicle.photoFileName)
                vehicle.photoFileName = nil
            }
            for entry in vehicle.historyEntries where isAppFile(entry.photoFileName) {
                deleteAppFile(entry.photoFileName)
                entry.photoFileName = nil
            }
            for document in vehicle.documents where isAppFile(document.photoFileName) {
                deleteAppFile(document.photoFileName)
                document.photoFileName = nil
            }
        }

        guard let directory = photosDirectory else { return }
        if let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) {
            for file in files {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }

    static func requestPhotoLibraryAccessIfNeeded() async {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .notDetermined else { return }
        _ = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }

    static func photosAssetIdentifier(from ref: String?) -> String? {
        guard let ref else { return nil }
        return libraryIdentifier(from: ref)
    }

    private static func saveAppFile(_ image: UIImage, kind: PhotoKind) -> String? {
        guard
            let directory = photosDirectory,
            let data = jpegData(from: image, maxDimension: kind.maxDimension)
        else {
            return nil
        }

        let fileName = "\(UUID().uuidString).jpg"
        let url = directory.appending(path: fileName)
        do {
            try data.write(to: url, options: .atomic)
            return filePrefix + fileName
        } catch {
            return nil
        }
    }

    private static func loadAppFile(_ ref: String) -> UIImage? {
        guard let url = fileURL(for: ref) else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    private static func fileURL(for ref: String) -> URL? {
        let fileName: String
        if ref.hasPrefix(filePrefix) {
            fileName = String(ref.dropFirst(filePrefix.count))
        } else if ref.hasPrefix(libraryPrefix) {
            return nil
        } else {
            fileName = ref
        }
        guard !fileName.isEmpty else { return nil }
        return photosDirectory?.appending(path: fileName)
    }

    private static func encodeLibrary(_ identifier: String) -> String {
        libraryPrefix + identifier
    }

    private static func libraryIdentifier(from ref: String) -> String? {
        guard ref.hasPrefix(libraryPrefix) else { return nil }
        let identifier = String(ref.dropFirst(libraryPrefix.count))
        return identifier.isEmpty ? nil : identifier
    }

    private static func saveToPhotoLibrary(_ image: UIImage) async -> String? {
        await requestPhotoLibraryAccessIfNeeded()

        return await withCheckedContinuation { continuation in
            var localID: String?
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
                localID = request.placeholderForCreatedAsset?.localIdentifier
            }) { success, _ in
                continuation.resume(returning: success ? localID : nil)
            }
        }
    }

    private static func loadFromPhotoLibrary(_ identifier: String) async -> UIImage? {
        await requestPhotoLibraryAccessIfNeeded()

        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        guard let asset = assets.firstObject else { return nil }

        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = true
            options.version = .current

            PHImageManager.default().requestImageDataAndOrientation(
                for: asset,
                options: options
            ) { data, _, _, _ in
                continuation.resume(returning: data.flatMap(UIImage.init(data:)))
            }
        }
    }

    static func preparedForWidget(_ image: UIImage, maxDimension: CGFloat = 720) -> UIImage {
        resized(image, maxDimension: maxDimension)
    }

    private static func jpegData(from image: UIImage, maxDimension: CGFloat, quality: CGFloat = 0.72) -> Data? {
        resized(image, maxDimension: maxDimension).jpegData(compressionQuality: quality)
    }

    private static func resized(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > maxDimension, longest > 0 else { return image }

        let scale = maxDimension / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
