//this is basically a template file so that we can reuse this type of header elsewhere for widgets and other.
import SwiftUI

struct VehicleHeaderView: View {

    let vehicle: Vehicle

    var body: some View {

        VStack(spacing: 12) {

            Image(systemName: "car.fill")
                .font(.system(size: 50))
                .foregroundStyle(.white)
                .frame(width: 90, height: 90)
                .background(.blue)
                .clipShape(Circle())

            Text("\(vehicle.year) \(vehicle.make) \(vehicle.model)")
                .font(.title2)
                .fontWeight(.bold)

            if !vehicle.nickname.isEmpty {
                Text(vehicle.nickname)
                    .foregroundStyle(.secondary)
            }

            Text("\(vehicle.currentMileage.formatted()) km")
                .font(.headline)

        }
        .frame(maxWidth: .infinity)
        .padding(.vertical)

    }
}
