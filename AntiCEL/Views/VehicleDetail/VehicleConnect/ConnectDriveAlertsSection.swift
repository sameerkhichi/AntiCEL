import SwiftUI
import SwiftData

struct ConnectDriveAlertsSheet: View {

    @Bindable var adapter: PairedAdapter
    @Environment(\.dismiss) private var dismiss

    @State private var showingHint = false

    var body: some View {
        InfotainmentScaffold(
            title: "Drive Alerts",
            confirmTitle: "Done",
            cancelTitle: "Close",
            onHelp: { showingHint = true },
            onCancel: { dismiss() },
            onConfirm: { dismiss() }
        ) {
            ConnectDriveAlertsSection(adapter: adapter)
        }
        .appTheme()
        .sheet(isPresented: $showingHint) {
            HintSheet(topic: .driveAlerts)
        }
    }
}

struct ConnectDriveAlertsSection: View {

    @Bindable var adapter: PairedAdapter
    @Environment(AppSettings.self) private var settings

    @State private var notificationDenied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
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
                temperatureSlider(
                    title: "Alert me at",
                    celsius: $adapter.coolantAlertThresholdCValue,
                    range: 80...150
                )
            }

            notificationToggle(
                title: "High oil temperature",
                subtitle: "If oil went above this on the last drive. Not every car reports oil temp.",
                isOn: $adapter.highOilTempEnabled
            )

            if adapter.highOilTempEnabled {
                temperatureSlider(
                    title: "Alert me at",
                    celsius: $adapter.oilAlertThresholdCValue,
                    range: 90...170
                )
            }

            if notificationDenied {
                Text("Notifications are off in iOS Settings. Enable them there to receive these reminders.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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

    private func temperatureSlider(
        title: String,
        celsius: Binding<Int>,
        range: ClosedRange<Int>
    ) -> some View {
        InfotainmentField(label: title) {
            VStack(alignment: .leading, spacing: 10) {
                Text(settings.temperatureUnit.formatted(Double(celsius.wrappedValue)))
                    .font(.body.weight(.semibold).monospacedDigit())

                Slider(
                    value: Binding(
                        get: { Double(celsius.wrappedValue) },
                        set: { celsius.wrappedValue = Int($0.rounded()) }
                    ),
                    in: Double(range.lowerBound)...Double(range.upperBound),
                    step: 1
                )
                .tint(Color.accentColor)

                HStack {
                    Text(settings.temperatureUnit.formatted(Double(range.lowerBound)))
                    Spacer()
                    Text(settings.temperatureUnit.formatted(Double(range.upperBound)))
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
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
