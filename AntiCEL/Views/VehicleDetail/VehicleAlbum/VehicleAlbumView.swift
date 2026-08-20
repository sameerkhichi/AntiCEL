import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct VehicleAlbumView: View {

    @Bindable var vehicle: Vehicle

    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings

    @State private var showingHint = false
    @State private var showingSource = false
    @State private var showingLibrary = false
    @State private var showingCamera = false
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var previewItem: AlbumPreviewItem?
    @State private var isImporting = false

    private let columns = [
        GridItem(.flexible(), spacing: 3),
        GridItem(.flexible(), spacing: 3),
        GridItem(.flexible(), spacing: 3)
    ]

    private var groupedPhotos: [AlbumMonthSection] {
        let photos = vehicle.albumPhotos
            .filter { $0.photoFileName != nil }
            .sorted { $0.displayDate > $1.displayDate }

        let grouped = Dictionary(grouping: photos) { photo in
            AlbumMonthSection.monthID(for: photo.displayDate)
        }

        return grouped.keys.sorted(by: >).compactMap { key in
            guard let photos = grouped[key] else { return nil }
            return AlbumMonthSection(id: key, photos: photos)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Album")
                    .font(.title3.weight(.semibold).width(.condensed))

                HintButton(title: "Album") {
                    showingHint = true
                }

                Spacer()

                Button {
                    showingSource = true
                } label: {
                    Image(systemName: "plus")
                        .font(.body.weight(.semibold))
                }
                .buttonStyle(DashButtonStyle(kind: .compact))
                .disabled(isImporting)
            }
            .padding(.horizontal)

            Rectangle()
                .fill(.quaternary)
                .frame(height: 1)
                .padding(.horizontal)

            if groupedPhotos.isEmpty {
                Text(isImporting ? "Adding photos…" : "No photos yet.")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            } else {
                LazyVStack(alignment: .leading, spacing: 20) {
                    ForEach(groupedPhotos) { section in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(section.title)
                                .font(.appBadge)
                                .tracking(1.6)
                                .textCase(.uppercase)
                                .foregroundStyle(.secondary)

                            LazyVGrid(columns: columns, spacing: 3) {
                                ForEach(section.photos) { photo in
                                    AlbumPhotoCell(photo: photo) {
                                        previewItem = AlbumPreviewItem(
                                            id: photo.persistentModelID,
                                            ref: photo.photoFileName,
                                            capturedAt: photo.displayDate
                                        )
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            delete(photo)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .opacity(isImporting ? 0.72 : 1)
            }
        }
        .padding(.vertical)
        .confirmationDialog("Add a photo", isPresented: $showingSource, titleVisibility: .visible) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Take Photo") {
                    showingCamera = true
                }
            }
            Button("Choose from Library") {
                Task {
                    await PhotoStore.requestPhotoLibraryAccessIfNeeded()
                    showingLibrary = true
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .photosPicker(
            isPresented: $showingLibrary,
            selection: $pickerItems,
            maxSelectionCount: 30,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: pickerItems) { _, items in
            guard !items.isEmpty else { return }
            Task { await importPickerItems(items) }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPicker { image in
                Task { await addCameraPhoto(image) }
            }
            .ignoresSafeArea()
        }
        .fullScreenCover(item: $previewItem) { item in
            PhotoLightbox(ref: item.ref, capturedAt: item.capturedAt, showsSaveButton: true)
        }
        .sheet(isPresented: $showingHint) {
            HintSheet(topic: .album)
        }
        .task {
            await backfillCaptureDates()
        }
    }

    private func importPickerItems(_ items: [PhotosPickerItem]) async {
        isImporting = true
        await PhotoStore.requestPhotoLibraryAccessIfNeeded()

        for item in items {
            let data = try? await item.loadTransferable(type: Data.self)
            let ref = await PhotoStore.persistAlbumPhoto(
                image: data.flatMap(UIImage.init(data:)),
                originalData: data,
                libraryID: item.itemIdentifier,
                copyIntoApp: settings.savePhotosInApp
            )
            let capturedAt = await PhotoStore.captureDate(
                ref: ref,
                libraryID: item.itemIdentifier,
                originalData: data
            )
            if let ref {
                await MainActor.run {
                    insertPhoto(ref: ref, capturedAt: capturedAt)
                }
            }
        }

        await MainActor.run {
            pickerItems = []
            isImporting = false
        }
    }

    private func addCameraPhoto(_ image: UIImage) async {
        isImporting = true
        let ref = await PhotoStore.persistAlbumPhoto(
            image: image,
            originalData: image.jpegData(compressionQuality: 0.95),
            libraryID: nil,
            copyIntoApp: settings.savePhotosInApp
        )
        let capturedAt = await PhotoStore.captureDate(ref: ref) ?? Date()
        await MainActor.run {
            if let ref {
                insertPhoto(ref: ref, capturedAt: capturedAt)
            }
            isImporting = false
        }
    }

    private func insertPhoto(ref: String, capturedAt: Date?) {
        let photo = VehicleAlbumPhoto(
            photoFileName: ref,
            capturedAt: capturedAt ?? Date(),
            vehicle: vehicle
        )
        modelContext.insert(photo)
        vehicle.updatedAt = Date()
    }

    private func backfillCaptureDates() async {
        let photos = vehicle.albumPhotos.filter { $0.capturedAt == nil && $0.photoFileName != nil }
        for photo in photos {
            let date = await PhotoStore.captureDate(ref: photo.photoFileName) ?? photo.createdAt
            photo.capturedAt = date
        }
    }

    private func delete(_ photo: VehicleAlbumPhoto) {
        PhotoStore.deleteAppFile(photo.photoFileName)
        if previewItem?.id == photo.persistentModelID {
            previewItem = nil
        }
        modelContext.delete(photo)
        vehicle.updatedAt = Date()
    }
}

private struct AlbumMonthSection: Identifiable {
    let id: String
    let photos: [VehicleAlbumPhoto]

    var title: String {
        guard let date = Self.date(from: id) else { return id }
        return date.formatted(.dateTime.month(.wide).year())
    }

    static func monthID(for date: Date) -> String {
        let components = Calendar.current.dateComponents([.year, .month], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        return String(format: "%04d-%02d", year, month)
    }

    static func date(from id: String) -> Date? {
        let parts = id.split(separator: "-")
        guard parts.count == 2, let year = Int(parts[0]), let month = Int(parts[1]) else {
            return nil
        }
        return Calendar.current.date(from: DateComponents(year: year, month: month, day: 1))
    }
}

private struct AlbumPreviewItem: Identifiable {
    let id: PersistentIdentifier
    let ref: String?
    let capturedAt: Date?
}

private struct AlbumPhotoCell: View {

    let photo: VehicleAlbumPhoto
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    AlbumPhotoThumbnail(ref: photo.photoFileName)
                }
                .clipped()
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Opens a full screen preview")
    }

    private var accessibilityLabel: String {
        "Album photo, \(photo.displayDate.formatted(date: .abbreviated, time: .omitted))"
    }
}

private struct AlbumPhotoThumbnail: View {

    let ref: String?

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color.primary.opacity(0.06))
                    .overlay {
                        Image(systemName: "photo")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
            }
        }
        .task(id: ref) {
            image = await PhotoStore.loadThumbnail(ref, maxDimension: 400)
        }
    }
}

#Preview {
    VehicleAlbumView(
        vehicle: Vehicle(
            make: "Audi",
            model: "S4",
            year: 2022,
            currentMileage: 79500
        )
    )
    .appTheme()
}
