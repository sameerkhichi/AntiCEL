import SwiftUI

struct VehicleHeaderView: View {

    let vehicle: Vehicle

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "car.side.fill")
                .font(.system(size: 56, weight: .regular))
                .foregroundStyle(Color.primary.opacity(0.92))
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

            Text("\(vehicle.currentMileage.formatted()) km")
                .font(.appOdometer)
                .foregroundStyle(Color.accentColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}
