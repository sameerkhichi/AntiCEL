import SwiftUI

enum HintTopic: Hashable {
    case serviceReminders
    case vehicleNotes
    case vehicleShops
    case quickInfo
    case history
    case documents
    case album
    case connect

    var title: String {
        switch self {
        case .serviceReminders: return "Service Reminders"
        case .vehicleNotes: return "Vehicle Notes"
        case .vehicleShops: return "Vehicle Shops"
        case .quickInfo: return "Quick Info"
        case .history: return "History"
        case .documents: return "Documents"
        case .album: return "Album"
        case .connect: return "Connect"
        }
    }

    var blocks: [(title: String, body: String)] {
        switch self {
        case .serviceReminders:
            return [
                (
                    "What they're for",
                    "Track upcoming work by date, mileage, or whichever comes first so you know what the vehicle needs next."
                ),
                (
                    "Completing a reminder",
                    "When you mark a service complete, AntiCEL automatically adds a matching history entry for that vehicle area."
                ),
            ]
        case .vehicleNotes:
            return [
                (
                    "What to store here",
                    "Use notes for details or items related to the vehicle that you want to remember, but that aren't a service or a history event."
                )
            ]
        case .vehicleShops:
            return [
                (
                    "What to store here",
                    "Keep a list of shops you use for this vehicle, such as a preferred mechanic, tint shop, or tire place. This is not a service reminder or a history event."
                )
            ]
        case .quickInfo:
            return [
                (
                    "Updating mileage",
                    "Tap the mileage count in the vehicle header, or the gauge button on the top-right of the garage bay, to edit mileage."
                ),
                (
                    "Mileage widget",
                    "You can also add the AntiCEL mileage widget to your Home Screen for quicker updates."
                )
            ]
        case .history:
            return [
                (
                    "Finding work by area",
                    "Tap hotspots on the 3D car, or the area buttons below it, to see work for that part of the vehicle."
                ),
                (
                    "Service reminders",
                    "Completed service reminders are added here automatically. You can also add any work done to the vehicle yourself with the plus button."
                ),
                (
                    "List view",
                    "Use the toolbar toggle to switch to a list of every history entry if you prefer that over the car view."
                )
            ]
        case .documents:
            return [
                (
                    "What to store here",
                    "Add documents related to the vehicle, such as registration, insurance, or a bill of sale."
                ),
                (
                    "Expiry dates",
                    "You can add an expiry date so AntiCEL can remind you when it's time to renew them."
                )
            ]
        case .album:
            return [
                (
                    "Photo Album",
                    "Add your favourite shots of your car! These photos can be shared when you share the entire vehicle."
                ),
                (
                    "Low Storage Mode",
                    "When Low Storage Mode is on, album photos are linked to your camera roll instead of copies in AntiCEL. Photos that are not copies on AntiCEL cannot be included if you share the vehicle."
                )
            ]
        case .connect:
            return [
                (
                    "Optional connection",
                    "Connect is optional. AntiCEL is not sponsored and does not require you to buy an adapter to use the rest of the app.."
                ),
                (
                    "Recommended adapter",
                    "The supported and tested device is the Veepeak OBDCheck BLE+. Pair it from Connect, not from iOS Bluetooth Settings."
                ),
                (
                    "Compatibility",
                    "Not every OBD dongle works. Most BLE ELM327 adapters should. Classic Bluetooth, Wi-Fi-only, and dealer scanners are not supported."
                ),
                (
                    "Mileage",
                    "Automatic mileage is not exact on every model. It depends on whether the vehicle reports odometer data over OBD. Otherwise distance is estimated from speed and time. A large mileage calculation will prompt you before saving."
                ),
                (
                    "Battery",
                    "BLE adapters should not drain a healthy battery in normal use, but leaving one plugged in for days is still a risk. AntiCEL is not responsible for a dead battery. Please take caution when using an adapter."
                )
            ]
        }
    }
}

struct HintButton: View {

    @Environment(AppSettings.self) private var settings
    @Environment(\.appTheme) private var theme

    let title: String
    var compact: Bool = false
    let action: () -> Void

    var body: some View {
        if settings.showHints {
            Button(action: action) {
                Image(systemName: "questionmark.circle")
                    .font(compact ? .caption.weight(.semibold) : .body.weight(.semibold))
                    .foregroundStyle(theme.accentColor)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("About \(title)")
        }
    }
}

struct HintSheet: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme

    let topic: HintTopic

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(topic.title)
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
                    ForEach(Array(topic.blocks.enumerated()), id: \.offset) { _, block in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(block.title)
                                .font(.subheadline.weight(.semibold))

                            Text(block.body)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(20)
            }
        }
        .background(theme.infotainment.ignoresSafeArea())
        .presentationBackground(theme.infotainment)
        .presentationDetents([.medium, .large])
        .appTheme()
    }
}
