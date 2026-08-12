import SwiftUI

struct HistoryModelView: View {

    @Bindable var vehicle: Vehicle

    @State private var selectedArea: VehicleArea?

    var body: some View {

        VStack(spacing: 12) {

            VehicleModel3DView(selectedArea: selectedArea) { area in

                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {

                    if selectedArea == area {
                        selectedArea = nil
                    } else {
                        selectedArea = area
                    }

                }

            }
            .frame(height: 320)
            .padding(.top, 4)

            ScrollView(.horizontal, showsIndicators: false) {

                HStack(spacing: 8) {

                    ForEach(VehicleArea.allCases) { area in

                        Button {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                                selectedArea = selectedArea == area ? nil : area
                            }
                        } label: {

                            Label(area.shortLabel, systemImage: area.iconName)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    selectedArea == area
                                        ? Color.accentColor.opacity(0.18)
                                        : Color(.secondarySystemBackground)
                                )
                                .foregroundStyle(
                                    selectedArea == area
                                        ? Color.accentColor
                                        : Color.primary
                                )
                                .clipShape(Capsule())

                        }
                        .buttonStyle(.plain)

                    }

                }
                .padding(.horizontal)

            }

            if let selectedArea {

                VehicleAreaHistoryPanel(
                    vehicle: vehicle,
                    area: selectedArea
                )
                .transition(
                    .move(edge: .bottom)
                    .combined(with: .opacity)
                )

            } else {

                areaSummaryCard
                    .transition(.opacity)

            }

        }
        .padding(.bottom)

    }

    private var areaSummaryCard: some View {

        VStack(alignment: .leading, spacing: 12) {

            Text("Areas")
                .font(.subheadline.weight(.semibold))

            ForEach(VehicleArea.allCases) { area in

                let count = vehicle.historyEntries.filter { $0.resolvedVehicleArea == area }.count
                let latest = vehicle.historyEntries
                    .filter { $0.resolvedVehicleArea == area }
                    .sorted { $0.date > $1.date }
                    .first

                Button {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                        selectedArea = area
                    }
                } label: {

                    HStack {

                        Image(systemName: area.iconName)
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {

                            Text(area.displayName)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)

                            if let latest {
                                Text(
                                    "Last: \(latest.title) · \(latest.date.formatted(date: .abbreviated, time: .omitted))"
                                )
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            } else {
                                Text("No records yet")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }

                        }

                        Spacer()

                        Text("\(count)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                    }
                    .padding(.vertical, 4)

                }
                .buttonStyle(.plain)

            }

        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal)
        .padding(.bottom)

    }

}

#Preview {
    NavigationStack {
        HistoryModelView(
            vehicle: Vehicle(
                make: "Audi",
                model: "S4",
                year: 2022,
                currentMileage: 79500
            )
        )
    }
}
