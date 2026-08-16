import Foundation
import SwiftData
import UserNotifications

enum ReminderNotifications {
    static func refresh(vehicles: [Vehicle], settings: AppSettings) async {
        let center = UNUserNotificationCenter.current()
        await center.removePendingNotificationRequests(
            withIdentifiers: await pendingAntiCELIdentifiers(center)
        )

        guard settings.notifyServiceReminders || settings.notifyExpiringDocuments else {
            return
        }

        let status = await center.notificationSettings()
        guard status.authorizationStatus == .authorized || status.authorizationStatus == .provisional else {
            return
        }

        let lead = TimeInterval(settings.notificationLeadDays.rawValue * 24 * 60 * 60)
        var requests: [UNNotificationRequest] = []

        if settings.notifyServiceReminders {
            for vehicle in vehicles {
                for reminder in vehicle.serviceReminders where !reminder.isCompleted {
                    guard let dueDate = reminder.dueDate else { continue }
                    let fireDate = dueDate.addingTimeInterval(-lead)
                    guard fireDate > Date() else { continue }

                    let content = UNMutableNotificationContent()
                    content.title = "Service due soon"
                    content.body = "\(reminder.name) on \(displayName(for: vehicle)) is due \(dueDate.formatted(date: .abbreviated, time: .omitted))."
                    content.sound = .default

                    requests.append(
                        request(
                            id: "anticel.service.\(vehicle.id.uuidString).\(stableID(reminder.name, dueDate))",
                            content: content,
                            fireDate: fireDate
                        )
                    )
                }
            }
        }

        if settings.notifyExpiringDocuments {
            for vehicle in vehicles {
                for document in vehicle.documents {
                    guard let expiration = document.expirationDate else { continue }
                    let fireDate = expiration.addingTimeInterval(-lead)
                    guard fireDate > Date() else { continue }

                    let content = UNMutableNotificationContent()
                    content.title = "Document expiring soon"
                    content.body = "\(document.title) for \(displayName(for: vehicle)) expires \(expiration.formatted(date: .abbreviated, time: .omitted))."
                    content.sound = .default

                    requests.append(
                        request(
                            id: "anticel.document.\(document.id.uuidString)",
                            content: content,
                            fireDate: fireDate
                        )
                    )
                }
            }
        }

        for request in requests {
            try? await center.add(request)
        }
    }

    static func refresh(using context: ModelContext) {
        let vehicles = (try? context.fetch(FetchDescriptor<Vehicle>())) ?? []
        let settings = AppSettings.shared
        Task {
            await refresh(vehicles: vehicles, settings: settings)
        }
    }

    static func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let status = await center.notificationSettings().authorizationStatus

        switch status {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        @unknown default:
            return false
        }
    }

    private static func request(
        id: String,
        content: UNMutableNotificationContent,
        fireDate: Date
    ) -> UNNotificationRequest {
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        return UNNotificationRequest(identifier: id, content: content, trigger: trigger)
    }

    private static func pendingAntiCELIdentifiers(_ center: UNUserNotificationCenter) async -> [String] {
        let pending = await center.pendingNotificationRequests()
        return pending.map(\.identifier).filter { $0.hasPrefix("anticel.") }
    }

    private static func displayName(for vehicle: Vehicle) -> String {
        if !vehicle.nickname.isEmpty {
            return vehicle.nickname
        }
        return "\(vehicle.year) \(vehicle.make) \(vehicle.model)"
    }

    private static func stableID(_ name: String, _ date: Date) -> String {
        let stamp = Int(date.timeIntervalSince1970)
        let safeName = name.lowercased().replacingOccurrences(of: " ", with: "-")
        return "\(safeName).\(stamp)"
    }
}
