import SwiftUI

struct VehicleDocumentsView: View {

    let vehicle: Vehicle

    var body: some View {

        Text("Documents Coming Soon")

    }

}

#Preview {
    VehicleDocumentsView(
        vehicle: Vehicle(
            make: "Audi",
            model: "S4",
            year: 2022,
            currentMileage: 79500
        )
    )
}
