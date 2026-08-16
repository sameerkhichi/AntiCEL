import SwiftUI
import SwiftData
import UserNotifications

struct AppSettingsView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @Environment(AppSettings.self) private var settings
    @Query private var vehicles: [Vehicle]

    @State private var notificationDenied = false

    var body: some View {
        @Bindable var settings = settings

        InfotainmentScaffold(
            title: "Settings",
            confirmTitle: "Done",
            cancelTitle: "Close",
            onCancel: { dismiss() },
            onConfirm: { dismiss() }
        ) {
            InfotainmentSectionHeader(title: "Appearance")

            AccentSwatchPicker(
                title: "Light Mode Accent",
                previewScheme: .light,
                selection: $settings.lightAccent
            )

            AccentSwatchPicker(
                title: "Dark Mode Accent",
                previewScheme: .dark,
                selection: $settings.darkAccent
            )

            InfotainmentChipPicker(
                title: "Mileage Units",
                selection: $settings.mileageUnit,
                options: MileageUnit.allCases,
                itemTitle: { $0.displayName }
            )

            InfotainmentSectionHeader(title: "Notifications")

            Text("Get a heads-up before a service is due or a document expires.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            notificationToggle(
                title: "Service reminders",
                subtitle: "Upcoming date-based services",
                isOn: $settings.notifyServiceReminders
            )

            notificationToggle(
                title: "Expiring documents",
                subtitle: "Registration, insurance, and more",
                isOn: $settings.notifyExpiringDocuments
            )

            if settings.notifyServiceReminders || settings.notifyExpiringDocuments {
                InfotainmentChipPicker(
                    title: "Notify me",
                    selection: $settings.notificationLeadDays,
                    options: NotificationLeadDays.allCases,
                    itemTitle: { "\($0.displayName) before" }
                )
            }

            if notificationDenied {
                Text("Notifications are off in iOS Settings. Enable them there to receive reminders.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .appTheme()
        .onChange(of: settings.notifyServiceReminders) { _, isOn in
            Task { await handleNotificationToggle(enabled: isOn) }
        }
        .onChange(of: settings.notifyExpiringDocuments) { _, isOn in
            Task { await handleNotificationToggle(enabled: isOn) }
        }
        .onChange(of: settings.notificationLeadDays) {
            Task { await refreshNotifications() }
        }
        .onDisappear {
            Task { await refreshNotifications() }
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

    private func handleNotificationToggle(enabled: Bool) async {
        if enabled {
            let allowed = await ReminderNotifications.requestAuthorizationIfNeeded()
            notificationDenied = !allowed
        }
        await refreshNotifications()
    }

    private func refreshNotifications() async {
        await ReminderNotifications.refresh(vehicles: vehicles, settings: settings)
    }
}

#Preview {
    AppSettingsView()
        .environment(AppSettings.shared)
        .appTheme()
}
