import SwiftUI
import SwiftData
import UIKit

final class AntiCELAppDelegate: NSObject, UIApplicationDelegate {
    func applicationWillTerminate(_ application: UIApplication) {
        ConnectBackgroundHint.scheduleImmediate()
    }
}

@main
struct AntiCELApp: App {
    @UIApplicationDelegateAdaptor(AntiCELAppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase

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
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                ConnectBackgroundHint.didBecomeActive()
            case .background:
                ConnectBackgroundHint.didEnterBackground()
            case .inactive:
                break
            @unknown default:
                break
            }
        }
    }
}
