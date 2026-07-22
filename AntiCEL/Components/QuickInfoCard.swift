import SwiftUI

struct QuickInfoCard: View {

    let vehicle: Vehicle

    var body: some View {

        VStack(alignment: .leading, spacing: 16) {

            Text("Quick Info")
                .font(.title3)
                .fontWeight(.semibold)

            Divider()

            infoRow(title: "VIN", value: vehicle.vin.isEmpty ? "Not Set" : vehicle.vin)

            infoRow(
                title: "Mileage",
                value: "\(vehicle.currentMileage.formatted()) km"
            )

            infoRow(
                title: "Nickname",
                value: vehicle.nickname.isEmpty ? "None" : vehicle.nickname
            )

        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)

    }

    @ViewBuilder
    private func infoRow(title: String, value: String) -> some View {

        HStack {

            Text(title)
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
}
