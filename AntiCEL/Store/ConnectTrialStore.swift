import Foundation
import Security

enum ConnectTrialStore {
    static let durationMonths = 1

    private static let service = "SRKSolutions.AntiCEL.connect"
    private static let account = "trialStartedAt"
    private static let iCloudKey = "connect.trialStartedAt"
    private static let iso = ISO8601DateFormatter()

    static var startedAt: Date? {
        earliest(
            keychainDate(synchronizable: false),
            keychainDate(synchronizable: true),
            iCloudDate()
        )
    }

    static var endsAt: Date? {
        guard let startedAt else { return nil }
        return Calendar.current.date(byAdding: .month, value: durationMonths, to: startedAt)
    }

    static var hasStarted: Bool { startedAt != nil }

    static var isActive: Bool {
        guard let endsAt else { return false }
        return Date() < endsAt
    }

    static var daysRemaining: Int {
        guard let endsAt else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: endsAt).day ?? 0
        return max(0, days)
    }

    static func startIfNeeded() {
        if hasStarted { return }
        persist(Date())
    }

    static func hydrate() {
        guard let startedAt else { return }
        persist(startedAt)
    }

    #if DEBUG
    static func reset() {
        deleteKeychain(synchronizable: false)
        deleteKeychain(synchronizable: true)
        NSUbiquitousKeyValueStore.default.removeObject(forKey: iCloudKey)
        NSUbiquitousKeyValueStore.default.synchronize()
    }
    #endif

    private static func persist(_ date: Date) {
        let value = iso.string(from: date)
        setKeychain(value, synchronizable: false)
        setKeychain(value, synchronizable: true)
        NSUbiquitousKeyValueStore.default.set(value, forKey: iCloudKey)
        NSUbiquitousKeyValueStore.default.synchronize()
    }

    private static func earliest(_ dates: Date?...) -> Date? {
        dates.compactMap { $0 }.min()
    }

    private static func iCloudDate() -> Date? {
        guard let value = NSUbiquitousKeyValueStore.default.string(forKey: iCloudKey) else {
            return nil
        }
        return iso.date(from: value)
    }

    private static func keychainDate(synchronizable: Bool) -> Date? {
        guard let value = keychainString(synchronizable: synchronizable) else { return nil }
        return iso.date(from: value)
    }

    private static func keychainString(synchronizable: Bool) -> String? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        query[kSecAttrSynchronizable as String] = synchronizable ? kCFBooleanTrue! : kCFBooleanFalse!

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func setKeychain(_ value: String, synchronizable: Bool) {
        deleteKeychain(synchronizable: synchronizable)
        guard let data = value.data(using: .utf8) else { return }
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        query[kSecAttrSynchronizable as String] = synchronizable ? kCFBooleanTrue! : kCFBooleanFalse!
        SecItemAdd(query as CFDictionary, nil)
    }

    private static func deleteKeychain(synchronizable: Bool) {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        query[kSecAttrSynchronizable as String] = synchronizable ? kCFBooleanTrue! : kCFBooleanFalse!
        SecItemDelete(query as CFDictionary)
    }
}
