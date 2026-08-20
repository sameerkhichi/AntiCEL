import SwiftUI
import UIKit

struct PhotoLightbox: View {

    var image: UIImage? = nil
    var ref: String? = nil
    var capturedAt: Date? = nil
    var showsSaveButton = false

    @Environment(\.dismiss) private var dismiss
    @State private var loadedImage: UIImage?
    @State private var isSaving = false
    @State private var saveMessage: String?
    @State private var resolvedCapturedAt: Date?

    private var displayedImage: UIImage? {
        image ?? loadedImage
    }

    private var displayedCapturedAt: Date? {
        capturedAt ?? resolvedCapturedAt
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            if let displayedImage {
                ZoomablePhotoView(image: displayedImage)
                    .ignoresSafeArea()
            } else {
                ProgressView()
                    .tint(.white)
            }

            HStack {
                if showsSaveButton {
                    DashButton(kind: .compact, action: saveToLibrary) {
                        if isSaving {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.primary)
                        } else {
                            Image(systemName: "square.and.arrow.down")
                        }
                    }
                    .disabled(isSaving || ref == nil)
                    .accessibilityLabel("Save to Photos")
                }

                Spacer()

                DashButton(kind: .compact, action: { dismiss() }) {
                    Image(systemName: "xmark")
                }
                .accessibilityLabel("Close preview")
            }
            .overlay {
                if let displayedCapturedAt {
                    VStack(spacing: 2) {
                        Text(displayedCapturedAt.formatted(.dateTime.month(.wide).day().year()))
                            .font(.subheadline.weight(.semibold))
                        Text(displayedCapturedAt.formatted(date: .omitted, time: .shortened))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.78))
                    }
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.75)
                    .lineLimit(2)
                    .padding(.horizontal, 72)
                    .shadow(color: .black.opacity(0.45), radius: 4, y: 1)
                    .allowsHitTesting(false)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(displayedCapturedAt.formatted(date: .long, time: .shortened))
                }
            }
            .padding(.top, 12)
            .padding(.horizontal, 16)

            if let saveMessage {
                Text(saveMessage)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.55), in: Capsule())
                    .padding(.top, 64)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .presentationBackground(.black)
        .statusBarHidden(false)
        .appTheme()
        .task(id: ref) {
            if image == nil {
                loadedImage = await PhotoStore.load(ref)
            }
            if capturedAt == nil, showsSaveButton {
                resolvedCapturedAt = await PhotoStore.captureDate(ref: ref)
            }
        }
    }

    private func saveToLibrary() {
        guard !isSaving, ref != nil else { return }
        isSaving = true
        saveMessage = nil

        Task {
            let saved = await PhotoStore.saveOriginalToDeviceLibrary(ref)
            await MainActor.run {
                isSaving = false
                saveMessage = saved ? "Saved to Photos" : "Couldn’t save photo"
            }
        }
    }
}

private struct ZoomablePhotoView: UIViewRepresentable {
    let image: UIImage

    func makeUIView(context: Context) -> ZoomableImageScrollView {
        let view = ZoomableImageScrollView()
        view.image = image
        return view
    }

    func updateUIView(_ uiView: ZoomableImageScrollView, context: Context) {
        if uiView.image !== image {
            uiView.image = image
        }
    }
}

fileprivate final class ZoomableImageScrollView: UIScrollView, UIScrollViewDelegate {

    private let imageView = UIImageView()
    private var lastBoundsSize: CGSize = .zero

    var image: UIImage? {
        didSet {
            imageView.image = image
            lastBoundsSize = .zero
            setNeedsLayout()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        delegate = self
        minimumZoomScale = 1
        maximumZoomScale = 5
        bouncesZoom = true
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        backgroundColor = .black
        contentInsetAdjustmentBehavior = .never
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        addSubview(imageView)

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTap)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.size != lastBoundsSize {
            lastBoundsSize = bounds.size
            fitImage()
        } else {
            centerImage()
        }
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImage()
    }

    private func fitImage() {
        guard let image, bounds.width > 0, bounds.height > 0 else { return }

        zoomScale = 1
        let size = image.orientedSize
        guard size.width > 0, size.height > 0 else { return }

        let scale = min(bounds.width / size.width, bounds.height / size.height)
        let width = size.width * scale
        let height = size.height * scale
        imageView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        contentSize = imageView.bounds.size
        centerImage()
    }

    private func centerImage() {
        let offsetX = max((bounds.width - contentSize.width) * 0.5, 0)
        let offsetY = max((bounds.height - contentSize.height) * 0.5, 0)
        imageView.center = CGPoint(
            x: contentSize.width * 0.5 + offsetX,
            y: contentSize.height * 0.5 + offsetY
        )
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if zoomScale > minimumZoomScale + 0.01 {
            setZoomScale(minimumZoomScale, animated: true)
            return
        }

        let point = gesture.location(in: imageView)
        let zoomFactor: CGFloat = 2.5
        let size = bounds.size
        let width = size.width / zoomFactor
        let height = size.height / zoomFactor
        zoom(
            to: CGRect(x: point.x - width / 2, y: point.y - height / 2, width: width, height: height),
            animated: true
        )
    }
}
