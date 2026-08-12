import SwiftUI

struct VehicleDetailView: View {

    //uses the enum to track what section we are looking at.
    @State private var selectedSection: VehicleDetailSection = .overview
    
    let vehicle: Vehicle

    var body: some View {

        VStack(spacing: 0) {

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
            .padding(.bottom, 8)

            //history owns its own scrolling / 3D gestures; other tabs use a ScrollView
            switch selectedSection {

            case .overview:
                ScrollView {
                    VehicleOverviewView(vehicle: vehicle)
                }

            case .history:
                VehicleHistoryView(vehicle: vehicle)

            case .documents:
                ScrollView {
                    VehicleDocumentsView(vehicle: vehicle)
                }

            case .settings:
                ScrollView {
                    VehicleSettingsView(vehicle: vehicle)
                }

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
