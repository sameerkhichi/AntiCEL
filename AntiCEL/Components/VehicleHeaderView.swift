import SwiftUI

struct VehicleHeaderView: View {

    @Bindable var vehicle: Vehicle

    @State private var showingUpdateMileage = false

    var body: some View {
        VStack(spacing: 14) {
            VehiclePhotoIcon(
                photoFileName: vehicle.photoFileName,
                width: 112,
                height: 74,
                symbolSize: 56,
                cornerRadius: 14
            )
            .shadow(color: Color.accentColor.opacity(0.35), radius: 12, y: 4)
            .padding(.top, 8)

            Text("\(String(vehicle.year))  \(vehicle.make.uppercased())  \(vehicle.model.uppercased())")
                .font(.appBadge)
                .tracking(1.8)
                .foregroundStyle(.secondary)

            if !vehicle.nickname.isEmpty {
                Text(vehicle.nickname)
                    .font(.title2.weight(.semibold).width(.condensed))
            }

            Button {
                showingUpdateMileage = true
            } label: {
                OdometerView(mileage: vehicle.currentMileage)
                    .contentShape(Rectangle())
            }
            .buttonStyle(OdometerTapStyle())
            .accessibilityHint("Updates current mileage")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .sheet(isPresented: $showingUpdateMileage) {
            UpdateMileageView(vehicle: vehicle)
        }
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
