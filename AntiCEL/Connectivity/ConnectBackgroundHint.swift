import UIKit
import UserNotifications

enum ConnectBackgroundHint {
    static let identifier = "anticel.connect.background-hint"

    private static var cancelWork: DispatchWorkItem?
    private static var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    static func didBecomeActive() {
        cancel()
    }

    static func didEnterBackground() {
        arm()
    }

    static func scheduleImmediate() {
        guard shouldHint else { return }
        cancelWork?.cancel()
        endBackgroundTask()
        addNotification(trigger: nil)
    }

    private static func arm() {
        cancel()
        guard shouldHint else { return }

        addNotification(
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        )

        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "ConnectBackgroundHint") {
            endBackgroundTask()
        }

        let work = DispatchWorkItem {
            cancelPending()
            endBackgroundTask()
        }
        cancelWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: work)
    }

    private static func cancel() {
        cancelWork?.cancel()
        cancelWork = nil
        cancelPending()
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
        endBackgroundTask()
    }

    private static func cancelPending() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    private static func addNotification(trigger: UNNotificationTrigger?) {
        let content = UNMutableNotificationContent()
        content.title = "Keep AntiCEL in the background"
        content.body = "Leave AntiCEL in the background so Connect can auto-reconnect to your adapter each drive. Swiping it away stops that until you open the app again."
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private static var shouldHint: Bool {
        #if DEBUG
        if OBDSessionController.shared.isUsingMockAdapter { return false }
        #endif
        guard ConnectEntitlementStore.shared.canAttemptConnection else { return false }
        return !OBDStore.allPairedAdapters().isEmpty
    }

    private static func endBackgroundTask() {
        guard backgroundTask != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }
}
