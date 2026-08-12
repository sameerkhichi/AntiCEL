import SwiftUI

struct VehicleModelCanvas: View {

    let selectedArea: VehicleArea?
    let onSelect: (VehicleArea) -> Void

    @State private var wheelRotation: Double = 0
    @State private var hoodAngle: Double = 0
    @State private var trunkAngle: Double = 0
    @State private var wheelsSpinning = false

    private var focusScale: CGFloat {
        selectedArea == nil ? 1.0 : 1.18
    }

    private var focusOffset: CGSize {
        switch selectedArea {
        case .drivetrain:
            return CGSize(width: 36, height: 8)
        case .body:
            return .zero
        case .wheels:
            return CGSize(width: 0, height: -10)
        case .misc:
            return CGSize(width: -40, height: 6)
        case nil:
            return .zero
        }
    }

    var body: some View {

        GeometryReader { geo in

            let width = geo.size.width
            let height = geo.size.height
            let carWidth = min(width * 0.88, 360.0)
            let carHeight = carWidth * 0.42
            let origin = CGPoint(
                x: (width - carWidth) / 2,
                y: (height - carHeight) / 2
            )

            ZStack {

                //ground shadow
                Capsule()
                    .fill(Color.black.opacity(0.12))
                    .frame(width: carWidth * 0.9, height: 14)
                    .offset(y: carHeight * 0.42)
                    .blur(radius: 4)

                carBody(origin: origin, size: CGSize(width: carWidth, height: carHeight))

                //tappable overlays
                hotspotOverlays(origin: origin, size: CGSize(width: carWidth, height: carHeight))

            }
            .frame(width: width, height: height)
            .scaleEffect(focusScale)
            .offset(focusOffset)
            .animation(.spring(response: 0.45, dampingFraction: 0.82), value: selectedArea)

        }
        .onChange(of: selectedArea) { _, newValue in
            animateSelection(newValue)
        }

    }

    @ViewBuilder
    private func carBody(origin: CGPoint, size: CGSize) -> some View {

        let w = size.width
        let h = size.height

        ZStack(alignment: .topLeading) {

            //main cabin / body
            RoundedRectangle(cornerRadius: h * 0.18, style: .continuous)
                .fill(bodyFill)
                .frame(width: w * 0.58, height: h * 0.42)
                .overlay {
                    RoundedRectangle(cornerRadius: h * 0.18, style: .continuous)
                        .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                .offset(x: origin.x + w * 0.22, y: origin.y + h * 0.08)
                .opacity(dimExcept(.body))

            //windows
            HStack(spacing: w * 0.02) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.cyan.opacity(0.28))
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.cyan.opacity(0.22))
            }
            .frame(width: w * 0.42, height: h * 0.18)
            .offset(x: origin.x + w * 0.30, y: origin.y + h * 0.14)
            .opacity(dimExcept(.body))

            //hood (drivetrain)
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(hoodFill)
                .frame(width: w * 0.26, height: h * 0.28)
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                }
                .rotationEffect(
                    .degrees(hoodAngle),
                    anchor: .trailing
                )
                .offset(x: origin.x + w * 0.02, y: origin.y + h * 0.22)
                .opacity(dimExcept(.drivetrain))

            //engine hint under hood when open / selected
            if selectedArea == .drivetrain {
                Image(systemName: "engine.combustion.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)
                    .offset(x: origin.x + w * 0.10, y: origin.y + h * 0.30)
                    .transition(.opacity.combined(with: .scale))
            }

            //trunk (misc)
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(trunkFill)
                .frame(width: w * 0.20, height: h * 0.26)
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                }
                .rotationEffect(
                    .degrees(trunkAngle),
                    anchor: .leading
                )
                .offset(x: origin.x + w * 0.78, y: origin.y + h * 0.24)
                .opacity(dimExcept(.misc))

            if selectedArea == .misc {
                Image(systemName: "shippingbox.fill")
                    .font(.caption)
                    .foregroundStyle(.brown)
                    .offset(x: origin.x + w * 0.84, y: origin.y + h * 0.32)
                    .transition(.opacity.combined(with: .scale))
            }

            //lower rocker / sill
            Capsule()
                .fill(Color.secondary.opacity(0.35))
                .frame(width: w * 0.72, height: h * 0.06)
                .offset(x: origin.x + w * 0.14, y: origin.y + h * 0.52)
                .opacity(dimExcept(.body))

            //wheels
            wheel(
                at: CGPoint(x: origin.x + w * 0.22, y: origin.y + h * 0.62),
                radius: h * 0.18
            )
            .opacity(dimExcept(.wheels))

            wheel(
                at: CGPoint(x: origin.x + w * 0.72, y: origin.y + h * 0.62),
                radius: h * 0.18
            )
            .opacity(dimExcept(.wheels))

            //labels when idle
            if selectedArea == nil {
                partLabel("Hood", x: origin.x + w * 0.10, y: origin.y - 4)
                partLabel("Body", x: origin.x + w * 0.45, y: origin.y - 4)
                partLabel("Trunk", x: origin.x + w * 0.82, y: origin.y - 4)
                partLabel("Wheels", x: origin.x + w * 0.45, y: origin.y + h * 0.88)
            }

        }
        .animation(.easeInOut(duration: 0.35), value: selectedArea)

    }

    private func wheel(at center: CGPoint, radius: CGFloat) -> some View {

        ZStack {

            Circle()
                .fill(Color(.systemGray2))
                .frame(width: radius * 2, height: radius * 2)

            Circle()
                .stroke(Color.primary.opacity(0.35), lineWidth: 3)
                .frame(width: radius * 2, height: radius * 2)

            //spokes
            ForEach(0..<5, id: \.self) { index in
                Capsule()
                    .fill(Color.primary.opacity(0.55))
                    .frame(width: 3, height: radius * 0.9)
                    .rotationEffect(.degrees(Double(index) * 72))
            }

            Circle()
                .fill(Color(.systemGray4))
                .frame(width: radius * 0.45, height: radius * 0.45)

        }
        .rotationEffect(.degrees(wheelsSpinning ? wheelRotation : 0))
        .position(center)

    }

    private func hotspotOverlays(origin: CGPoint, size: CGSize) -> some View {

        let w = size.width
        let h = size.height

        return ZStack(alignment: .topLeading) {

            //drivetrain / hood
            Button {
                onSelect(.drivetrain)
            } label: {
                Color.clear
                    .frame(width: w * 0.28, height: h * 0.42)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .offset(x: origin.x, y: origin.y + h * 0.12)

            //body
            Button {
                onSelect(.body)
            } label: {
                Color.clear
                    .frame(width: w * 0.42, height: h * 0.42)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .offset(x: origin.x + w * 0.28, y: origin.y + h * 0.05)

            //trunk / misc
            Button {
                onSelect(.misc)
            } label: {
                Color.clear
                    .frame(width: w * 0.24, height: h * 0.42)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .offset(x: origin.x + w * 0.74, y: origin.y + h * 0.12)

            //wheels strip
            Button {
                onSelect(.wheels)
            } label: {
                Color.clear
                    .frame(width: w * 0.86, height: h * 0.32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .offset(x: origin.x + w * 0.07, y: origin.y + h * 0.52)

        }

    }

    private func partLabel(_ text: String, x: CGFloat, y: CGFloat) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .position(x: x, y: y)
    }

    private var bodyFill: Color {
        selectedArea == .body
            ? Color.accentColor.opacity(0.55)
            : Color(.systemGray3)
    }

    private var hoodFill: Color {
        selectedArea == .drivetrain
            ? Color.orange.opacity(0.55)
            : Color(.systemGray4)
    }

    private var trunkFill: Color {
        selectedArea == .misc
            ? Color.brown.opacity(0.45)
            : Color(.systemGray4)
    }

    private func dimExcept(_ area: VehicleArea) -> Double {
        guard let selectedArea else { return 1 }
        return selectedArea == area ? 1 : 0.35
    }

    private func animateSelection(_ area: VehicleArea?) {

        withAnimation(.easeInOut(duration: 0.4)) {
            hoodAngle = area == .drivetrain ? -28 : 0
            trunkAngle = area == .misc ? 32 : 0
        }

        if area == .wheels {
            wheelsSpinning = true
            wheelRotation = 0
            withAnimation(.linear(duration: 1.1).repeatForever(autoreverses: false)) {
                wheelRotation = 360
            }
        } else {
            wheelsSpinning = false
            withAnimation(.easeOut(duration: 0.25)) {
                wheelRotation = 0
            }
        }

    }

}
