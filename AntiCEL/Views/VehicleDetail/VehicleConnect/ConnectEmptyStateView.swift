import SwiftUI

struct ConnectEmptyStateView: View {

    let onScan: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            disclaimer(
                title: "Optional Feature",
                body: "Connect is an optional feature. AntiCEL is not sponsored, does not sell adapters, and you do not need to buy anything to use the rest of the app. There is absolutely zero pressure to buy anything to be able to use AntiCEL."
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
