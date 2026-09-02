import SwiftUI

struct ConnectEmptyStateView: View {

    let onScan: () -> Void
    let onSeePlans: () -> Void
    var onUseMock: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            DashPanel(padding: 14, cornerRadius: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Try it free for a month")
                        .font(.subheadline.weight(.semibold))
                    Text("See if you like it! Connect is free for one month so you can try live OBD with your car. After that, you can pick a monthly, yearly, or one-time plan.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    DashButton(kind: .bar, action: onSeePlans) {
                        Text("See Plans & Details")
                    }
                }
            }

            disclaimer(
                title: "Optional Feature",
                body: "Connect is optional. The rest of AntiCEL like the garage, history, documents, album, and remindersstays free. AntiCEL is not sponsored and does not sell adapters. You only pay if you want live OBD after the free month."
            )

            disclaimer(
                title: "Recommended Adapter",
                body: "The supported and tested device is the Veepeak OBDCheck BLE+. Pair it from this screen, do NOT pair it in iOS Bluetooth Settings as it will not reconnect later and the app may not recognize it."
            )

            disclaimer(
                title: "Compatibility",
                body: "Not every OBD dongle works. Most BLE ELM327 adapters (devices that say BLE, Bluetooth Low Energy, or iOS compatible) should be able to connect. Classic Bluetooth dongles, Wi-Fi-only adapters, and dealer scanners are not supported."
            )

            disclaimer(
                title: "Mileage",
                body: "Automatic mileage updates are not exact on every model. They only work if the vehicle reports odometer data over OBD. Otherwise AntiCEL estimates distance from speed and time. If the mileage calculated is greater than 80km (50mi), AntiCEL will prompt you on the vehicle screen if the update is accruate, and it will let you either keep your current mileage or use the calculated value. You can always enter mileage yourself."
            )

            disclaimer(
                title: "Battery",
                body: "Low-energy BLE adapters should not drain a healthy battery in normal use, but leaving any adapter plugged in for days is still a risk. AntiCEL is not responsible for a dead battery. Unplug the adapter for long storage or during extreme cold weather conditions."
            )

            DashButton(kind: .bar, action: onScan) {
                Text("Scan for Adapter")
            }
            .padding(.top, 4)

            #if DEBUG
            if let onUseMock {
                DashButton(kind: .bar, action: onUseMock) {
                    Text("Use Mock Adapter")
                }
                Text("Debug only. Simulates a Veepeak BLE+ so you can try Connect without hardware. Hidden in Release builds.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            #endif
        }
        .padding(.horizontal)
    }

    private func disclaimer(title: String, body: String) -> some View {
        DashPanel(padding: 14, cornerRadius: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(body)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
