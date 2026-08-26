import StoreKit
import SwiftUI

struct ConnectAccessView: View {

    enum Origin {
        case garage
        case connect
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @Environment(ConnectEntitlementStore.self) private var store

    let origin: Origin

    @State private var showingManage = false
    @State private var showingLegal: LegalDocument?

    var body: some View {
        InfotainmentScaffold(
            title: "Connect Access",
            confirmTitle: "Done",
            cancelTitle: "Close",
            onCancel: { dismiss() },
            onConfirm: { dismiss() }
        ) {
            statusPanel

            explanationPanel

            if shouldShowPlans {
                InfotainmentSectionHeader(title: "Plans")

                ForEach(ConnectProductID.allCases) { id in
                    planCard(id)
                }

                disclosure
            }

            if let lastMessage = store.lastMessage {
                Text(lastMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            InfotainmentSectionHeader(title: "Account")

            DashButton(kind: .bar) {
                Task { await store.restore() }
            } label: {
                Text(store.isRestoring ? "Restoring…" : "Restore Purchases")
            }
            .disabled(store.isRestoring)

            if store.hasRenewableSubscription {
                DashButton(kind: .bar) {
                    showingManage = true
                } label: {
                    Text("Cancel / Manage Subscription")
                }
            }

            InfotainmentSectionHeader(title: "Legal")

            DashButton(kind: .bar) {
                showingLegal = .privacyPolicy
            } label: {
                Text("Privacy Policy")
            }

            DashButton(kind: .bar) {
                showingLegal = .termsOfUse
            } label: {
                Text("Terms of Use")
            }

            footer

            #if DEBUG
            InfotainmentSectionHeader(title: "Debug")
            DashButton(kind: .bar) {
                store.resetTrialForDebugging()
            } label: {
                Text("Reset Trial")
            }
            #endif
        }
        .appTheme()
        .task {
            await store.refresh()
        }
        .manageSubscriptionsSheet(isPresented: $showingManage)
        .sheet(item: $showingLegal) { document in
            LegalDocumentSheet(document: document)
        }
    }

    private var shouldShowPlans: Bool {
        switch store.status {
        case .lifetime:
            return false
        case .notStarted, .trial, .expired, .subscribed:
            return true
        }
    }

    private var statusPanel: some View {
        DashPanel(padding: 14, cornerRadius: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Status")
                    .font(.subheadline.weight(.semibold))
                Text(statusTitle)
                    .font(.title3.weight(.semibold).width(.condensed))
                Text(statusDetail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var explanationPanel: some View {
        DashPanel(padding: 14, cornerRadius: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Try it with your car")
                    .font(.subheadline.weight(.semibold))
                Text("Connect is free for one month so you can see if it fits your lifestyle and whether your vehicle reports the data you care about. Not every car sends the same values. After that month, pick a plan to keep using live OBD. The rest of AntiCEL stays free.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func planCard(_ id: ConnectProductID) -> some View {
        let product = store.product(for: id)
        let alreadySubscribed: Bool = {
            if case .subscribed(let productID, _, _) = store.status {
                return productID == id.rawValue
            }
            return false
        }()

        return DashPanel(padding: 14, cornerRadius: 14) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(id.displayName)
                        .font(.headline.width(.condensed))
                    Spacer()
                    if id.isRecommended {
                        Text(id == .lifetime ? "Own it" : "Best value")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(theme.accentColor)
                    }
                }

                Text(id.subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(product?.displayPrice ?? id.fallbackPrice)
                        .font(.title3.weight(.semibold).monospacedDigit())
                    Text(id.periodLabel)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if alreadySubscribed {
                    Text("Your current plan")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.accentColor)
                } else if id != .lifetime, case .subscribed = store.status {
                    Text("Switch this plan in Cancel / Manage Subscription.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    DashButton(kind: .bar, isSelected: id.isRecommended) {
                        Task { await store.purchase(id) }
                    } label: {
                        Text(purchaseTitle(for: id))
                    }
                    .disabled(product == nil || store.isPurchasing || store.isLoadingProducts)
                }
            }
        }
    }

    private var disclosure: some View {
        Text("Subscriptions automatically renew unless you cancel at least 24 hours before the current period ends. Payment is charged to your Apple ID. Cancel from Cancel / Manage Subscription above, or in iOS Settings → Apple ID → Subscriptions. Restore Purchases brings back a plan you already bought on this Apple ID.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var footer: some View {
        Text(origin == .garage
             ? "You can also open this from a vehicle’s Connect tab."
             : "You can also find this from the garage, top left.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 4)
    }

    private var statusTitle: String {
        switch store.status {
        case .notStarted:
            return "Free month ready"
        case .trial:
            return "Free trial"
        case .subscribed:
            return "Subscribed"
        case .lifetime:
            return "Lifetime"
        case .expired:
            return "Trial ended"
        }
    }

    private var statusDetail: String {
        switch store.status {
        case .notStarted:
            return "The month starts when AntiCEL first connects to a supported adapter, not when you scan."
        case .trial(let daysRemaining, let endsAt):
            if daysRemaining <= 0 {
                return "Ends today, \(endsAt.formatted(date: .abbreviated, time: .shortened)). Choose a plan to keep Connect after that."
            }
            let dayText = daysRemaining == 1 ? "1 day left" : "\(daysRemaining) days left"
            return "\(dayText). Ends \(endsAt.formatted(date: .abbreviated, time: .shortened))."
        case .subscribed(_, let expiresAt, let willAutoRenew):
            if let expiresAt {
                if willAutoRenew {
                    return "Renews \(expiresAt.formatted(date: .abbreviated, time: .omitted)). Cancel at least 24 hours before then to avoid the next charge."
                }
                return "Access continues until \(expiresAt.formatted(date: .abbreviated, time: .omitted))."
            }
            return "Your Connect subscription is active."
        case .lifetime:
            return "Connect is unlocked on this Apple ID. Restore Purchases if you move to a new device."
        case .expired:
            return "Your free month is over. Choose a plan to keep using live OBD. Saved faults and mileage stay in the garage."
        }
    }

    private func purchaseTitle(for id: ConnectProductID) -> String {
        if store.isPurchasing {
            return "Purchasing…"
        }
        switch id {
        case .monthly: return "Continue Monthly"
        case .yearly: return "Continue Yearly"
        case .lifetime: return "Unlock Lifetime"
        }
    }
}

struct ConnectTrialExplainerSheet: View {

    @Environment(\.dismiss) private var dismiss

    let onContinue: () -> Void
    let onSeePlans: () -> Void

    var body: some View {
        InfotainmentScaffold(
            title: "Try Connect",
            confirmTitle: "Continue",
            cancelTitle: "Not Now",
            onCancel: { dismiss() },
            onConfirm: {
                dismiss()
                onContinue()
            }
        ) {
            DashPanel(padding: 14, cornerRadius: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("One free month")
                        .font(.subheadline.weight(.semibold))
                    Text("Try Connect free for a month and see if you like it. Not every car sends the same data. This month lets you test whether it works well with your vehicle and whether it fits your wants, needs, and lifestyle.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            DashPanel(padding: 14, cornerRadius: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("When the month starts")
                        .font(.subheadline.weight(.semibold))
                    Text("Scanning does not start the trial. The month begins the moment AntiCEL successfully connects to a supported adapter. If the dongle cannot talk to the car, you are not charged a trial.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            DashPanel(padding: 14, cornerRadius: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("After that")
                        .font(.subheadline.weight(.semibold))
                    Text("When the month ends you can choose monthly, yearly, or a one-time lifetime purchase. You can also see those plans now. The rest of AntiCEL stays free either way.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            DashButton(kind: .bar) {
                dismiss()
                onSeePlans()
            } label: {
                Text("See Plans")
            }

            Text("You can also find this from the garage, top left.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .appTheme()
    }
}
