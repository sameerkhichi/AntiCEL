import SwiftUI

struct QuickInfoCard: View {

    @Environment(AppSettings.self) private var settings

    let vehicle: Vehicle

    var body: some View {
        DashPanel {
            VStack(alignment: .leading, spacing: 16) {
                Text("Quick Info")
                    .font(.title3.weight(.semibold).width(.condensed))

                Rectangle()
                    .fill(.quaternary)
                    .frame(height: 1)

                infoRow(title: "VIN", value: vehicle.vin.isEmpty ? "Not Set" : vehicle.vin)

                infoRow(
                    title: "Mileage",
                    value: settings.formattedMileage(vehicle.currentMileage)
                )

                infoRow(
                    title: "Nickname",
                    value: vehicle.nickname.isEmpty ? "None" : vehicle.nickname
                )
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.appBadge)
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview {
    QuickInfoCard(
        vehicle: Vehicle(
            make: "Audi",
            model: "S4",
            year: 2022,
            nickname: "Daily Driver",
            vin: "WAUENAF49NA123456",
            currentMileage: 79500
        )
    )
    .appTheme()
}
