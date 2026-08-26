import SwiftUI

enum LegalLinks {
    static let site = URL(string: "https://sameerkhichi.github.io/AntiCELDocs/")!
    static let privacy = URL(string: "https://sameerkhichi.github.io/AntiCELDocs/privacy.html")!
    static let terms = URL(string: "https://sameerkhichi.github.io/AntiCELDocs/terms.html")!
    static let credits = URL(string: "https://sameerkhichi.github.io/AntiCELDocs/credits.html")!
    static let companyName = "SRKSuite"
    static let supportEmail = "SRKSuite@gmail.com"
    static let supportMail = URL(string: "mailto:SRKSuite@gmail.com")!
    static let applePrivacy = URL(string: "https://www.apple.com/legal/privacy/")!
    static let appleMediaServices = URL(string: "https://www.apple.com/legal/internet-services/itunes/")!
}

enum LegalDocument: String, Identifiable, CaseIterable {
    case privacyPolicy
    case termsOfUse

    var id: String { rawValue }

    var title: String {
        switch self {
        case .privacyPolicy: return "Privacy Policy"
        case .termsOfUse: return "Terms of Use"
        }
    }

    var webURL: URL {
        switch self {
        case .privacyPolicy: return LegalLinks.privacy
        case .termsOfUse: return LegalLinks.terms
        }
    }

    var effectiveDate: String { "August 26, 2026" }

    var intro: String {
        switch self {
        case .privacyPolicy:
            return "AntiCEL is made by \(LegalLinks.companyName). This policy explains what the app does with information on your iPhone or iPad."
        case .termsOfUse:
            return "These terms are an agreement between you and \(LegalLinks.companyName) for the AntiCEL app. By downloading or using AntiCEL, you agree to them. If you do not agree, do not use the app. Apple’s standard Licensed Application End User License Agreement also applies to apps from the App Store, except where these terms add to it."
        }
    }

    var sections: [(title: String, body: String)] {
        switch self {
        case .privacyPolicy: return Self.privacySections
        case .termsOfUse: return Self.termsSections
        }
    }

    private static let privacySections: [(title: String, body: String)] = [
        (
            "The short version",
            "We do not collect, sell, or host your vehicle data. AntiCEL has no account and no server of ours. Vehicle records stay on your device unless you send them yourself. If you buy Connect, Apple processes the payment. We do not receive your card details."
        ),
        (
            "Information stored on your device",
            "Depending on how you use the app, AntiCEL may store vehicle details (make, model, year, VIN if you enter it, and mileage); service reminders, notes, and shops; history entries; documents you add; album and vehicle photos; paired OBD adapter identifiers and diagnostic records; mileage, fuel, temperature, and fault-code readings from an optional OBD adapter; Connect trial start time and whether Connect is unlocked; and app settings such as units, accents, notification preferences, and photo storage mode. This information is stored in the app, in Keychain, optionally in iCloud Key-Value storage, and in an App Group container so the mileage widget and Siri shortcuts can use the same garage data. It is not sent to \(LegalLinks.companyName)."
        ),
        (
            "What we do not collect",
            "We do not operate a backend for AntiCEL. We do not use analytics, advertising, crash-reporting SDKs, or other tools that send your information to us or to third parties. We do not track you across apps or websites."
        ),
        (
            "Photos and camera",
            "If you allow access, AntiCEL can use the camera and your photo library so you can photograph a vehicle, receipts, and documents, or choose existing photos. Photos may be stored as copies in the app, or left in your library when Low Storage Mode is on. AntiCEL can also save photos to your library when you use that option. We do not upload these photos."
        ),
        (
            "Documents",
            "Documents you store, including registration, insurance, and bills of sale, remain on your device. They leave the device only if you include them when sharing a vehicle."
        ),
        (
            "VIN",
            "VIN is stored on your device if you enter it. When you share a vehicle, VIN is left out unless you turn that option on."
        ),
        (
            "Sharing a vehicle",
            "Share Vehicle creates a copy of a vehicle as an .anticel file and lets you send it through the system share sheet, for example AirDrop, Messages, or Files. We never receive that file. You choose what the package includes: VIN, history, documents, album photos, reminders, notes, and shops. The original vehicle stays in your garage. Anyone who opens the file in AntiCEL gets that copy on their device. We cannot recall it. Only share with people you trust, and only include what you are comfortable sending. Photos that are not stored in the app cannot be packed into a share."
        ),
        (
            "Bluetooth and Connect",
            "Connect is optional. If you pair a Bluetooth Low Energy OBD adapter in the app, AntiCEL may read mileage, fuel level, temperatures, and diagnostic trouble codes from the vehicle and store them on your device. This data is not sent to us. Pair from the Connect screen, not from iOS Bluetooth Settings. We do not sell adapters."
        ),
        (
            "Purchases and Apple",
            "If you buy Connect access, payment is processed by Apple, not by \(LegalLinks.companyName). We never receive your Apple ID password or payment card details. The app reads purchase and subscription status from StoreKit on this device using your Apple ID so it can unlock Connect. Restore Purchases asks Apple to send that status again. Apple’s privacy policy applies to App Store payments: \(LegalLinks.applePrivacy.absoluteString)"
        ),
        (
            "Trial status",
            "The free Connect month starts when AntiCEL first successfully connects to a supported adapter. The start time is stored on this device (Keychain) and may sync with your iCloud account so a second device can see the same trial. We do not operate a server that tracks trials. A determined person could start another trial on a new device with iCloud off. The policy is one trial per Apple ID."
        ),
        (
            "Background Bluetooth",
            "Once an adapter is paired, AntiCEL may keep looking for it while you drive, including when the phone is locked or the app is in the background. Bluetooth may wake the app if the adapter comes back. This is so mileage and drive alerts can keep working. Forget the adapter in the app if you want that to stop. The rest of AntiCEL works without Connect."
        ),
        (
            "Notifications",
            "Reminders for upcoming service, expiring documents, and drive alerts are scheduled on your device. They are not push notifications from a server."
        ),
        (
            "Widgets and Siri",
            "The mileage widget and Siri shortcuts read and update garage data on your device through the App Group. They do not send that data to us."
        ),
        (
            "Device backups",
            "If you back up this device, including iCloud Backup, your AntiCEL data may be included in that backup. That backup belongs to you and your Apple account, not to us."
        ),
        (
            "Permissions",
            "The app may ask for camera access to photograph the vehicle, receipts, and documents; photo library access to choose or save those photos; Bluetooth to connect to an optional BLE OBD adapter; and notifications for service, document, and drive alerts. You can change these in iOS Settings. Features that need a permission will not work without it. The rest of the app will."
        ),
        (
            "Children",
            "AntiCEL is not directed at children. We do not knowingly collect personal information from anyone, including children."
        ),
        (
            "Third parties",
            "We do not share your AntiCEL vehicle data with third parties, because we do not receive it. If you share a vehicle file, you are sending it to the recipient you chose, not to us. Purchases go through Apple. Apple is a separate controller for App Store payment information."
        ),
        (
            "Deleting your data",
            "Delete a vehicle in the app to remove that vehicle’s records from this device. Delete the app to remove AntiCEL’s local garage data. Trial timestamps in Keychain or iCloud may remain. We have no cloud copy of your garage to delete. Deleting the app does not cancel an App Store subscription. If you already shared a package, the recipient’s copy is not under our control or yours."
        ),
        (
            "Changes",
            "If this policy changes, we will update it here and change the effective date. Continued use of AntiCEL after an update means you accept the revised policy."
        ),
        (
            "Contact",
            "Questions about privacy: \(LegalLinks.supportEmail)"
        ),
    ]

    private static let termsSections: [(title: String, body: String)] = [
        (
            "What AntiCEL is",
            "AntiCEL is a personal log for vehicle builds, maintenance, documents, photos, and optional OBD information. It is a record-keeping tool. AntiCEL is not a mechanic, dealership scanner, or substitute for professional diagnosis, repair, or inspection. It does not guarantee that a vehicle is safe, legal, or free of faults."
        ),
        (
            "Your content",
            "You are responsible for the information, photos, and documents you store or share. Do not store or send content you do not have the right to use, or that is illegal. You keep ownership of your content. We do not claim it, and in the normal use of this app we never receive it."
        ),
        (
            "Photos and documents",
            "Photos and documents on your device may include other people, identity documents, registration, insurance, or a bill of sale. You decide what to add and what to share. Handle that material with care."
        ),
        (
            "Sharing vehicles",
            "Sharing sends a copy. You choose the contents. VIN is off unless you turn it on. Once you send a package, we cannot retrieve it. Do not share VIN, documents, or photos with someone you would not hand those items to in person. The recipient gets an independent copy in their garage. Your original stays with you."
        ),
        (
            "Connect and OBD",
            "Connect is optional paid live OBD. Garage, history, documents, album, reminders, notes, and shops stay free. Supported adapters are Bluetooth Low Energy ELM327-style devices. The adapter we have tested is the Veepeak OBDCheck BLE+. Classic Bluetooth, Wi-Fi-only adapters, and dealer scanners are not supported. Not every vehicle reports the same data. Mileage from the adapter may be missing, estimated from speed and time, or wrong. Confirm important readings yourself. Leave an adapter in the port only when you intend to use it. Unplug it for long storage or extreme cold. A dongle left in the port can drain the vehicle battery. We do not sell or sponsor adapters."
        ),
        (
            "Connect trial",
            "You may use Connect free for one month. The month starts when AntiCEL first successfully connects to a supported adapter, not when you scan or open the app. Scanning or a failed handshake does not start the trial. The trial is intended as one per Apple ID. We store the start time on the device and may sync it with iCloud; we do not run an account server, so this is best-effort. If you buy a plan during the trial, paid access takes over for that purchase."
        ),
        (
            "Connect plans and billing",
            "After the trial, live OBD requires an in-app purchase: a monthly auto-renewable subscription, a yearly auto-renewable subscription, or a one-time lifetime purchase. Prices are shown in the app in your local currency before you buy and are charged to your Apple ID through the App Store. Subscriptions renew automatically unless you cancel at least 24 hours before the end of the current period. Apple, not \(LegalLinks.companyName), processes payment. We never see your card number. Apple’s Media Services terms also apply: \(LegalLinks.appleMediaServices.absoluteString)"
        ),
        (
            "How to cancel a subscription",
            "Open Connect Access from the garage (top left) and tap Cancel / Manage Subscription. That opens Apple’s subscription management. You can also go to iOS Settings → your name → Subscriptions, or Settings → Apple ID → Subscriptions, and cancel AntiCEL Connect there. We cannot cancel an App Store subscription ourselves. Canceling stops the next renewal. You keep Connect until the period you already paid for ends. Deleting the app does not cancel a subscription."
        ),
        (
            "Restore Purchases",
            "Connect access is tied to your Apple ID. If you get a new device, reinstall AntiCEL, or iOS does not restore automatically, open Connect Access and tap Restore Purchases. Family Sharing may also grant access if you enabled it for the purchase in App Store Connect."
        ),
        (
            "Lifetime purchase and refunds",
            "Lifetime Connect is a one-time digital purchase for this Apple ID. Refunds are decided by Apple under the Apple Media Services Terms, not by \(LegalLinks.companyName). We cannot promise that a purchase is non-refundable after a set number of days. If Apple refunds a purchase, AntiCEL revokes Connect access for that item."
        ),
        (
            "Diagnostic codes",
            "Reading a code is not a diagnosis. Clearing codes does not repair the vehicle. Codes can return. Clearing a code may affect inspections or emissions tests where you live. Only clear codes when you understand why they are there."
        ),
        (
            "Background Bluetooth",
            "If you pair an adapter, AntiCEL may use Bluetooth in the background to stay connected while you drive. Forget the adapter to stop that."
        ),
        (
            "Notifications",
            "Reminders are best-effort. Do not rely on AntiCEL as your only notice for service, registration, insurance, or a mechanical problem."
        ),
        (
            "Third-party materials",
            "The 3D vehicle in History is “Generic Sedan Car” by MMC Works, licensed under Creative Commons Attribution 4.0 International. Full credit, including links to the model and the license, is in Settings → Credits and on the AntiCEL credits page. The model was adapted for AntiCEL. MMC Works does not endorse this app."
        ),
        (
            "No warranty",
            "AntiCEL is provided “as is” and “as available,” without warranties of any kind, including merchantability, fitness for a particular purpose, and non-infringement, to the extent allowed by law. We do not warrant that OBD readings, reminders, or records will be accurate, complete, or uninterrupted."
        ),
        (
            "Limitation of liability",
            "To the extent allowed by law, \(LegalLinks.companyName) is not liable for any indirect, incidental, special, consequential, or punitive damages, or for lost data, lost profits, vehicle damage, missed maintenance, failed inspections, or personal injury, arising from your use of AntiCEL, an OBD adapter, or a shared vehicle file. Our total liability for any claim relating to the app will not exceed the amount you paid for AntiCEL, including in-app purchases, if any. Some places do not allow these limits. In those places, the limits apply only as far as the law allows."
        ),
        (
            "Changes",
            "We may update these terms. The effective date at the top will change. Continued use after an update means you accept the new terms."
        ),
        (
            "Contact",
            LegalLinks.supportEmail
        ),
    ]
}

struct LegalDocumentSheet: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme

    let document: LegalDocument

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(document.title)
                    .font(.headline.width(.condensed))
                    .tracking(0.8)

                Spacer()

                DashButton(kind: .compact, action: { dismiss() }) {
                    Text("Done")
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .background(theme.housing.opacity(0.92))
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(theme.edge)
                    .frame(height: 1)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Effective \(document.effectiveDate)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(document.intro)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    ForEach(Array(document.sections.enumerated()), id: \.offset) { _, section in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(section.title)
                                .font(.subheadline.weight(.semibold))

                            Text(section.body)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Link("View on the web", destination: document.webURL)
                        .font(.footnote.weight(.semibold))
                }
                .padding(20)
            }
        }
        .background(theme.infotainment.ignoresSafeArea())
        .presentationBackground(theme.infotainment)
        .presentationDetents([.large])
        .appTheme()
    }
}
