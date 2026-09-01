import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct GarageView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var theme
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.scenePhase) private var scenePhase
    @Query private var vehicles: [Vehicle]

    @State private var showingAddVehicle = false
    @State private var showingSettings = false
    @State private var showingConnectAccess = false
    @State private var vehiclePendingDelete: Vehicle?
    @State private var vehicleForMileageUpdate: Vehicle?
    @State private var vehicleToShare: Vehicle?
    @State private var orderedIDs: [UUID] = []
    @State private var draggingID: UUID?
    @Binding var pendingMileageVehicleID: UUID?

    private var columns: [GridItem] {
        let count = sizeClass == .regular ? 2 : 1
        return Array(repeating: GridItem(.flexible(), spacing: 18), count: count)
    }

    private var displayedVehicles: [Vehicle] {
        let byID = Dictionary(uniqueKeysWithValues: vehicles.map { ($0.id, $0) })
        var seen = Set<UUID>()
        var result: [Vehicle] = []

        for id in orderedIDs {
            if let vehicle = byID[id] {
                result.append(vehicle)
                seen.insert(id)
            }
        }

        let extras = vehicles
            .filter { !seen.contains($0.id) }
            .sorted(by: Vehicle.garageSort)

        return result + extras
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
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
                        ForEach(displayedVehicles) { vehicle in
                            garageBay(for: vehicle)
                        }

                        Button {
                            AppHaptic.button.play()
                            showingAddVehicle = true
                        } label: {
                            GarageBayCard(isAddBay: true)
                        }
                        .buttonStyle(.plain)
                        .onDrop(
                            of: [UTType.plainText],
                            delegate: GarageReorderDropDelegate(
                                target: .end,
                                orderedIDs: $orderedIDs,
                                draggingID: $draggingID
                            )
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                    .animation(.snappy(duration: 0.22), value: orderedIDs)
                }
                .padding(.top, 8)
                .onDrop(
                    of: [UTType.plainText],
                    delegate: GarageReorderDropDelegate(
                        target: .commit,
                        orderedIDs: $orderedIDs,
                        draggingID: $draggingID
                    )
                )
            }
            }
            .overlay(alignment: .topLeading) {
                DashButton(kind: .compact) {
                    showingConnectAccess = true
                } label: {
                    Image(systemName: "dot.radiowaves.left.and.right")
                }
                .padding(.top, 12)
                .padding(.leading, 20)
                .accessibilityLabel("Connect access")
            }
            .overlay(alignment: .topTrailing) {
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
            .environment(OBDSessionController.shared)
            .environment(ConnectEntitlementStore.shared)
            .navigationTitle("Garage")
            .toolbar(.hidden, for: .navigationBar)
            .keyboardDismissToolbar()
            .sheet(isPresented: $showingAddVehicle) {
                AddVehicleView()
            }
            .sheet(isPresented: $showingSettings) {
                AppSettingsView()
            }
            .sheet(isPresented: $showingConnectAccess) {
                ConnectAccessView(origin: .garage)
                    .environment(ConnectEntitlementStore.shared)
            }
            .sheet(item: $vehicleForMileageUpdate) { vehicle in
                UpdateMileageView(vehicle: vehicle)
            }
            .sheet(isPresented: Binding(
                get: { vehicleToShare != nil },
                set: { if !$0 { vehicleToShare = nil } }
            )) {
                if let vehicleToShare {
                    ShareVehicleSheet(vehicle: vehicleToShare)
                }
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
                syncGarageOrder()
            }
            .onChange(of: draggingID) { oldValue, newValue in
                if oldValue != nil, newValue == nil {
                    persistGarageOrder()
                }
            }
            .onAppear {
                syncGarageOrder()
                openPendingMileageUpdate()
                ReminderNotifications.refresh(using: modelContext)
                OBDSessionController.shared.isForeground = true
                ConnectEntitlementStore.shared.expireIfNeeded()
                OBDSessionController.shared.reconnectKnownAdapters()
            }
            .onChange(of: scenePhase) { _, phase in
                OBDSessionController.shared.isForeground = phase == .active
                if phase == .active {
                    ReminderNotifications.refresh(using: modelContext)
                    ConnectEntitlementStore.shared.expireIfNeeded()
                    OBDSessionController.shared.reconnectKnownAdapters()
                }
            }
        }
    }

    @ViewBuilder
    private func garageBay(for vehicle: Vehicle) -> some View {
        ZStack(alignment: .topTrailing) {
            NavigationLink(destination: VehicleDetailView(vehicle: vehicle)) {
                GarageBayCard(vehicle: vehicle)
            }
            .buttonStyle(.plain)
            .allowsHitTesting(draggingID == nil)
            .simultaneousGesture(
                TapGesture().onEnded {
                    AppHaptic.flashlight.play()
                }
            )

            DashButton(kind: .compact) {
                vehicleForMileageUpdate = vehicle
            } label: {
                Image(systemName: "gauge")
            }
            .padding(10)
            .allowsHitTesting(draggingID == nil)
            .accessibilityLabel("Update mileage")
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                vehicleToShare = vehicle
            } label: {
                Label("Share Vehicle", systemImage: "square.and.arrow.up")
            }
            Button("Remove from Garage", role: .destructive) {
                vehiclePendingDelete = vehicle
            }
        }
        .opacity(draggingID == vehicle.id ? 0.4 : 1)
        .onDrag {
            draggingID = vehicle.id
            AppHaptic.flashlight.play()
            return NSItemProvider(object: vehicle.id.uuidString as NSString)
        } preview: {
            GarageBayCard(vehicle: vehicle)
                .frame(width: 260)
                .appTheme()
        }
        .onDrop(
            of: [UTType.plainText],
            delegate: GarageReorderDropDelegate(
                target: .vehicle(vehicle.id),
                orderedIDs: $orderedIDs,
                draggingID: $draggingID
            )
        )
        .accessibilityHint("Touch and hold, then drag to reorder")
    }

    private func syncGarageOrder() {
        guard draggingID == nil else { return }
        orderedIDs = Vehicle.garageOrdered(vehicles).map(\.id)
    }

    private func persistGarageOrder() {
        Vehicle.assignGarageOrder(displayedVehicles)
        syncGarageOrder()
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

private struct GarageReorderDropDelegate: DropDelegate {

    enum Target {
        case vehicle(UUID)
        case end
        case commit
    }

    let target: Target
    @Binding var orderedIDs: [UUID]
    @Binding var draggingID: UUID?

    func dropEntered(info: DropInfo) {
        guard let draggingID else { return }

        let destination: Int
        switch target {
        case .vehicle(let id):
            guard draggingID != id, let index = orderedIDs.firstIndex(of: id) else {
                return
            }
            destination = index
        case .end:
            guard orderedIDs.last != draggingID else { return }
            destination = max(orderedIDs.count - 1, 0)
        case .commit:
            return
        }

        guard let origin = orderedIDs.firstIndex(of: draggingID), origin != destination else {
            return
        }

        withAnimation(.snappy(duration: 0.22)) {
            orderedIDs.move(
                fromOffsets: IndexSet(integer: origin),
                toOffset: destination > origin ? destination + 1 : destination
            )
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggingID = nil
        return true
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
        .environment(ConnectEntitlementStore.shared)
}
