import SwiftUI
import UIKit

struct PhotoLightbox: View {

    var image: UIImage? = nil
    var ref: String? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var loadedImage: UIImage?

    private var displayedImage: UIImage? {
        image ?? loadedImage
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            if let displayedImage {
                ZoomablePhotoView(image: displayedImage)
                    .ignoresSafeArea()
            } else {
                ProgressView()
                    .tint(.white)
            }

            DashButton(kind: .compact, action: { dismiss() }) {
                Image(systemName: "xmark")
            }
            .padding(.top, 12)
            .padding(.trailing, 16)
            .accessibilityLabel("Close preview")
        }
        .background(Color.black.ignoresSafeArea())
        .presentationBackground(.black)
        .statusBarHidden(false)
        .appTheme()
        .task(id: ref) {
            guard image == nil else { return }
            loadedImage = await PhotoStore.load(ref)
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
