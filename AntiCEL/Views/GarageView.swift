import SwiftUI
import SwiftData

struct GarageView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var theme
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Query private var vehicles: [Vehicle]

    @State private var showingAddVehicle = false
    @State private var vehiclePendingDelete: Vehicle?

    private var columns: [GridItem] {
        let count = sizeClass == .regular ? 2 : 1
        return Array(repeating: GridItem(.flexible(), spacing: 18), count: count)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    overheadLights
                    wordmark

                    if vehicles.isEmpty {
                        Text("Park your first vehicle")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    LazyVGrid(columns: columns, spacing: 18) {
                        ForEach(vehicles) { vehicle in
                            NavigationLink(destination: VehicleDetailView(vehicle: vehicle)) {
                                GarageBayCard(vehicle: vehicle)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("Remove from Garage", role: .destructive) {
                                    vehiclePendingDelete = vehicle
                                }
                            }
                        }

                        Button {
                            showingAddVehicle = true
                        } label: {
                            GarageBayCard(isAddBay: true)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
                .padding(.top, 8)
            }
            .appCanvas()
            .navigationTitle("Garage")
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingAddVehicle) {
                AddVehicleView()
            }
            .confirmationDialog(
                "Remove this vehicle from the garage?",
                isPresented: Binding(
                    get: { vehiclePendingDelete != nil },
                    set: { if !$0 { vehiclePendingDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Remove", role: .destructive) {
                    if let vehiclePendingDelete {
                        modelContext.delete(vehiclePendingDelete)
                    }
                    vehiclePendingDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    vehiclePendingDelete = nil
                }
            }
        }
    }

    private var wordmark: some View {
        Text("ANTICEL")
            .font(.appWordmark)
            .tracking(8)
            .foregroundStyle(theme.wordmark)
            .padding(.top, 4)
    }

    private var overheadLights: some View {
        let intensity: Double = vehicles.isEmpty ? 0.35 : 0.9

        return HStack(spacing: 22) {
            ForEach(0..<5, id: \.self) { _ in
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                theme.bayGlow.opacity(intensity),
                                Color.accentColor.opacity(intensity * 0.35),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 28
                        )
                    )
                    .frame(width: 54, height: 14)
                    .blur(radius: 1.5)
                    .shadow(color: Color.accentColor.opacity(intensity * 0.45), radius: 10, y: 6)
            }
        }
        .padding(.top, 12)
        .opacity(intensity)
    }
}

#Preview {
    GarageView()
        .appTheme()
}
