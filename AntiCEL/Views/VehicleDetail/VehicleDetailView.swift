import SwiftUI

struct VehicleDetailView: View {

    @Environment(\.appTheme) private var theme
    @State private var selectedSection: VehicleDetailSection = .overview
    @State private var showingShare = false

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

                case .album:
                    ScrollView {
                        VehicleAlbumView(vehicle: vehicle)
                    }

                case .settings:
                    ScrollView {
                        VehicleSettingsView(vehicle: vehicle)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            VehicleSectionTabBar(selection: $selectedSection)
        }
        .appCanvas()
        .navigationTitle(navigationTitleText)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.canvas, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            if selectedSection == .overview {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingShare = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Share Vehicle")
                }
            }
        }
        .sheet(isPresented: $showingShare) {
            ShareVehicleSheet(vehicle: vehicle)
        }
    }
}

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
    .appTheme()
}
