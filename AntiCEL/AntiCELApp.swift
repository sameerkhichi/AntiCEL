import SwiftUI
import SwiftData

@main
struct AntiCELApp: App {
    var sharedModelContainer: ModelContainer = {
        //this is where you register different models that you create.
        let schema = Schema([
            Vehicle.self,
            ServiceReminder.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
