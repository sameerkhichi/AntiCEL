import SwiftUI

struct VehicleHeaderView: View {

    @Bindable var vehicle: Vehicle
    @Bindable private var obd = OBDSessionController.shared

    @State private var showingUpdateMileage = false

    private var hasPhoto: Bool {
        vehicle.photoFileName != nil
    }

    private var headerHeight: CGFloat {
        let extra: CGFloat = displayedFuelPercent != nil ? 126 : 0
        return (hasPhoto ? 300 : 210) + extra
    }

    var body: some View {
        Group {
            if hasPhoto {
                photoHeader
            } else {
                compactHeader
            }
        }
        .sheet(isPresented: $showingUpdateMileage) {
            UpdateMileageView(vehicle: vehicle)
        }
    }

    private var photoHeader: some View {
        GeometryReader { geo in
            let minY = geo.frame(in: .scrollView(axis: .vertical)).minY
            let stretch = max(minY, 0)

            ZStack(alignment: .bottom) {
                Color.clear
                    .overlay {
                        StoredPhotoView(ref: vehicle.photoFileName, framing: vehicle.photoFraming) {
                            Color.black.opacity(0.25)
                        }
                    }
                    .overlay {
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.18),
                                Color.black.opacity(0.05),
                                Color.black.opacity(0.58)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                    .frame(width: geo.size.width, height: headerHeight + stretch)
                    .clipped()
                    .offset(y: -stretch)

                identityOverlay(onPhoto: true)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 18)
            }
        }
        .frame(height: headerHeight)
    }

    private var compactHeader: some View {
        VStack(spacing: 14) {
            VehiclePhotoIcon(
                photoFileName: nil,
                width: 112,
                height: 74,
                symbolSize: 56,
                cornerRadius: 14
            )
            .shadow(color: Color.accentColor.opacity(0.35), radius: 12, y: 4)
            .padding(.top, 8)

            identityOverlay(onPhoto: false)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private func identityOverlay(onPhoto: Bool) -> some View {
        VStack(spacing: onPhoto ? 10 : 8) {
            Text("\(String(vehicle.year))  \(vehicle.make.uppercased())  \(vehicle.model.uppercased())")
                .font(.appBadge)
                .tracking(1.8)
                .foregroundStyle(onPhoto ? Color.white.opacity(0.82) : Color.secondary)

            if !vehicle.nickname.isEmpty {
                Text(vehicle.nickname)
                    .font(.title2.weight(.semibold).width(.condensed))
                    .foregroundStyle(onPhoto ? Color.white : Color.primary)
                    .shadow(color: onPhoto ? .black.opacity(0.45) : .clear, radius: 6, y: 1)
            }

            Button {
                showingUpdateMileage = true
            } label: {
                OdometerView(mileage: vehicle.currentMileage)
                    .contentShape(Rectangle())
            }
            .buttonStyle(OdometerTapStyle())
            .accessibilityHint("Updates current mileage")

            if let fuel = displayedFuelPercent {
                FuelGaugeView(percent: fuel)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var displayedFuelPercent: Double? {
        if obd.isConnected(to: vehicle.id), let live = obd.fuelPercent {
            return live
        }
        return OBDStore.pairedAdapter(on: vehicle)?.lastFuelPercent
    }
}

private struct OdometerTapStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        OdometerTapChrome(isPressed: configuration.isPressed) {
            configuration.label
        }
    }
}

private struct OdometerTapChrome<Label: View>: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let isPressed: Bool
    @ViewBuilder var label: () -> Label

    var body: some View {
        label()
            .opacity(isPressed ? 0.7 : 1)
            .scaleEffect((isPressed && !reduceMotion) ? 0.97 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: isPressed)
    }
}
