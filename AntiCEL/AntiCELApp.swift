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
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(OBDSessionController.shared)
        }
        .modelContainer(sharedModelContainer)
    }
}
