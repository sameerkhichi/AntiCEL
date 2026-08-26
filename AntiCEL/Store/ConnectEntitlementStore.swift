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
    private var iCloudObserver: NSObjectProtocol?
    private var cachedLifetime = false
    private var cachedSubscription: SubscriptionSnapshot?

    private init() {}

    func start() {
        guard !didStart else { return }
        didStart = true
        ConnectTrialStore.hydrate()
        applyLocalStatus(paidLifetime: false, subscription: nil)
        listenForTransactions()
        observeICloudTrial()
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

    func purchase(_ id: ConnectProductID) async {
        lastMessage = nil
        guard let product = product(for: id) else {
            lastMessage = "This plan is not available yet. Try again in a moment."
            return
        }

        isPurchasing = true
        defer { isPurchasing = false }

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
    }

    func restore() async {
        lastMessage = nil
        isRestoring = true
        defer { isRestoring = false }

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
    func resetTrialForDebugging() {
        ConnectTrialStore.reset()
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
        do {
            let ids = ConnectProductID.allCases.map(\.rawValue)
            products = try await Product.products(for: ids).sorted { lhs, rhs in
                let order = ConnectProductID.allCases.map(\.rawValue)
                let li = order.firstIndex(of: lhs.id) ?? 0
                let ri = order.firstIndex(of: rhs.id) ?? 0
                return li < ri
            }
        } catch {
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

    private func observeICloudTrial() {
        iCloudObserver = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { _ in
            Task { @MainActor in
                ConnectTrialStore.hydrate()
                await ConnectEntitlementStore.shared.refresh()
            }
        }
        NSUbiquitousKeyValueStore.default.synchronize()
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
