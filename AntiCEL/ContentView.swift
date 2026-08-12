import SwiftUI

struct ContentView: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var doorOpen = false
    @State private var showDoor = true

    var body: some View {
        ZStack {
            GarageView()

            if showDoor && !reduceMotion {
                GarageDoorOverlay(isOpen: doorOpen)
            }
        }
        .appTheme()
        .onAppear {
            playDoorIfNeeded()
        }
    }

    private func playDoorIfNeeded() {
        if reduceMotion {
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
