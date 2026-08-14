import SwiftUI

struct ContentView: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var doorOpen = false
    @State private var showDoor = true
    @State private var pendingMileageVehicleID: UUID?

    var body: some View {
        ZStack {
            GarageView(pendingMileageVehicleID: $pendingMileageVehicleID)

            if showDoor && !reduceMotion {
                GarageDoorOverlay(isOpen: doorOpen)
            }
        }
        .appTheme()
        .onAppear {
            playDoorIfNeeded()
        }
        .onOpenURL { url in
            handleOpenURL(url)
        }
    }

    private func handleOpenURL(_ url: URL) {
        guard let vehicleID = AntiCELDeepLink.vehicleIDForMileage(from: url) else {
            return
        }

        pendingMileageVehicleID = vehicleID
        showDoor = false
    }

    private func playDoorIfNeeded() {
        if reduceMotion || pendingMileageVehicleID != nil {
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
