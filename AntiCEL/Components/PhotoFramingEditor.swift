import SwiftUI
import UIKit

struct PhotoFramingEditorSheet: View {

    let image: UIImage
    @Binding var framing: PhotoFraming

    var year: Int
    var make: String
    var model: String
    var nickname: String
    var mileage: Int

    @Environment(\.dismiss) private var dismiss
    @State private var draft: PhotoFraming

    init(
        image: UIImage,
        framing: Binding<PhotoFraming>,
        year: Int,
        make: String,
        model: String,
        nickname: String,
        mileage: Int
    ) {
        self.image = image
        self._framing = framing
        self.year = year
        self.make = make
        self.model = model
        self.nickname = nickname
        self.mileage = mileage
        _draft = State(initialValue: framing.wrappedValue)
    }

    var body: some View {
        InfotainmentScaffold(
            title: "Frame Photo",
            confirmTitle: "Done",
            scrolls: false,
            onCancel: { dismiss() },
            onConfirm: {
                framing = draft.clamped
                dismiss()
            }
        ) {
            Text("Drag to reposition. Pinch to zoom. This is how the photo appears in your garage.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            PhotoFramingCanvas(image: image, framing: $draft) {
                garagePreviewOverlay
            }
            .aspectRatio(1.5, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
            }

            Button {
                draft = .identity
            } label: {
                Text("Reset Frame")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.accentColor)
        }
        .appTheme()
    }

    private var garagePreviewOverlay: some View {
        ZStack(alignment: .bottom) {
            ParkingStallOverlay()
                .stroke(Color.white.opacity(0.55), style: StrokeStyle(lineWidth: 3, lineCap: .square, lineJoin: .miter))
                .padding(10)
                .allowsHitTesting(false)

            VehiclePhotoScrim()

            VStack(spacing: 6) {
                Text("\(String(year))  \(make.uppercased())  \(model.uppercased())")
                    .font(.appBadge)
                    .tracking(1.4)
                    .foregroundStyle(Color.white.opacity(0.9))

                if !nickname.isEmpty {
                    Text(nickname)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.white)
                        .shadow(color: .black.opacity(0.4), radius: 4, y: 1)
                }

                OdometerView(mileage: mileage, compact: true)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 18)
            .frame(maxWidth: .infinity)
            .allowsHitTesting(false)
        }
    }
}

struct PhotoFramingCanvas<Overlay: View>: View {
    let image: UIImage
    @Binding var framing: PhotoFraming
    @ViewBuilder var overlay: () -> Overlay

    @State private var dragOrigin: PhotoFraming?
    @State private var pinchOrigin: PhotoFraming?
    @State private var canvasSize: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black

                FramedPhotoView(image: image, framing: framing)
                    .frame(width: geo.size.width, height: geo.size.height)

                overlay()
            }
            .contentShape(Rectangle())
            .highPriorityGesture(dragGesture)
            .simultaneousGesture(pinchGesture)
            .onAppear { canvasSize = geo.size }
            .onChange(of: geo.size) { _, size in
                canvasSize = size
            }
        }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let origin = dragOrigin ?? framing
                if dragOrigin == nil {
                    dragOrigin = origin
                }

                let layout = PhotoFraming.layout(
                    imageSize: image.orientedSize,
                    frameSize: canvasSize,
                    framing: origin
                )

                var next = origin
                if layout.extra.width > 1 {
                    next.offsetX = origin.offsetX - (2 * value.translation.width / layout.extra.width)
                }
                if layout.extra.height > 1 {
                    next.offsetY = origin.offsetY - (2 * value.translation.height / layout.extra.height)
                }
                framing = next.clamped
            }
            .onEnded { _ in
                dragOrigin = nil
            }
    }

    private var pinchGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let origin = pinchOrigin ?? framing
                if pinchOrigin == nil {
                    pinchOrigin = origin
                }
                var next = origin
                next.scale = origin.scale * value.magnification
                framing = next.clamped
            }
            .onEnded { _ in
                pinchOrigin = nil
            }
    }
}

private struct ParkingStallOverlay: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let inset: CGFloat = 6
        path.move(to: CGPoint(x: inset, y: inset))
        path.addLine(to: CGPoint(x: inset, y: rect.height - inset))
        path.addLine(to: CGPoint(x: rect.width - inset, y: rect.height - inset))
        path.addLine(to: CGPoint(x: rect.width - inset, y: inset))
        return path
    }
}
