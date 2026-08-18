import Photos
import PhotosUI
import SwiftUI
import UIKit

struct PhotoDraft: Equatable {
    var preview: UIImage?
    var libraryIdentifier: String?
    var originalRef: String?
    var didChange = false

    var hasPhoto: Bool {
        preview != nil || (!didChange && originalRef != nil)
    }

    mutating func load(from ref: String?) {
        originalRef = ref
        preview = PhotoStore.loadSync(ref)
        libraryIdentifier = PhotoStore.photosAssetIdentifier(from: ref)
        didChange = false
    }

    mutating func setPicked(image: UIImage, libraryID: String?) {
        preview = image
        libraryIdentifier = libraryID
        didChange = true
    }

    mutating func remove() {
        preview = nil
        libraryIdentifier = nil
        didChange = true
    }

    func commit(copyIntoApp: Bool, kind: PhotoKind) async -> String? {
        if !didChange {
            return originalRef
        }

        return await PhotoStore.persist(
            image: preview,
            libraryID: libraryIdentifier,
            replacing: originalRef,
            copyIntoApp: copyIntoApp,
            kind: kind
        )
    }
}

enum PhotoPreviewStyle {
    case vehicleIcon
    case wide
}

struct PhotoAttachmentField: View {

    @Environment(\.appTheme) private var theme
    @Environment(AppSettings.self) private var settings

    var label: String = "Photo"
    var footnote: String? = nil
    var style: PhotoPreviewStyle = .wide
    var usesInfotainmentChrome = true

    @Binding var draft: PhotoDraft

    @State private var pickerItem: PhotosPickerItem?
    @State private var showingLibrary = false
    @State private var showingCamera = false
    @State private var showingSource = false

    var body: some View {
        Group {
            if usesInfotainmentChrome {
                InfotainmentField(label: label) {
                    fieldContent
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    InfotainmentSectionHeader(title: label)
                    fieldContent
                }
            }
        }
        .confirmationDialog("Add a photo", isPresented: $showingSource, titleVisibility: .visible) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Take Photo") {
                    showingCamera = true
                }
            }
            Button("Choose from Library") {
                showingLibrary = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .modifier(
            PhotoLibraryPickerModifier(
                isPresented: $showingLibrary,
                selection: $pickerItem,
                copyIntoApp: settings.savePhotosInApp
            )
        )
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task { await loadPickerItem(item) }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPicker { image in
                draft.setPicked(image: image, libraryID: nil)
            }
            .ignoresSafeArea()
        }
        .task(id: draft.originalRef) {
            guard draft.preview == nil, !draft.didChange, let ref = draft.originalRef else { return }
            draft.preview = await PhotoStore.load(ref)
        }
    }

    private var fieldContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            preview

            HStack(spacing: 10) {
                Button {
                    showingSource = true
                } label: {
                    Text(draft.hasPhoto ? "Change Photo" : "Add Photo")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(theme.accentColor)

                if draft.hasPhoto {
                    Button(role: .destructive) {
                        draft.remove()
                    } label: {
                        Text("Remove")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                }
            }

            if let footnote {
                Text(footnote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if settings.lowStorageMode {
                Text("Low Storage Mode is on, so this stays in your camera roll.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var preview: some View {
        switch style {
        case .vehicleIcon:
            vehiclePreview
        case .wide:
            widePreview
        }
    }

    private var vehiclePreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(theme.keyFace)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(theme.edge, lineWidth: 1)
                }

            if let preview = draft.preview {
                Image(uiImage: preview)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 108, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                Image(systemName: "car.side.fill")
                    .font(.system(size: 36, weight: .regular))
                    .foregroundStyle(Color.primary.opacity(0.78))
            }
        }
        .frame(width: 116, height: 80)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var widePreview: some View {
        if let preview = draft.preview {
            Image(uiImage: preview)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 148)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        } else {
            HStack(spacing: 10) {
                Image(systemName: "photo")
                    .font(.title3)
                    .foregroundStyle(theme.accentColor)
                Text("Optional")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        }
    }

    private func loadPickerItem(_ item: PhotosPickerItem) async {
        if !settings.savePhotosInApp {
            await PhotoStore.requestPhotoLibraryAccessIfNeeded()
        }

        guard
            let data = try? await item.loadTransferable(type: Data.self),
            let image = UIImage(data: data)
        else {
            return
        }

        draft.setPicked(image: image, libraryID: item.itemIdentifier)
        pickerItem = nil
    }
}

struct StoredPhotoView<Placeholder: View>: View {

    let ref: String?
    var contentMode: ContentMode = .fill
    @ViewBuilder var placeholder: () -> Placeholder

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                placeholder()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .task(id: ref) {
            image = await PhotoStore.load(ref)
        }
    }
}

struct VehiclePhotoIcon: View {

    let photoFileName: String?
    var width: CGFloat = 72
    var height: CGFloat = 48
    var symbolSize: CGFloat = 44
    var cornerRadius: CGFloat = 10

    var body: some View {
        if photoFileName == nil {
            Image(systemName: "car.side.fill")
                .font(.system(size: symbolSize, weight: .regular))
                .foregroundStyle(Color.primary.opacity(0.88))
        } else {
            StoredPhotoView(ref: photoFileName) {
                Image(systemName: "car.side.fill")
                    .font(.system(size: symbolSize * 0.7, weight: .regular))
                    .foregroundStyle(Color.primary.opacity(0.55))
            }
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.accentColor.opacity(0.35), lineWidth: 1)
            }
        }
    }
}

struct PhotoThumbnail: View {

    let ref: String?
    var size: CGFloat = 40

    var body: some View {
        StoredPhotoView(ref: ref) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(0.06))
                .overlay {
                    Image(systemName: "photo")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct CameraPicker: UIViewControllerRepresentable {

    var onPicked: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(onPicked: onPicked, dismiss: dismiss)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onPicked: (UIImage) -> Void
        let dismiss: DismissAction

        init(onPicked: @escaping (UIImage) -> Void, dismiss: DismissAction) {
            self.onPicked = onPicked
            self.dismiss = dismiss
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onPicked(image)
            }
            dismiss()
        }
    }
}

private struct PhotoLibraryPickerModifier: ViewModifier {

    @Binding var isPresented: Bool
    @Binding var selection: PhotosPickerItem?
    var copyIntoApp: Bool

    func body(content: Content) -> some View {
        if copyIntoApp {
            content.photosPicker(
                isPresented: $isPresented,
                selection: $selection,
                matching: .images
            )
        } else {
            content.photosPicker(
                isPresented: $isPresented,
                selection: $selection,
                matching: .images,
                photoLibrary: .shared()
            )
        }
    }
}
