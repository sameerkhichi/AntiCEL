import Foundation
import StoreKit

@Observable
final class ConnectEntitlementStore {
    static let shared = ConnectEntitlementStore()

    var products: [Product] = []
    var status: ConnectAccessStatus = .notStarted
    var isLoadingProducts = false
    var isPurchasing = false
    var isRestoring = false
    var lastMessage: String?
    var hasRenewableSubscription = false
    #if DEBUG
    var lastProductLoadError: String?
    #endif

    var hasAccess: Bool {
        switch status {
        case .trial, .subscribed, .lifetime:
            return true
        case .notStarted, .expired:
            return false
        }
    }

    var canAttemptConnection: Bool {
        hasAccess || status == .notStarted
    }

    var hasLifetime: Bool {
        if case .lifetime = status { return true }
        return false
    }

    private var didStart = false
    private var updatesTask: Task<Void, Never>?
    private var cachedLifetime = false
    private var cachedSubscription: SubscriptionSnapshot?

    private init() {}

    func start() {
        guard !didStart else { return }
        didStart = true
        ConnectTrialStore.hydrate()
        applyLocalStatus(paidLifetime: false, subscription: nil)
        listenForTransactions()
        Task { await refresh() }
    }

    func product(for id: ConnectProductID) -> Product? {
        products.first { $0.id == id.rawValue }
    }

    func beginTrialIfNeeded() {
        guard !cachedLifetime, cachedSubscription == nil else { return }
        ConnectTrialStore.startIfNeeded()
        applyLocalStatus(paidLifetime: cachedLifetime, subscription: cachedSubscription)
        OBDSessionController.shared.enforceConnectAccess()
    }

    func expireIfNeeded() {
        guard !hasPaidAccess else { return }
        applyLocalStatus(paidLifetime: cachedLifetime, subscription: cachedSubscription)
        OBDSessionController.shared.enforceConnectAccess()
    }

    var canPurchase: Bool {
        if isPurchasing || isLoadingProducts { return false }
        if !products.isEmpty { return true }
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    func purchase(_ id: ConnectProductID) async {
        lastMessage = nil
        isPurchasing = true
        defer { isPurchasing = false }

        if let product = product(for: id) {
            do {
                let result = try await product.purchase()
                switch result {
                case .success(let verification):
                    let transaction = try Self.verified(verification)
                    await transaction.finish()
                    await refresh()
                case .userCancelled:
                    break
                case .pending:
                    lastMessage = "This purchase is pending approval."
                @unknown default:
                    lastMessage = "Purchase could not be completed."
                }
            } catch {
                lastMessage = error.localizedDescription
            }
            return
        }

        #if DEBUG
        ConnectDebugPurchase.grant(id)
        await refresh()
        lastMessage = "Debug purchase granted. Apple’s catalog is not attached to this run, so this did not go through StoreKit."
        #else
        lastMessage = "This plan is not available yet. Try again in a moment."
        #endif
    }

    func restore() async {
        lastMessage = nil
        isRestoring = true
        defer { isRestoring = false }

        #if DEBUG
        if products.isEmpty {
            await refresh()
            lastMessage = hasPaidAccess
                ? "Debug purchase is still on this install."
                : "No debug purchase on this install. Real Restore needs App Store products or a StoreKit config from Xcode."
            return
        }
        #endif

        do {
            try await AppStore.sync()
            await refresh()
            if hasPaidAccess {
                lastMessage = "Purchases restored."
            } else {
                lastMessage = "No Connect purchases were found for this Apple ID."
            }
        } catch {
            lastMessage = error.localizedDescription
        }
    }

    #if DEBUG
    var debugStoreSummary: String {
        if isLoadingProducts {
            return "Loading StoreKit products…"
        }
        if products.isEmpty {
            return "Apple returned 0 products. That is expected unless you press Run in Xcode with AntiCEL.storekit on the scheme (Cursor launches usually skip that). Use the plan buttons anyway — Debug grants access on this install without StoreKit."
        }
        return "\(products.count) StoreKit products loaded: \(products.map(\.id).joined(separator: ", ")). Purchases will use Apple’s sheet."
    }

    func debugStartTrial() {
        ConnectTrialStore.startForDebugging()
        Task { await refresh() }
    }

    func debugExpireTrial() {
        ConnectTrialStore.expireForDebugging()
        Task { await refresh() }
    }

    func resetTrialForDebugging() {
        ConnectTrialStore.reset()
        Task { await refresh() }
    }

    func clearDebugPurchase() {
        ConnectDebugPurchase.clear()
        Task { await refresh() }
    }
    #endif

    func refresh() async {
        await loadProducts()
        let paid = await loadPaidEntitlements()
        applyLocalStatus(paidLifetime: paid.lifetime, subscription: paid.subscription)
        OBDSessionController.shared.enforceConnectAccess()
    }

    private var hasPaidAccess: Bool {
        cachedLifetime || cachedSubscription != nil
    }

    private func loadProducts() async {
        isLoadingProducts = products.isEmpty
        defer { isLoadingProducts = false }
        #if DEBUG
        lastProductLoadError = nil
        #endif
        let ids = Set(ConnectProductID.allCases.map(\.rawValue))
        do {
            var loaded: [Product] = []
            for attempt in 1...4 {
                loaded = try await Product.products(for: ids)
                if !loaded.isEmpty { break }
                if attempt < 4 {
                    try await Task.sleep(for: .milliseconds(250))
                }
            }
            products = loaded.sorted { lhs, rhs in
                let order = ConnectProductID.allCases.map(\.rawValue)
                let li = order.firstIndex(of: lhs.id) ?? 0
                let ri = order.firstIndex(of: rhs.id) ?? 0
                return li < ri
            }
            #if DEBUG
            if products.isEmpty {
                lastProductLoadError = "StoreKit returned no products for \(ids.sorted().joined(separator: ", "))."
                print("Connect StoreKit: \(lastProductLoadError ?? "")")
            } else {
                print("Connect StoreKit loaded: \(products.map(\.id).joined(separator: ", "))")
            }
            #endif
        } catch {
            #if DEBUG
            lastProductLoadError = String(describing: error)
            print("Connect StoreKit load failed: \(error)")
            #endif
            lastMessage = "Could not load plans. Check your connection and try again."
        }
    }

    private func loadPaidEntitlements() async -> (lifetime: Bool, subscription: SubscriptionSnapshot?) {
        var lifetime = false
        var subscription: SubscriptionSnapshot?
        hasRenewableSubscription = false

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? Self.verified(result) else { continue }
            if transaction.revocationDate != nil { continue }

            if transaction.productID == ConnectProductID.lifetime.rawValue {
                lifetime = true
                continue
            }

            if transaction.productType == .autoRenewable {
                hasRenewableSubscription = true
                var willAutoRenew = true
                if let product = products.first(where: { $0.id == transaction.productID }),
                   let subscription = product.subscription {
                    if let statuses = try? await subscription.status {
                        for status in statuses {
                            if let renewal = try? Self.verified(status.renewalInfo) {
                                willAutoRenew = renewal.willAutoRenew
                                break
                            }
                        }
                    }
                }
                subscription = SubscriptionSnapshot(
                    productID: transaction.productID,
                    expiresAt: transaction.expirationDate,
                    willAutoRenew: willAutoRenew
                )
            }
        }

        #if DEBUG
        if !lifetime, subscription == nil, let debug = ConnectDebugPurchase.snapshot() {
            lifetime = debug.lifetime
            subscription = debug.subscription
            if subscription != nil {
                hasRenewableSubscription = true
            }
        }
        #endif

        cachedLifetime = lifetime
        cachedSubscription = subscription
        return (lifetime, subscription)
    }

    private func applyLocalStatus(paidLifetime: Bool, subscription: SubscriptionSnapshot?) {
        if paidLifetime {
            status = .lifetime
            return
        }
        if let subscription {
            status = .subscribed(
                productID: subscription.productID,
                expiresAt: subscription.expiresAt,
                willAutoRenew: subscription.willAutoRenew
            )
            return
        }
        if ConnectTrialStore.isActive, let endsAt = ConnectTrialStore.endsAt {
            status = .trial(daysRemaining: ConnectTrialStore.daysRemaining, endsAt: endsAt)
            return
        }
        if ConnectTrialStore.hasStarted {
            status = .expired
            return
        }
        status = .notStarted
    }

    private func listenForTransactions() {
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if let transaction = try? Self.verified(result) {
                    await transaction.finish()
                }
                await self.refresh()
            }
        }
    }

    private static func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }
}

private struct SubscriptionSnapshot {
    let productID: String
    let expiresAt: Date?
    let willAutoRenew: Bool
}

#if DEBUG
private enum ConnectDebugPurchase {
    private static let productKey = "connect.debug.productID"
    private static let expiresKey = "connect.debug.expiresAt"

    static func grant(_ id: ConnectProductID) {
        UserDefaults.standard.set(id.rawValue, forKey: productKey)
        switch id {
        case .lifetime:
            UserDefaults.standard.removeObject(forKey: expiresKey)
        case .monthly:
            UserDefaults.standard.set(Date().addingTimeInterval(2 * 60 * 60), forKey: expiresKey)
        case .yearly:
            UserDefaults.standard.set(Date().addingTimeInterval(24 * 60 * 60), forKey: expiresKey)
        }
    }

    static func snapshot() -> (lifetime: Bool, subscription: SubscriptionSnapshot?)? {
        guard let raw = UserDefaults.standard.string(forKey: productKey),
              let id = ConnectProductID(rawValue: raw) else {
            return nil
        }
        if id == .lifetime {
            return (true, nil)
        }
        let expires = UserDefaults.standard.object(forKey: expiresKey) as? Date
        if let expires, expires < Date() {
            clear()
            return nil
        }
        return (
            false,
            SubscriptionSnapshot(productID: id.rawValue, expiresAt: expires, willAutoRenew: false)
        )
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: productKey)
        UserDefaults.standard.removeObject(forKey: expiresKey)
    }
}
#endif
