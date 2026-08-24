import Foundation
import SwiftData
import UserNotifications

enum ReminderNotifications {
    private static let presentationDelegate = NotificationPresentationDelegate()
    private static let scheduler = Scheduler()

    static func configure() {
        UNUserNotificationCenter.current().delegate = presentationDelegate
    }

    static func refresh(vehicles: [Vehicle], settings: AppSettings) async {
        let snapshot = NotificationSnapshot(vehicles: vehicles)
        await scheduler.refresh(snapshot: snapshot, preferences: NotificationPreferences(settings: settings))
    }

    static func refresh(using context: ModelContext) {
        let vehicles = (try? context.fetch(FetchDescriptor<Vehicle>())) ?? []
        let snapshot = NotificationSnapshot(vehicles: vehicles)
        let preferences = NotificationPreferences(settings: AppSettings.shared)
        Task {
            await scheduler.refresh(snapshot: snapshot, preferences: preferences)
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
}

private final class NotificationPresentationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }
}

private struct NotificationPreferences {
    var notifyServiceReminders: Bool
    var notifyExpiringDocuments: Bool
    var serviceLeadDays: Int
    var documentLeadDays: Int
    var mileageLeadKilometers: Int
    var mileageUnit: MileageUnit

    init(settings: AppSettings) {
        notifyServiceReminders = settings.notifyServiceReminders
        notifyExpiringDocuments = settings.notifyExpiringDocuments
        serviceLeadDays = settings.notificationLeadDays.rawValue
        documentLeadDays = settings.documentNotificationLeadDays.rawValue
        mileageLeadKilometers = settings.mileageUnit.storedKilometers(
            fromDisplay: settings.serviceNotificationLeadMileage.rawValue
        )
        mileageUnit = settings.mileageUnit
    }
}

private struct NotificationSnapshot {
    var reminders: [ServiceReminderSnapshot]
    var documents: [DocumentSnapshot]

    init(vehicles: [Vehicle]) {
        var reminders: [ServiceReminderSnapshot] = []
        var documents: [DocumentSnapshot] = []

        for vehicle in vehicles {
            let vehicleName = Self.displayName(for: vehicle)

            for reminder in vehicle.serviceReminders where !reminder.isCompleted {
                reminders.append(
                    ServiceReminderSnapshot(
                        key: Self.reminderKey(reminder, vehicleID: vehicle.id),
                        name: reminder.name,
                        vehicleName: vehicleName,
                        dueDate: reminder.dueDate,
                        dueMileage: reminder.dueMileage,
                        currentMileage: vehicle.currentMileage
                    )
                )
            }

            for document in vehicle.documents {
                guard let expiration = document.expirationDate else { continue }
                documents.append(
                    DocumentSnapshot(
                        key: "\(document.id.uuidString).\(Int(expiration.timeIntervalSince1970))",
                        title: document.title,
                        vehicleName: vehicleName,
                        expirationDate: expiration
                    )
                )
            }
        }

        self.reminders = reminders
        self.documents = documents
    }

    private static func displayName(for vehicle: Vehicle) -> String {
        if !vehicle.nickname.isEmpty {
            return vehicle.nickname
        }
        return "\(vehicle.year) \(vehicle.make) \(vehicle.model)"
    }

    private static func reminderKey(_ reminder: ServiceReminder, vehicleID: UUID) -> String {
        let dateStamp = reminder.dueDate.map { Int($0.timeIntervalSince1970) } ?? 0
        let mileage = reminder.dueMileage ?? 0
        let safeName = reminder.name.lowercased().replacingOccurrences(of: " ", with: "-")
        return "\(vehicleID.uuidString).\(safeName).\(dateStamp).\(mileage)"
    }
}

private struct ServiceReminderSnapshot {
    var key: String
    var name: String
    var vehicleName: String
    var dueDate: Date?
    var dueMileage: Int?
    var currentMileage: Int
}

private struct DocumentSnapshot {
    var key: String
    var title: String
    var vehicleName: String
    var expirationDate: Date
}

private struct ScheduledRecord: Codable {
    var id: String
    var fireDate: TimeInterval
}

private actor Scheduler {
    private static let deliveredKey = "notifications.deliveredIDs"
    private static let scheduledKey = "notifications.scheduledRecords"
    private static let morningHour = 9

    func refresh(snapshot: NotificationSnapshot, preferences: NotificationPreferences) async {
        let center = UNUserNotificationCenter.current()
        await center.removePendingNotificationRequests(
            withIdentifiers: await pendingAntiCELIdentifiers(center)
        )

        guard preferences.notifyServiceReminders || preferences.notifyExpiringDocuments else {
            saveScheduledRecords([])
            return
        }

        let status = await center.notificationSettings()
        guard status.authorizationStatus == .authorized
            || status.authorizationStatus == .provisional
            || status.authorizationStatus == .ephemeral
        else {
            return
        }

        let now = Date()
        var delivered = loadDeliveredIDs()
        let previouslyScheduled = Dictionary(
            loadScheduledRecords().map { ($0.id, Date(timeIntervalSince1970: $0.fireDate)) },
            uniquingKeysWith: { _, latest in latest }
        )
        var livingIDs: Set<String> = []
        var nextScheduled: [ScheduledRecord] = []
        var requests: [UNNotificationRequest] = []

        if preferences.notifyServiceReminders {
            for reminder in snapshot.reminders {
                if let dueDate = reminder.dueDate {
                    appendDateNotifications(
                        idPrefix: "anticel.service.date",
                        itemKey: reminder.key,
                        leadDays: preferences.serviceLeadDays,
                        dueDate: dueDate,
                        now: now,
                        leadContent: content(
                            title: "Service due soon",
                            body: "\(reminder.name) on \(reminder.vehicleName) is due \(formatted(dueDate))."
                        ),
                        dueContent: serviceDueContent(reminder, dueDate: dueDate, now: now),
                        previouslyScheduled: previouslyScheduled,
                        delivered: &delivered,
                        livingIDs: &livingIDs,
                        nextScheduled: &nextScheduled,
                        requests: &requests
                    )
                }

                if let dueMileage = reminder.dueMileage {
                    appendMileageNotifications(
                        reminder: reminder,
                        dueMileage: dueMileage,
                        leadKilometers: preferences.mileageLeadKilometers,
                        unit: preferences.mileageUnit,
                        delivered: &delivered,
                        livingIDs: &livingIDs,
                        requests: &requests
                    )
                }
            }
        }

        if preferences.notifyExpiringDocuments {
            for document in snapshot.documents {
                appendDateNotifications(
                    idPrefix: "anticel.document.date",
                    itemKey: document.key,
                    leadDays: preferences.documentLeadDays,
                    dueDate: document.expirationDate,
                    now: now,
                    leadContent: content(
                        title: "Document expiring soon",
                        body: "\(document.title) for \(document.vehicleName) expires \(formatted(document.expirationDate))."
                    ),
                    dueContent: documentDueContent(document, now: now),
                    previouslyScheduled: previouslyScheduled,
                    delivered: &delivered,
                    livingIDs: &livingIDs,
                    nextScheduled: &nextScheduled,
                    requests: &requests
                )
            }
        }

        saveDeliveredIDs(delivered.intersection(livingIDs))
        saveScheduledRecords(nextScheduled)

        for request in requests {
            try? await center.add(request)
        }
    }

    private func appendDateNotifications(
        idPrefix: String,
        itemKey: String,
        leadDays: Int,
        dueDate: Date,
        now: Date,
        leadContent: UNMutableNotificationContent,
        dueContent: UNMutableNotificationContent,
        previouslyScheduled: [String: Date],
        delivered: inout Set<String>,
        livingIDs: inout Set<String>,
        nextScheduled: inout [ScheduledRecord],
        requests: inout [UNNotificationRequest]
    ) {
        let leadID = "\(idPrefix).lead.\(itemKey)"
        let dueID = "\(idPrefix).due.\(itemKey)"
        livingIDs.insert(leadID)
        livingIDs.insert(dueID)

        let dueFire = morning(of: dueDate)
        let leadFire = morning(
            of: Calendar.current.date(byAdding: .day, value: -leadDays, to: startOfDay(dueDate)) ?? dueDate
        )

        enqueueDateNotification(
            id: dueID,
            fireDate: dueFire,
            now: now,
            content: dueContent,
            deliverIfPast: true,
            previouslyScheduled: previouslyScheduled,
            delivered: &delivered,
            nextScheduled: &nextScheduled,
            requests: &requests
        )

        enqueueDateNotification(
            id: leadID,
            fireDate: leadFire,
            now: now,
            content: leadContent,
            deliverIfPast: dueFire > now,
            previouslyScheduled: previouslyScheduled,
            delivered: &delivered,
            nextScheduled: &nextScheduled,
            requests: &requests
        )
    }

    private func enqueueDateNotification(
        id: String,
        fireDate: Date,
        now: Date,
        content: UNMutableNotificationContent,
        deliverIfPast: Bool,
        previouslyScheduled: [String: Date],
        delivered: inout Set<String>,
        nextScheduled: inout [ScheduledRecord],
        requests: inout [UNNotificationRequest]
    ) {
        if fireDate > now {
            nextScheduled.append(ScheduledRecord(id: id, fireDate: fireDate.timeIntervalSince1970))
            requests.append(calendarRequest(id: id, content: content, fireDate: fireDate))
            return
        }

        if delivered.contains(id) {
            return
        }

        if let previousFire = previouslyScheduled[id], previousFire <= now {
            delivered.insert(id)
            return
        }

        guard deliverIfPast else {
            return
        }

        delivered.insert(id)
        requests.append(immediateRequest(id: id, content: content))
    }

    private func appendMileageNotifications(
        reminder: ServiceReminderSnapshot,
        dueMileage: Int,
        leadKilometers: Int,
        unit: MileageUnit,
        delivered: inout Set<String>,
        livingIDs: inout Set<String>,
        requests: inout [UNNotificationRequest]
    ) {
        let leadID = "anticel.service.mileage.lead.\(reminder.key)"
        let dueID = "anticel.service.mileage.due.\(reminder.key)"
        livingIDs.insert(leadID)
        livingIDs.insert(dueID)

        let current = reminder.currentMileage
        let leadThreshold = max(dueMileage - leadKilometers, 0)

        if current >= dueMileage {
            enqueueImmediateIfNeeded(
                id: dueID,
                content: mileageDueContent(reminder, dueMileage: dueMileage, unit: unit),
                delivered: &delivered,
                requests: &requests
            )
        } else if current >= leadThreshold {
            let remaining = max(dueMileage - current, 0)
            enqueueImmediateIfNeeded(
                id: leadID,
                content: content(
                    title: "Service due soon",
                    body: "\(reminder.name) on \(reminder.vehicleName) is due in \(unit.formatted(remaining))."
                ),
                delivered: &delivered,
                requests: &requests
            )
        }
    }

    private func enqueueImmediateIfNeeded(
        id: String,
        content: UNMutableNotificationContent,
        delivered: inout Set<String>,
        requests: inout [UNNotificationRequest]
    ) {
        guard !delivered.contains(id) else {
            return
        }

        delivered.insert(id)
        requests.append(immediateRequest(id: id, content: content))
    }

    private func serviceDueContent(
        _ reminder: ServiceReminderSnapshot,
        dueDate: Date,
        now: Date
    ) -> UNMutableNotificationContent {
        if Calendar.current.isDateInToday(dueDate) {
            return content(
                title: "Service due today",
                body: "\(reminder.name) on \(reminder.vehicleName) is due today."
            )
        }

        if startOfDay(dueDate) < startOfDay(now) {
            return content(
                title: "Service overdue",
                body: "\(reminder.name) on \(reminder.vehicleName) was due \(formatted(dueDate))."
            )
        }

        return content(
            title: "Service due",
            body: "\(reminder.name) on \(reminder.vehicleName) is due \(formatted(dueDate))."
        )
    }

    private func documentDueContent(_ document: DocumentSnapshot, now: Date) -> UNMutableNotificationContent {
        if Calendar.current.isDateInToday(document.expirationDate) {
            return content(
                title: "Document expires today",
                body: "\(document.title) for \(document.vehicleName) expires today."
            )
        }

        if startOfDay(document.expirationDate) < startOfDay(now) {
            return content(
                title: "Document expired",
                body: "\(document.title) for \(document.vehicleName) expired \(formatted(document.expirationDate))."
            )
        }

        return content(
            title: "Document expires",
            body: "\(document.title) for \(document.vehicleName) expires \(formatted(document.expirationDate))."
        )
    }

    private func mileageDueContent(
        _ reminder: ServiceReminderSnapshot,
        dueMileage: Int,
        unit: MileageUnit
    ) -> UNMutableNotificationContent {
        if reminder.currentMileage > dueMileage {
            return content(
                title: "Service overdue",
                body: "\(reminder.name) on \(reminder.vehicleName) was due at \(unit.formatted(dueMileage))."
            )
        }

        return content(
            title: "Service due",
            body: "\(reminder.name) on \(reminder.vehicleName) is due at \(unit.formatted(dueMileage))."
        )
    }

    private func content(title: String, body: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        return content
    }

    private func calendarRequest(
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

    private func immediateRequest(
        id: String,
        content: UNMutableNotificationContent
    ) -> UNNotificationRequest {
        UNNotificationRequest(identifier: id, content: content, trigger: nil)
    }

    private func morning(of date: Date) -> Date {
        Calendar.current.date(
            bySettingHour: Self.morningHour,
            minute: 0,
            second: 0,
            of: date
        ) ?? date
    }

    private func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    private func formatted(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }

    private func pendingAntiCELIdentifiers(_ center: UNUserNotificationCenter) async -> [String] {
        let pending = await center.pendingNotificationRequests()
        return pending.map(\.identifier).filter {
            $0.hasPrefix("anticel.") && !$0.hasPrefix(OBDDriveNotifications.identifierPrefix)
        }
    }

    private func loadDeliveredIDs() -> Set<String> {
        let defaults = UserDefaults(suiteName: AppGroup.identifier) ?? .standard
        return Set(defaults.stringArray(forKey: Self.deliveredKey) ?? [])
    }

    private func saveDeliveredIDs(_ ids: Set<String>) {
        let defaults = UserDefaults(suiteName: AppGroup.identifier) ?? .standard
        defaults.set(Array(ids), forKey: Self.deliveredKey)
    }

    private func loadScheduledRecords() -> [ScheduledRecord] {
        let defaults = UserDefaults(suiteName: AppGroup.identifier) ?? .standard
        guard let data = defaults.data(forKey: Self.scheduledKey) else {
            return []
        }
        return (try? JSONDecoder().decode([ScheduledRecord].self, from: data)) ?? []
    }

    private func saveScheduledRecords(_ records: [ScheduledRecord]) {
        let defaults = UserDefaults(suiteName: AppGroup.identifier) ?? .standard
        let data = try? JSONEncoder().encode(records)
        defaults.set(data, forKey: Self.scheduledKey)
    }
}
