import AppIntents

struct AntiCELShortcuts: AppShortcutsProvider {

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SetVehicleMileageIntent(),
            phrases: [
                "Set \(.applicationName) mileage",
                "Update \(.applicationName) odometer"
            ],
            shortTitle: "Set Mileage",
            systemImageName: "gauge"
        )
    }
}
