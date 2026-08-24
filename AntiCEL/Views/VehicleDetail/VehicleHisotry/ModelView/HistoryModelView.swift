import SwiftUI

struct HistoryModelView: View {

    @Bindable var vehicle: Vehicle
    var isActive = true

    @Environment(VehicleSceneCache.self) private var sceneCache

    @State private var selectedArea: VehicleArea?
    @State private var cameraResetID = UUID()

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ZStack(alignment: .topTrailing) {
                    Group {
                        if sceneCache.isReady {
                            VehicleModel3DView(
                                selectedArea: selectedArea,
                                cameraResetID: cameraResetID,
                                isActive: isActive
                            ) { area in
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                                    if selectedArea == area {
                                        selectedArea = nil
                                    } else {
                                        selectedArea = area
                                    }
                                }
                            }
                        } else {
                            HistoryModelPlaceholder()
                        }
                    }
                    .frame(height: 320)

                    if sceneCache.isReady {
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
                }
                .padding(.top, 4)

                HStack(spacing: 3) {
                    ForEach(VehicleArea.allCases) { area in
                        Button {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                                selectedArea = selectedArea == area ? nil : area
                            }
                        } label: {
                            VStack(spacing: 3) {
                                Image(systemName: area.iconName)
                                    .font(.system(size: 11, weight: .semibold))

                                Text(area.shortLabel)
                                    .font(.system(size: 8, weight: .semibold).width(.condensed))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.65)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 2)
                        }
                        .buttonStyle(DashButtonStyle(isSelected: selectedArea == area, kind: .key))
                    }
                }
                .padding(.horizontal, 10)

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

private struct HistoryModelPlaceholder: View {

    @Environment(\.appTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var startedAt = Date()

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(theme.panel.opacity(0.55))

            TimelineView(
                .animation(
                    minimumInterval: reduceMotion ? 1 : 1 / 30,
                    paused: reduceMotion
                )
            ) { context in
                ModelLoadingOdometer(
                    progress: reduceMotion
                        ? 0
                        : ModelLoadingOdometer.progress(
                            elapsed: context.date.timeIntervalSince(startedAt)
                        )
                )
            }
        }
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
    .environment(VehicleSceneCache.shared)
    .task { await VehicleSceneCache.shared.prepare() }
}
