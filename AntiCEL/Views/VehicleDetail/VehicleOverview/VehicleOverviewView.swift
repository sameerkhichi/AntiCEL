import SwiftUI

struct VehicleOverviewView: View {

    let vehicle: Vehicle

    var body: some View {

        VStack(spacing: 20) {

            QuickInfoCard(vehicle: vehicle)

            ServiceReminderCard(vehicle: vehicle)

            // VehicleNotesCard()

        }
        .padding(.vertical)

    }
}

#Preview {
    VehicleOverviewView(
        vehicle: Vehicle(
            make: "Audi",
            model: "S4",
            year: 2022,
            nickname: "Batmobile",
            vin: "WAUENAF49NA123456",
            currentMileage: 79500
        )
    )
}
