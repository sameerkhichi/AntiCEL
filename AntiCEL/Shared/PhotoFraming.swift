import SwiftUI
import UIKit

struct PhotoFraming: Equatable, Sendable {
    /// Extra zoom on top of aspect-fill. 1 = fill the frame.
    var scale: Double = 1
    /// Horizontal bias of the crop. -1 shows the left edge, 1 shows the right.
    var offsetX: Double = 0
    /// Vertical bias of the crop. -1 shows the top edge, 1 shows the bottom.
    var offsetY: Double = 0

    static let identity = PhotoFraming()

    static let minScale: Double = 1
    static let maxScale: Double = 4

    var clamped: PhotoFraming {
        PhotoFraming(
            scale: min(max(scale, Self.minScale), Self.maxScale),
            offsetX: min(max(offsetX, -1), 1),
            offsetY: min(max(offsetY, -1), 1)
        )
    }

    struct Layout {
        var drawnSize: CGSize
        var offset: CGPoint
        var extra: CGSize
    }

    static func layout(
        imageSize: CGSize,
        frameSize: CGSize,
        framing: PhotoFraming
    ) -> Layout {
        guard
            imageSize.width > 0,
            imageSize.height > 0,
            frameSize.width > 0,
            frameSize.height > 0
        else {
            return Layout(drawnSize: frameSize, offset: .zero, extra: .zero)
        }

        let framing = framing.clamped
        let imageAspect = imageSize.width / imageSize.height
        let frameAspect = frameSize.width / frameSize.height

        let drawn: CGSize
        if imageAspect > frameAspect {
            let height = frameSize.height * framing.scale
            drawn = CGSize(width: height * imageAspect, height: height)
        } else {
            let width = frameSize.width * framing.scale
            drawn = CGSize(width: width, height: width / imageAspect)
        }

        let extra = CGSize(
            width: drawn.width - frameSize.width,
            height: drawn.height - frameSize.height
        )

        let rawX = -extra.width / 2 - framing.offsetX * extra.width / 2
        let rawY = -extra.height / 2 - framing.offsetY * extra.height / 2

        return Layout(
            drawnSize: drawn,
            offset: CGPoint(
                x: min(0, max(-extra.width, rawX)),
                y: min(0, max(-extra.height, rawY))
            ),
            extra: extra
        )
    }
}

struct FramedPhotoView: View {
    let image: UIImage
    var framing: PhotoFraming = .identity

    var body: some View {
        GeometryReader { geo in
            let layout = PhotoFraming.layout(
                imageSize: image.orientedSize,
                frameSize: geo.size,
                framing: framing
            )

            Image(uiImage: image)
                .resizable()
                .interpolation(.high)
                .frame(width: layout.drawnSize.width, height: layout.drawnSize.height)
                .offset(x: layout.offset.x, y: layout.offset.y)
                .frame(
                    width: geo.size.width,
                    height: geo.size.height,
                    alignment: .topLeading
                )
                .clipped()
        }
        .clipped()
    }
}

struct VehiclePhotoScrim: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color.black.opacity(0.12),
                Color.black.opacity(0.08),
                Color.black.opacity(0.62)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .allowsHitTesting(false)
    }
}

extension UIImage {
    var orientedSize: CGSize {
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            return CGSize(width: size.height, height: size.width)
        default:
            return size
        }
    }
}
