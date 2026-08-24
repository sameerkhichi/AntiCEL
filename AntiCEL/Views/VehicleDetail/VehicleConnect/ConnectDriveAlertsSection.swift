import SwiftUI
import SwiftData

struct ConnectDriveAlertsSection: View {

    @Bindable var adapter: PairedAdapter
    @Environment(AppSettings.self) private var settings

    @State private var notificationDenied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Drive alerts")
                .font(.headline.width(.condensed))
                .padding(.horizontal)

            Text("These wait about 10 minutes after the adapter stops talking so a short stop does not fire one. If it reconnects, the reminder is cancelled.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)

            notificationToggle(
                title: "Fill-up reminder",
                subtitle: "When the last drive ended at or below this fuel level",
                isOn: $adapter.fillUpRemindersEnabled
            )

            if adapter.fillUpRemindersEnabled {
                InfotainmentChipPicker(
                    title: "Remind me at",
                    selection: $adapter.fillUpThresholdPercentValue,
                    options: [10, 15, 20, 25],
                    itemTitle: { "\($0)%" }
                )
                .padding(.horizontal)
            }

            notificationToggle(
                title: "Faults on last drive",
                subtitle: "New diagnostic codes that appeared during the trip",
                isOn: $adapter.driveFaultsEnabled
            )

            notificationToggle(
                title: "High coolant temperature",
                subtitle: "If coolant went above this on the last drive",
                isOn: $adapter.highCoolantTempEnabled
            )

            if adapter.highCoolantTempEnabled {
                InfotainmentChipPicker(
                    title: "Alert me at",
                    selection: $adapter.coolantAlertThresholdCValue,
                    options: [100, 105, 110, 115, 120],
                    itemTitle: { settings.temperatureUnit.formatted(Double($0)) }
                )
                .padding(.horizontal)
            }

            notificationToggle(
                title: "High oil temperature",
                subtitle: "If oil went above this on the last drive. Not every car reports oil temp.",
                isOn: $adapter.highOilTempEnabled
            )

            if adapter.highOilTempEnabled {
                InfotainmentChipPicker(
                    title: "Alert me at",
                    selection: $adapter.oilAlertThresholdCValue,
                    options: [120, 125, 130, 135, 140],
                    itemTitle: { settings.temperatureUnit.formatted(Double($0)) }
                )
                .padding(.horizontal)
            }

            if notificationDenied {
                Text("Notifications are off in iOS Settings. Enable them there to receive these reminders.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
        }
        .onAppear {
            Task { await requestIfAlertsEnabled() }
        }
        .onChange(of: adapter.fillUpRemindersEnabled) { _, isOn in
            Task { await handleToggle(enabled: isOn) }
        }
        .onChange(of: adapter.driveFaultsEnabled) { _, isOn in
            Task { await handleToggle(enabled: isOn) }
        }
        .onChange(of: adapter.highCoolantTempEnabled) { _, isOn in
            Task { await handleToggle(enabled: isOn) }
        }
        .onChange(of: adapter.highOilTempEnabled) { _, isOn in
            Task { await handleToggle(enabled: isOn) }
        }
    }

    private func notificationToggle(
        title: String,
        subtitle: String,
        isOn: Binding<Bool>
    ) -> some View {
        InfotainmentField {
            Toggle(isOn: isOn) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body.weight(.medium))
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .tint(Color.accentColor)
        }
        .padding(.horizontal)
    }

    private func handleToggle(enabled: Bool) async {
        if enabled {
            let allowed = await ReminderNotifications.requestAuthorizationIfNeeded()
            notificationDenied = !allowed
        }
    }

    private func requestIfAlertsEnabled() async {
        let anyOn = adapter.fillUpRemindersEnabled
            || adapter.driveFaultsEnabled
            || adapter.highCoolantTempEnabled
            || adapter.highOilTempEnabled
        guard anyOn else { return }
        let allowed = await ReminderNotifications.requestAuthorizationIfNeeded()
        notificationDenied = !allowed
    }
}
