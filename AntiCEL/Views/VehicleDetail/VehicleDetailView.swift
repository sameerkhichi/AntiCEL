import SwiftUI

struct VehicleDetailView: View {

    //uses the enum to track what section we are looking at.
    @State private var selectedSection: VehicleDetailSection = .overview
    
    let vehicle: Vehicle

    private var navigationTitleText: String {
        if !vehicle.nickname.isEmpty {
            return vehicle.nickname
        }
        return "\(vehicle.make) \(vehicle.model)"
    }

    var body: some View {

        VStack(spacing: 0) {

            Group {

                switch selectedSection {

                case .overview:
                    ScrollView {
                        VStack(spacing: 0) {
                            VehicleHeaderView(vehicle: vehicle)
                            VehicleOverviewView(vehicle: vehicle)
                        }
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            VehicleSectionTabBar(selection: $selectedSection)

        }
        .navigationTitle(navigationTitleText)
        .navigationBarTitleDisplayMode(.inline)

    }
}

//test preview.
#Preview {
    NavigationStack {
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
}
