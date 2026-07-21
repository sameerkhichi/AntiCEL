import SwiftUI

struct VehicleDetailView: View {

    //uses the enum to track what section we are looking at.
    @State private var selectedSection: VehicleDetailSection = .overview
    
    let vehicle: Vehicle

    var body: some View {

        ScrollView {

            VehicleHeaderView(vehicle: vehicle)

            //this is a picker so the user can select different tabs on the vehicle details page.
            Picker("", selection: $selectedSection) {
                ForEach(VehicleDetailSection.allCases, id: \.self) {
                    Text($0.rawValue)
                        .tag($0)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            //for the dynamic text
            switch selectedSection {

            case .overview:
                Text("Overview")

            case .history:
                Text("History")

            case .documents:
                Text("Documents")

            case .settings:
                Text("Settings")

            }

        }
        .navigationTitle(vehicle.make)
        .navigationBarTitleDisplayMode(.inline)

    }
}

//test preview.
#Preview {
    VehicleDetailView(
        vehicle: Vehicle(
            make: "Audi",
            model: "S4",
            year: 2022,
            nickname: "Batmobile",
            currentMileage: 79500
        )
    )
}
