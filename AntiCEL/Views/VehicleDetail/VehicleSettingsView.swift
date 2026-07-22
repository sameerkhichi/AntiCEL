import SwiftUI

struct VehicleSettingsView: View {

    let vehicle: Vehicle

    var body: some View {

        Text("Settings Coming Soon")

    }

}

#Preview {
    VehicleSettingsView(
        vehicle: Vehicle(
            make: "Audi",
            model: "S4",
            year: 2022,
            currentMileage: 79500
        )
    )
}
