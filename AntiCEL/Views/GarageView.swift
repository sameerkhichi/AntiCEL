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
    @State private var showingConnectAccess = false
    @State private var vehiclePendingDelete: Vehicle?
    @State private var vehicleForMileageUpdate: Vehicle?
    @State private var vehicleToShare: Vehicle?
    @State private var orderedIDs: [UUID] = []
    @State private var bayFrames: [UUID: CGRect] = [:]
    @GestureState private var dragSession: GarageDragSession?
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

    private var draggedVehicle: Vehicle? {
        guard let dragSession else { return nil }
        return displayedVehicles.first(where: { $0.id == dragSession.id })
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
                            .background {
                                bayFrameProbe(for: GarageReorder.addBayID)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                        .coordinateSpace(name: GarageReorder.spaceName)
                        .animation(.snappy(duration: 0.22), value: orderedIDs)
                        .onPreferenceChange(BayFramePreferenceKey.self) { bayFrames = $0 }
                        .overlay {
                            dragPreview
                        }
                    }
                    .padding(.top, 8)
                }
                .scrollDisabled(dragSession != nil)
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
            .onChange(of: dragSession?.id) { oldValue, newValue in
                if oldValue == nil, newValue != nil {
                    AppHaptic.flashlight.play()
                }
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
    private var dragPreview: some View {
        if let dragSession, let vehicle = draggedVehicle {
            GarageBayCard(vehicle: vehicle)
                .frame(width: bayFrames[dragSession.id]?.width)
                .scaleEffect(1.04)
                .shadow(color: theme.shadow.opacity(0.6), radius: 18, y: 8)
                .position(dragSession.location)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private func garageBay(for vehicle: Vehicle) -> some View {
        ZStack(alignment: .topTrailing) {
            NavigationLink(destination: VehicleDetailView(vehicle: vehicle)) {
                GarageBayCard(vehicle: vehicle)
            }
            .buttonStyle(.plain)
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
            .accessibilityLabel("Update mileage")
        }
        .contentShape(Rectangle())
        .opacity(dragSession?.id == vehicle.id ? 0.35 : 1)
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
        .background {
            bayFrameProbe(for: vehicle.id)
        }
        .simultaneousGesture(reorderGesture(for: vehicle.id))
        .accessibilityHint("Touch and hold, then drag to reorder")
    }

    private func reorderGesture(for id: UUID) -> some Gesture {
        LongPressGesture(minimumDuration: 0.28)
            .sequenced(
                before: DragGesture(
                    minimumDistance: 2,
                    coordinateSpace: .named(GarageReorder.spaceName)
                )
            )
            .updating($dragSession) { value, state, _ in
                switch value {
                case .first(true):
                    if let frame = bayFrames[id] {
                        state = GarageDragSession(
                            id: id,
                            location: CGPoint(x: frame.midX, y: frame.midY)
                        )
                    } else {
                        state = GarageDragSession(id: id, location: .zero)
                    }
                case .second(true, let drag):
                    let location = drag?.location ?? state?.location ?? .zero
                    state = GarageDragSession(id: id, location: location)
                default:
                    break
                }
            }
            .onChanged { value in
                guard case .second(true, let drag) = value, let drag else { return }
                moveDraggedVehicle(id, to: drag.location)
            }
    }

    private func moveDraggedVehicle(_ draggingID: UUID, to location: CGPoint) {
        guard let targetID = targetBayID(at: location), targetID != draggingID else {
            return
        }

        guard let origin = orderedIDs.firstIndex(of: draggingID) else {
            return
        }

        if targetID == GarageReorder.addBayID {
            guard orderedIDs.last != draggingID else { return }
            withAnimation(.snappy(duration: 0.22)) {
                orderedIDs.move(
                    fromOffsets: IndexSet(integer: origin),
                    toOffset: orderedIDs.count
                )
            }
            return
        }

        guard let destination = orderedIDs.firstIndex(of: targetID), origin != destination else {
            return
        }

        withAnimation(.snappy(duration: 0.22)) {
            orderedIDs.move(
                fromOffsets: IndexSet(integer: origin),
                toOffset: destination > origin ? destination + 1 : destination
            )
        }
    }

    private func targetBayID(at location: CGPoint) -> UUID? {
        if let hit = bayFrames.first(where: { $0.value.insetBy(dx: -8, dy: -8).contains(location) }) {
            return hit.key
        }

        guard let closest = bayFrames.min(by: { lhs, rhs in
            hypot(lhs.value.midX - location.x, lhs.value.midY - location.y)
                < hypot(rhs.value.midX - location.x, rhs.value.midY - location.y)
        }) else {
            return nil
        }

        let distance = hypot(closest.value.midX - location.x, closest.value.midY - location.y)
        return distance < 140 ? closest.key : nil
    }

    private func bayFrameProbe(for id: UUID) -> some View {
        GeometryReader { geo in
            Color.clear.preference(
                key: BayFramePreferenceKey.self,
                value: [id: geo.frame(in: .named(GarageReorder.spaceName))]
            )
        }
    }

    private func syncGarageOrder() {
        guard dragSession == nil else { return }
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

private enum GarageReorder {
    static let spaceName = "garageGrid"
    static let addBayID = UUID(uuidString: "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF")!
}

private struct GarageDragSession: Equatable {
    var id: UUID
    var location: CGPoint
}

private struct BayFramePreferenceKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]

    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
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
