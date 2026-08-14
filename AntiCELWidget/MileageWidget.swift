import AppIntents
import SwiftUI
import WidgetKit

struct MileageWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: AntiCELWidgetKind.mileage,
            intent: MileageWidgetConfiguration.self,
            provider: MileageTimelineProvider()
        ) { entry in
            MileageWidgetView(entry: entry)
                .appTheme()
        }
        .configurationDisplayName("Odometer")
        .description("Check a vehicle’s mileage. Tap to type a new reading, or use the dash keys to add kilometers.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

struct MileageEntry: TimelineEntry {
    let date: Date
    let snapshot: MileageSnapshot?
}

struct MileageTimelineProvider: AppIntentTimelineProvider {

    func placeholder(in context: Context) -> MileageEntry {
        MileageEntry(
            date: Date(),
            snapshot: MileageSnapshot(
                vehicleID: UUID(),
                name: "Daily Driver",
                mileage: 79500
            )
        )
    }

    func snapshot(
        for configuration: MileageWidgetConfiguration,
        in context: Context
    ) async -> MileageEntry {
        entry(for: configuration)
    }

    func timeline(
        for configuration: MileageWidgetConfiguration,
        in context: Context
    ) async -> Timeline<MileageEntry> {
        Timeline(
            entries: [entry(for: configuration)],
            policy: .after(Date().addingTimeInterval(15 * 60))
        )
    }

    private func entry(for configuration: MileageWidgetConfiguration) -> MileageEntry {
        let snapshot = try? MileageWriter.snapshot(for: configuration.vehicle?.id)
        return MileageEntry(date: Date(), snapshot: snapshot)
    }
}

struct MileageWidgetView: View {

    @Environment(\.widgetFamily) private var family
    @Environment(\.appTheme) private var theme

    var entry: MileageEntry

    var body: some View {
        Group {
            if let snapshot = entry.snapshot {
                populatedView(snapshot: snapshot)
            } else {
                emptyView
            }
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [theme.canvasTop, theme.canvas],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .widgetURL(entry.snapshot.map { AntiCELDeepLink.mileage(vehicleID: $0.vehicleID) })
    }

    @ViewBuilder
    private func populatedView(snapshot: MileageSnapshot) -> some View {
        let vehicle = VehicleEntity(id: snapshot.vehicleID, name: snapshot.name)

        switch family {
        case .systemMedium:
            VStack(alignment: .leading, spacing: 10) {
                vehicleHeader(snapshot.name)
                OdometerView(mileage: snapshot.mileage, compact: true)
                    .frame(maxWidth: .infinity)
                incrementRow(vehicle: vehicle)
            }
            .padding(.vertical, 2)

        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text(snapshot.name)
                    .font(.headline)
                    .lineLimit(1)
                Text("\(snapshot.mileage.formatted()) km")
                    .font(.system(.title3, design: .monospaced).weight(.medium))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

        default:
            VStack(spacing: 8) {
                vehicleHeader(snapshot.name)
                OdometerView(mileage: snapshot.mileage, compact: true)
                incrementRow(vehicle: vehicle)
            }
        }
    }

    private func incrementRow(vehicle: VehicleEntity) -> some View {
        HStack(spacing: 8) {
            incrementButton(vehicle: vehicle, kilometers: 10)
            incrementButton(vehicle: vehicle, kilometers: 50)
            incrementButton(vehicle: vehicle, kilometers: 100)
        }
    }

    private func incrementButton(vehicle: VehicleEntity, kilometers: Int) -> some View {
        Button(intent: AddMileageIntent(vehicle: vehicle, kilometers: kilometers)) {
            Text("+\(kilometers)")
        }
        .buttonStyle(DashButtonStyle(isSelected: true, kind: .key))
        .invalidatableContent()
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "car.side")
                .font(.title2)
                .foregroundStyle(Color.accentColor)
            Text("Park a vehicle")
                .font(.appBadge)
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func vehicleHeader(_ name: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "car.side.fill")
                .foregroundStyle(Color.accentColor)
            Text(name)
                .font(.appBadge)
                .tracking(1.1)
                .textCase(.uppercase)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
    }
}

#Preview("Small", as: .systemSmall) {
    MileageWidget()
} timeline: {
    MileageEntry(
        date: .now,
        snapshot: MileageSnapshot(vehicleID: UUID(), name: "Batmobile", mileage: 79500)
    )
}

#Preview("Medium", as: .systemMedium) {
    MileageWidget()
} timeline: {
    MileageEntry(
        date: .now,
        snapshot: MileageSnapshot(vehicleID: UUID(), name: "Batmobile", mileage: 79500)
    )
}
