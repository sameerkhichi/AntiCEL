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

            //for the dynamic cards on selection
            //This will call on the individual views for the corresponding section that is picked
            switch selectedSection {

            case .overview:
                VehicleOverviewView(vehicle: vehicle)

            case .history:
                VehicleHistoryView(vehicle: vehicle)

            case .documents:
                VehicleDocumentsView(vehicle: vehicle)

            case .settings:
                VehicleSettingsView(vehicle: vehicle)

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
