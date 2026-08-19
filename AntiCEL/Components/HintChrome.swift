import SwiftUI

enum HintTopic: Hashable {
    case serviceReminders
    case vehicleNotes
    case quickInfo
    case history
    case documents

    var title: String {
        switch self {
        case .serviceReminders: return "Service Reminders"
        case .vehicleNotes: return "Vehicle Notes"
        case .quickInfo: return "Quick Info"
        case .history: return "History"
        case .documents: return "Documents"
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
                (
                    "How they're ordered",
                    "Reminders are listed soonest due first, with overdue items at the top."
                )
            ]
        case .vehicleNotes:
            return [
                (
                    "What to store here",
                    "Use notes for details or items related to the vehicle that you want to remember, but that aren't a service or a history event."
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
