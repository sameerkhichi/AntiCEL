import SwiftUI

struct VehicleHistoryView: View {

    let vehicle: Vehicle

    var body: some View {

        Text("History Tab Not Yet Implemented")

    }

}

#Preview {
    VehicleHistoryView(
        vehicle: Vehicle(
            make: "Audi",
            model: "S4",
            year: 2022,
            currentMileage: 79500
        )
    )
}
