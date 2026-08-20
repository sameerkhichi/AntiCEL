import SwiftUI

struct ContentView: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var doorOpen = false
    @State private var showDoor = true
    @State private var pendingMileageVehicleID: UUID?
    @State private var pendingImport: PendingVehicleImport?
    @State private var importFileToDelete: URL?

    var body: some View {
        ZStack {
            GarageView(pendingMileageVehicleID: $pendingMileageVehicleID)

            if showDoor && !reduceMotion {
                GarageDoorOverlay(isOpen: doorOpen)
            }
        }
        .appTheme()
        .environment(OBDSessionController.shared)
        .onAppear {
            playDoorIfNeeded()
        }
        .onOpenURL { url in
            handleOpenURL(url)
        }
        .sheet(item: $pendingImport, onDismiss: deleteImportFileIfNeeded) { item in
            ImportVehicleSheet(packageURL: item.url)
        }
    }

    private func handleOpenURL(_ url: URL) {
        if VehicleShareImporter.isVehiclePackage(url) {
            if let local = try? VehicleShareImporter.copyToTemporaryFile(url) {
                importFileToDelete = local
                pendingImport = PendingVehicleImport(url: local)
            } else {
                importFileToDelete = nil
                pendingImport = PendingVehicleImport(url: url, deleteOnDismiss: false)
            }
            showDoor = false
            return
        }

        guard let vehicleID = AntiCELDeepLink.vehicleIDForMileage(from: url) else {
            return
        }

        pendingMileageVehicleID = vehicleID
        showDoor = false
    }

    private func deleteImportFileIfNeeded() {
        if let importFileToDelete {
            try? FileManager.default.removeItem(at: importFileToDelete)
        }
        importFileToDelete = nil
    }

    private func playDoorIfNeeded() {
        if reduceMotion || pendingMileageVehicleID != nil || pendingImport != nil {
            showDoor = false
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.easeInOut(duration: 1.4)) {
                doorOpen = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {
            showDoor = false
        }
    }
}

#Preview {
    ContentView()
}
