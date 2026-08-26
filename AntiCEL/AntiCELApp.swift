import SwiftUI
import SwiftData

@main
struct AntiCELApp: App {
    var sharedModelContainer: ModelContainer = {
        do {
            return try SharedModelContainer.make()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        ReminderNotifications.configure()
        OBDSessionController.shared.modelContainer = sharedModelContainer
        ConnectEntitlementStore.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(OBDSessionController.shared)
                .environment(ConnectEntitlementStore.shared)
        }
        .modelContainer(sharedModelContainer)
    }
}
