import SwiftUI

struct GarageBayCard: View {

    @Environment(\.appTheme) private var theme

    var vehicle: Vehicle?
    var isAddBay = false

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                ParkingStallShape()
                    .stroke(theme.stallPaint, style: StrokeStyle(lineWidth: 3, lineCap: .square, lineJoin: .miter))
                    .padding(10)

                if let vehicle {
                    vehicleContent(vehicle)
                } else {
                    emptyContent
                }
            }
            .frame(minHeight: 168)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(theme.panel.opacity(0.55))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(theme.edge, lineWidth: 1)
                }
                .shadow(color: theme.shadow, radius: 12, y: 6)
        }
    }

    private func vehicleContent(_ vehicle: Vehicle) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "car.side.fill")
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(Color.primary.opacity(0.88))
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

                Text("\(vehicle.currentMileage.formatted()) km")
                    .font(.appOdometer)
                    .foregroundStyle(Color.accentColor)
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
