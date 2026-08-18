import SwiftUI
import SwiftData

struct GarageView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var theme
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.scenePhase) private var scenePhase
    @Query private var vehicles: [Vehicle]

    @State private var showingAddVehicle = false
    @State private var showingSettings = false
    @State private var vehiclePendingDelete: Vehicle?
    @State private var vehicleForMileageUpdate: Vehicle?
    @Binding var pendingMileageVehicleID: UUID?

    private var columns: [GridItem] {
        let count = sizeClass == .regular ? 2 : 1
        return Array(repeating: GridItem(.flexible(), spacing: 18), count: count)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topTrailing) {
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
                            ZStack(alignment: .topTrailing) {
                                NavigationLink(destination: VehicleDetailView(vehicle: vehicle)) {
                                    GarageBayCard(vehicle: vehicle)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button("Remove from Garage", role: .destructive) {
                                        vehiclePendingDelete = vehicle
                                    }
                                }

                                DashButton(kind: .compact) {
                                    vehicleForMileageUpdate = vehicle
                                } label: {
                                    Image(systemName: "gauge")
                                }
                                .padding(10)
                                .accessibilityLabel("Update mileage")
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

            DashButton(kind: .compact) {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
            }
            .padding(.top, 12)
            .padding(.trailing, 20)
            .accessibilityLabel("Settings")
            }
            .appCanvas()
            .navigationTitle("Garage")
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingAddVehicle) {
                AddVehicleView()
            }
            .sheet(isPresented: $showingSettings) {
                AppSettingsView()
            }
            .sheet(item: $vehicleForMileageUpdate) { vehicle in
                UpdateMileageView(vehicle: vehicle)
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
                        PhotoStore.deleteAll(for: vehiclePendingDelete)
                        modelContext.delete(vehiclePendingDelete)
                        WidgetReloader.reload()
                    }
                    vehiclePendingDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    vehiclePendingDelete = nil
                }
            }
            .onChange(of: pendingMileageVehicleID) {
                openPendingMileageUpdate()
            }
            .onChange(of: vehicles.count) {
                openPendingMileageUpdate()
            }
            .onAppear {
                openPendingMileageUpdate()
                ReminderNotifications.refresh(using: modelContext)
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    ReminderNotifications.refresh(using: modelContext)
                }
            }
        }
    }

    private func openPendingMileageUpdate() {
        guard let pendingMileageVehicleID else {
            return
        }

        if let vehicle = vehicles.first(where: { $0.id == pendingMileageVehicleID }) {
            vehicleForMileageUpdate = vehicle
            self.pendingMileageVehicleID = nil
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
        let intensity: Double = vehicles.isEmpty ? 0.32 : 1.0

        return HStack(spacing: 10) {
            ForEach(0..<5, id: \.self) { _ in
                HexShopLight(intensity: intensity)
            }
        }
        .padding(.top, 10)
    }
}

private struct HexShopLight: View {

    @Environment(\.appTheme) private var theme

    var intensity: Double

    var body: some View {
        ZStack {
            HexagonShape()
                .fill(theme.bayGlow.opacity(intensity * 0.4))
                .blur(radius: 7)
                .scaleEffect(1.4)

            HexagonShape()
                .fill(Color.black.opacity(theme.isDark ? 0.88 : 0.45))

            HexagonShape()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(intensity),
                            theme.bayGlow.opacity(intensity * 0.9),
                            theme.bayGlow.opacity(intensity * 0.25)
                        ],
                        center: .center,
                        startRadius: 1,
                        endRadius: 20
                    )
                )
                .padding(3.5)

            HexagonShape()
                .stroke(Color.white.opacity(theme.isDark ? 0.18 : 0.35), lineWidth: 0.8)
        }
        .frame(width: 38, height: 42)
        .shadow(color: theme.bayGlow.opacity(intensity * 0.55), radius: 8, y: 5)
        .opacity(0.35 + intensity * 0.65)
    }
}

private struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let inset = rect.insetBy(dx: 1, dy: 1)
        let w = inset.width
        let h = inset.height
        let x = inset.minX
        let y = inset.minY

        var path = Path()
        path.move(to: CGPoint(x: x + w / 2, y: y))
        path.addLine(to: CGPoint(x: x + w, y: y + h * 0.25))
        path.addLine(to: CGPoint(x: x + w, y: y + h * 0.75))
        path.addLine(to: CGPoint(x: x + w / 2, y: y + h))
        path.addLine(to: CGPoint(x: x, y: y + h * 0.75))
        path.addLine(to: CGPoint(x: x, y: y + h * 0.25))
        path.closeSubpath()
        return path
    }
}

#Preview {
    GarageView(pendingMileageVehicleID: .constant(nil))
        .appTheme()
}
