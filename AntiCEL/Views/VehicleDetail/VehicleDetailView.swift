import SwiftUI

struct VehicleDetailView: View {

    @Environment(\.appTheme) private var theme
    @Environment(OBDSessionController.self) private var obd
    @Environment(AppSettings.self) private var settings
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

                case .connect:
                    ScrollView {
                        VehicleConnectView(vehicle: vehicle)
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
                ToolbarItemGroup(placement: .topBarTrailing) {
                    NavigationLink {
                        ScrollView {
                            VehicleSettingsView(vehicle: vehicle)
                        }
                        .appCanvas()
                        .navigationTitle("Settings")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbarBackground(theme.canvas, for: .navigationBar)
                        .toolbarBackground(.visible, for: .navigationBar)
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    .accessibilityLabel("Vehicle Settings")

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
        .alert(
            "Update mileage?",
            isPresented: Binding(
                get: { obd.mileageJump?.vehicleID == vehicle.id },
                set: { if !$0 { obd.declineMileageJump() } }
            )
        ) {
            Button("Update") {
                obd.confirmMileageJump(on: vehicle)
            }
            Button("Keep Current", role: .cancel) {
                obd.declineMileageJump()
            }
        } message: {
            if let jump = obd.mileageJump, jump.vehicleID == vehicle.id {
                Text(
                    "The \(jump.source) is \(settings.formattedMileage(jump.proposedKm)). Current mileage is \(settings.formattedMileage(jump.currentKm)). Large jumps are confirmed before they are saved."
                )
            }
        }
        .onChange(of: obd.appliedMileageKm) { _, newValue in
            guard let newValue, obd.connectedVehicleID == vehicle.id else { return }
            if newValue > vehicle.currentMileage {
                vehicle.currentMileage = newValue
                vehicle.updatedAt = Date()
            }
        }
        .onAppear {
            if OBDStore.pairedAdapter(on: vehicle) != nil, obd.connectionState == .disconnected {
                obd.connectPairedAdapter(for: vehicle)
            }
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
    .environment(OBDSessionController.shared)
}
