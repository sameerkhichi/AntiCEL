import SwiftUI
import SwiftData
import UserNotifications

struct AppSettingsView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @Environment(AppSettings.self) private var settings
    @Query private var vehicles: [Vehicle]

    @State private var notificationDenied = false
    @State private var showingClearPhotos = false
    @State private var showingPhotoHelp = false
    @State private var showingNotificationsHelp = false
    @State private var didClearPhotos = false

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

            InfotainmentChipPicker(
                title: "Temperature Units",
                selection: $settings.temperatureUnit,
                options: TemperatureUnit.allCases,
                itemTitle: { $0.displayName }
            )

            InfotainmentSectionHeader(title: "Tips")

            InfotainmentField {
                Toggle(isOn: $settings.showHints) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Show Tips")
                            .font(.body.weight(.medium))
                        Text("Question-mark buttons that explain each section")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(Color.accentColor)
            }

            InfotainmentSectionHeader(title: "Notifications", onHelp: { showingNotificationsHelp = true })

            notificationToggle(
                title: "Service reminders",
                subtitle: "Upcoming services by date or mileage",
                isOn: $settings.notifyServiceReminders
            )

            if settings.notifyServiceReminders {
                InfotainmentChipPicker(
                    title: "Remind me by date",
                    selection: $settings.notificationLeadDays,
                    options: NotificationLeadDays.allCases,
                    itemTitle: { "\($0.displayName) before" }
                )

                InfotainmentChipPicker(
                    title: "Remind me by mileage",
                    selection: $settings.serviceNotificationLeadMileage,
                    options: NotificationLeadMileage.allCases,
                    itemTitle: { "\($0.displayName(using: settings.mileageUnit)) before" }
                )
            }

            notificationToggle(
                title: "Expiring documents",
                subtitle: "Registration, insurance, and more",
                isOn: $settings.notifyExpiringDocuments
            )

            if settings.notifyExpiringDocuments {
                InfotainmentChipPicker(
                    title: "Remind me",
                    selection: $settings.documentNotificationLeadDays,
                    options: NotificationLeadDays.allCases,
                    itemTitle: { "\($0.displayName) before" }
                )
            }

            if notificationDenied {
                Text("Notifications are off in iOS Settings. Enable them there to receive reminders.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            InfotainmentSectionHeader(title: "Photos", onHelp: { showingPhotoHelp = true })

            InfotainmentField {
                Toggle(isOn: $settings.lowStorageMode) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Low Storage Mode")
                            .font(.body.weight(.medium))
                        Text("Uses your camera roll instead of storing copies in AntiCEL")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(Color.accentColor)
            }

            DashButton(kind: .bar, isDestructive: true) {
                showingClearPhotos = true
            } label: {
                Text("Remove Saved Photos")
            }

            if didClearPhotos {
                Text("Saved photos were removed from AntiCEL.")
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
        .onChange(of: settings.serviceNotificationLeadMileage) {
            Task { await refreshNotifications() }
        }
        .onChange(of: settings.documentNotificationLeadDays) {
            Task { await refreshNotifications() }
        }
        .onChange(of: settings.mileageUnit) {
            Task { await refreshNotifications() }
        }
        .onChange(of: settings.lowStorageMode) { _, isOn in
            if isOn {
                Task { await PhotoStore.requestPhotoLibraryAccessIfNeeded() }
            }
        }
        .sheet(isPresented: $showingPhotoHelp) {
            PhotoStorageHelpSheet()
        }
        .sheet(isPresented: $showingNotificationsHelp) {
            HintSheet(topic: .notifications)
        }
        .alert("Remove Saved Photos?", isPresented: $showingClearPhotos) {
            Button("Remove Photos", role: .destructive) {
                PhotoStore.clearAppCopies(in: vehicles)
                didClearPhotos = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This deletes all photos stored on AntiCEL. Photos stored on this app, and not in your camera roll, will be permanently deleted.")
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
