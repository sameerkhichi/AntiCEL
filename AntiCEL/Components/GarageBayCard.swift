import SwiftUI

struct GarageBayCard: View {

    @Environment(\.appTheme) private var theme

    var vehicle: Vehicle?
    var isAddBay = false

    private var hasPhoto: Bool {
        vehicle?.photoFileName != nil
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                ParkingStallShape()
                    .stroke(stallStroke, style: StrokeStyle(lineWidth: 3, lineCap: .square, lineJoin: .miter))
                    .padding(10)

                if let vehicle {
                    if !hasPhoto {
                        vehicleContent(vehicle)
                    }
                } else {
                    emptyContent
                }
            }
            .frame(minHeight: hasPhoto ? 210 : 168)

            if let vehicle, hasPhoto {
                photoOverlay(vehicle)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .background {
            cardBackground
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(hasPhoto ? Color.black : theme.panel.opacity(0.55))
            .overlay {
                if let vehicle, hasPhoto {
                    StoredPhotoView(ref: vehicle.photoFileName) {
                        theme.panel.opacity(0.55)
                    }
                    .overlay {
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.12),
                                Color.black.opacity(0.08),
                                Color.black.opacity(0.62)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(theme.edge, lineWidth: 1)
            }
            .shadow(color: theme.shadow, radius: 12, y: 6)
    }

    private var stallStroke: Color {
        hasPhoto ? Color.white.opacity(0.72) : theme.stallPaint
    }

    private func photoOverlay(_ vehicle: Vehicle) -> some View {
        VStack(spacing: 6) {
            Text("\(String(vehicle.year))  \(vehicle.make.uppercased())  \(vehicle.model.uppercased())")
                .font(.appBadge)
                .tracking(1.4)
                .foregroundStyle(Color.white.opacity(0.9))

            if !vehicle.nickname.isEmpty {
                Text(vehicle.nickname)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.white)
                    .shadow(color: .black.opacity(0.4), radius: 4, y: 1)
            }

            OdometerView(mileage: vehicle.currentMileage, compact: true)
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity)
    }

    private func vehicleContent(_ vehicle: Vehicle) -> some View {
        VStack(spacing: 10) {
            VehiclePhotoIcon(
                photoFileName: nil,
                width: 86,
                height: 56,
                symbolSize: 44
            )
            .shadow(color: Color.accentColor.opacity(0.25), radius: 8, y: 2)

            VStack(spacing: 2) {
                Text("\(String(vehicle.year))  \(vehicle.make.uppercased())  \(vehicle.model.uppercased())")
                    .font(.appBadge)
                    .tracking(1.4)
                    .foregroundStyle(.primary)

                if !vehicle.nickname.isEmpty {
                    Text(vehicle.nickname)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                OdometerView(mileage: vehicle.currentMileage, compact: true)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var emptyContent: some View {
        VStack(spacing: 10) {
            Image(systemName: isAddBay ? "plus" : "car.side")
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(Color.accentColor.opacity(0.85))

            Text(isAddBay ? "Park a vehicle" : "Empty bay")
                .font(.appBadge)
                .tracking(1.6)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ParkingStallShape: Shape {
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
