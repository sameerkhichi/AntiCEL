import Foundation
import ImageIO
import Photos
import UIKit

enum PhotoKind {
    case vehicleIcon
    case attachment
    case album

    var maxDimension: CGFloat? {
        switch self {
        case .vehicleIcon: return 900
        case .attachment: return 1600
        case .album: return nil
        }
    }

    var jpegQuality: CGFloat {
        switch self {
        case .album: return 0.95
        case .vehicleIcon, .attachment: return 0.72
        }
    }
}

enum PhotoStore {

    private static let filePrefix = "file:"
    private static let libraryPrefix = "lib:"
    private static let cache = NSCache<NSString, UIImage>()
    private static let thumbnailCache = NSCache<NSString, UIImage>()

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

    static func appFileURL(for ref: String?) -> URL? {
        guard let ref, !ref.isEmpty, !ref.hasPrefix(libraryPrefix) else { return nil }
        guard let url = fileURL(for: ref) else { return nil }
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return url
    }

    static func appFileSize(for ref: String?) -> Int64 {
        guard let url = appFileURL(for: ref) else { return 0 }
        let values = try? url.resourceValues(forKeys: [.fileSizeKey])
        return Int64(values?.fileSize ?? 0)
    }

    static func importAppFile(data: Data, fileExtension: String? = nil) -> String? {
        guard let directory = photosDirectory else { return nil }

        let ext: String
        if let fileExtension, !fileExtension.isEmpty {
            ext = fileExtension
        } else {
            ext = Self.fileExtension(for: data)
        }

        let fileName = "\(UUID().uuidString).\(ext)"
        let url = directory.appending(path: fileName)
        do {
            try data.write(to: url, options: .atomic)
            return filePrefix + fileName
        } catch {
            return nil
        }
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

    static func persistAlbumPhoto(
        image: UIImage?,
        originalData: Data?,
        libraryID: String?,
        copyIntoApp: Bool
    ) async -> String? {
        if copyIntoApp {
            if let libraryID, let ref = await copyOriginalResource(libraryID: libraryID) {
                return ref
            }
            if let originalData, let ref = saveOriginalAppFile(data: originalData) {
                return ref
            }
            if let image {
                return saveAppFile(image, kind: .album)
            }
            return nil
        }

        if let libraryID, !libraryID.isEmpty {
            return encodeLibrary(libraryID)
        }
        if let image, let savedID = await saveToPhotoLibrary(image) {
            return encodeLibrary(savedID)
        }
        if let originalData, let image = UIImage(data: originalData), let savedID = await saveToPhotoLibrary(image) {
            return encodeLibrary(savedID)
        }
        return nil
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

    static func loadThumbnail(_ ref: String?, maxDimension: CGFloat) async -> UIImage? {
        guard let ref, !ref.isEmpty else { return nil }

        let cacheKey = "\(ref)#\(Int(maxDimension))" as NSString
        if let cached = thumbnailCache.object(forKey: cacheKey) {
            return cached
        }

        let image: UIImage?
        if isAppFile(ref) || !ref.hasPrefix(libraryPrefix) {
            image = thumbnailFromAppFile(ref, maxDimension: maxDimension)
        } else if let libraryID = libraryIdentifier(from: ref) {
            image = await thumbnailFromPhotoLibrary(libraryID, maxDimension: maxDimension)
        } else {
            image = thumbnailFromAppFile(ref, maxDimension: maxDimension)
        }

        if let image {
            thumbnailCache.setObject(image, forKey: cacheKey)
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
        for photo in vehicle.albumPhotos {
            deleteAppFile(photo.photoFileName)
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
            for photo in vehicle.albumPhotos where isAppFile(photo.photoFileName) {
                deleteAppFile(photo.photoFileName)
                photo.photoFileName = nil
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

    static func requestPhotoLibraryAddAccessIfNeeded() async {
        let readWrite = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if readWrite == .authorized || readWrite == .limited {
            return
        }

        let addOnly = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if addOnly == .authorized {
            return
        }

        if addOnly == .notDetermined {
            _ = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            return
        }

        if readWrite == .notDetermined {
            _ = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        }
    }

    static func photosAssetIdentifier(from ref: String?) -> String? {
        guard let ref else { return nil }
        return libraryIdentifier(from: ref)
    }

    static func saveOriginalToDeviceLibrary(_ ref: String?) async -> Bool {
        guard let ref, !ref.isEmpty else { return false }
        await requestPhotoLibraryAddAccessIfNeeded()

        if let url = fileURL(for: ref), FileManager.default.fileExists(atPath: url.path) {
            return await addFileToPhotoLibrary(url)
        }

        if let libraryID = libraryIdentifier(from: ref) {
            return await duplicateLibraryAsset(libraryID)
        }

        if let image = await load(ref) {
            return await saveToPhotoLibrary(image) != nil
        }

        return false
    }

    private static func saveAppFile(_ image: UIImage, kind: PhotoKind) -> String? {
        guard let directory = photosDirectory else { return nil }

        let data: Data?
        if let maxDimension = kind.maxDimension {
            data = jpegData(from: image, maxDimension: maxDimension, quality: kind.jpegQuality)
        } else {
            data = image.jpegData(compressionQuality: kind.jpegQuality)
        }
        guard let data else { return nil }

        let fileName = "\(UUID().uuidString).jpg"
        let url = directory.appending(path: fileName)
        do {
            try data.write(to: url, options: .atomic)
            return filePrefix + fileName
        } catch {
            return nil
        }
    }

    private static func saveOriginalAppFile(data: Data) -> String? {
        guard let directory = photosDirectory else { return nil }

        let fileName = "\(UUID().uuidString).\(fileExtension(for: data))"
        let url = directory.appending(path: fileName)
        do {
            try data.write(to: url, options: .atomic)
            return filePrefix + fileName
        } catch {
            return nil
        }
    }

    private static func copyOriginalResource(libraryID: String) async -> String? {
        await requestPhotoLibraryAccessIfNeeded()

        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [libraryID], options: nil)
        guard let asset = assets.firstObject else { return nil }

        let resources = PHAssetResource.assetResources(for: asset)
        guard
            let resource = resources.first(where: { $0.type == .fullSizePhoto })
                ?? resources.first(where: { $0.type == .photo }),
            let directory = photosDirectory
        else {
            return nil
        }

        let ext = URL(fileURLWithPath: resource.originalFilename).pathExtension
        let fileName = "\(UUID().uuidString).\(ext.isEmpty ? "jpg" : ext)"
        let url = directory.appending(path: fileName)

        do {
            try await writeResource(resource, to: url)
            return filePrefix + fileName
        } catch {
            try? FileManager.default.removeItem(at: url)
            return nil
        }
    }

    private static func loadAppFile(_ ref: String) -> UIImage? {
        guard let url = fileURL(for: ref) else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    private static func thumbnailFromAppFile(_ ref: String, maxDimension: CGFloat) -> UIImage? {
        guard let url = fileURL(for: ref) else { return nil }
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension,
            kCGImageSourceShouldCacheImmediately: true
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }

    private static func thumbnailFromPhotoLibrary(_ identifier: String, maxDimension: CGFloat) async -> UIImage? {
        await requestPhotoLibraryAccessIfNeeded()

        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        guard let asset = assets.firstObject else { return nil }

        let scale = await MainActor.run { UIScreen.main.scale }
        let pixelSize = maxDimension * scale

        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = true
            options.version = .current

            let resumeOnce = ResumeOnce<UIImage?>(continuation)
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: pixelSize, height: pixelSize),
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                if (info?[PHImageResultIsDegradedKey] as? Bool) == true {
                    return
                }
                resumeOnce.resume(returning: image)
            }
        }
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
        await requestPhotoLibraryAddAccessIfNeeded()

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

    private static func addFileToPhotoLibrary(_ url: URL) async -> Bool {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, fileURL: url, options: nil)
            }) { success, _ in
                continuation.resume(returning: success)
            }
        }
    }

    private static func duplicateLibraryAsset(_ identifier: String) async -> Bool {
        await requestPhotoLibraryAccessIfNeeded()

        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        guard let asset = assets.firstObject else { return false }

        let resources = PHAssetResource.assetResources(for: asset)
        guard
            let resource = resources.first(where: { $0.type == .fullSizePhoto })
                ?? resources.first(where: { $0.type == .photo })
        else {
            if let image = await loadFromPhotoLibrary(identifier) {
                return await saveToPhotoLibrary(image) != nil
            }
            return false
        }

        let ext = URL(fileURLWithPath: resource.originalFilename).pathExtension
        let tempURL = FileManager.default.temporaryDirectory
            .appending(path: "\(UUID().uuidString).\(ext.isEmpty ? "jpg" : ext)")

        do {
            try await writeResource(resource, to: tempURL)
            let saved = await addFileToPhotoLibrary(tempURL)
            try? FileManager.default.removeItem(at: tempURL)
            return saved
        } catch {
            try? FileManager.default.removeItem(at: tempURL)
            if let image = await loadFromPhotoLibrary(identifier) {
                return await saveToPhotoLibrary(image) != nil
            }
            return false
        }
    }

    private static func writeResource(_ resource: PHAssetResource, to url: URL) async throws {
        let options = PHAssetResourceRequestOptions()
        options.isNetworkAccessAllowed = true

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHAssetResourceManager.default().writeData(for: resource, toFile: url, options: options) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
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
            options.resizeMode = .none
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

    private static func fileExtension(for data: Data) -> String {
        if data.starts(with: [0xFF, 0xD8, 0xFF]) {
            return "jpg"
        }
        if data.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
            return "png"
        }
        if data.count > 11 {
            let brand = data.subdata(in: 4..<8)
            if brand == Data("ftyp".utf8) {
                return "heic"
            }
        }
        return "jpg"
    }
}

private final class ResumeOnce<Value>: @unchecked Sendable {
    private var continuation: CheckedContinuation<Value, Never>?

    init(_ continuation: CheckedContinuation<Value, Never>) {
        self.continuation = continuation
    }

    func resume(returning value: Value) {
        continuation?.resume(returning: value)
        continuation = nil
    }
}
