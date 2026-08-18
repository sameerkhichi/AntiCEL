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
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
