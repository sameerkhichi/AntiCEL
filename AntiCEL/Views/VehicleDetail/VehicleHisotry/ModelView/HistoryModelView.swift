import SwiftUI

struct HistoryModelView: View {

    @Bindable var vehicle: Vehicle

    @State private var selectedArea: VehicleArea?
    @State private var cameraResetID = UUID()

    var body: some View {

        VStack(spacing: 12) {

            ZStack(alignment: .topTrailing) {

                VehicleModel3DView(
                    selectedArea: selectedArea,
                    cameraResetID: cameraResetID
                ) { area in

                    withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {

                        if selectedArea == area {
                            selectedArea = nil
                        } else {
                            selectedArea = area
                        }

                    }

                }
                .frame(height: 320)

                Button {
                    cameraResetID = UUID()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        selectedArea = nil
                    }
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(DashButtonStyle(kind: .compact))
                .padding(.trailing, 16)
                .padding(.top, 12)
                .accessibilityLabel("Reset model view")

            }
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
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)

                        }
                        .buttonStyle(DashButtonStyle(isSelected: selectedArea == area, kind: .compact))

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
        DashPanel {
            VStack(alignment: .leading, spacing: 12) {
                Text("Areas")
                    .font(.title3.weight(.semibold).width(.condensed))

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
        }
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
    .appTheme()
}
